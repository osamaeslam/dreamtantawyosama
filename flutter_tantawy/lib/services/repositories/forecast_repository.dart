import '../../models/models.dart';
import 'package:intl/intl.dart';
import 'base_repository.dart';

/// All Supabase read/write operations for sales targets and forecasts.
class ForecastRepository extends BaseRepository {
  const ForecastRepository();

  // ===================== الأهداف والتارجت (Targets) =====================
  Future<List<TargetRecord>> fetchTargets({
    String? repName,
    String? branchName,
    int? month,
    int? year,
  }) async {
    try {
      var query = client.from('targets').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (month != null) {
        query = query.eq('month', month);
      }
      if (year != null) {
        query = query.eq('year', year);
      }
      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>)
          .map((e) => TargetRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchTargets', e);
      return [];
    }
  }

  // ===================== التوقعات/التوقعات الأسبوعية (Forecasts) =====================
  Future<List<CollectionForecastRecord>> fetchForecasts({
    String? repName,
    String? monthKey,
    ForecastStatusType? status,
  }) async {
    try {
      var query = client.from('forecasts').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      if (monthKey != null && monthKey.isNotEmpty) {
        query = query.eq('month_key', monthKey);
      }
      if (status != null) {
        query = query.eq('status', ForecastRepository.forecastStatusToString(status));
      }
      final data = await query.order('month_key', ascending: false);
      return (data as List<dynamic>)
          .map((e) =>
              CollectionForecastRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchForecasts', e);
      return [];
    }
  }

  Future<ForecastMonthPlan?> fetchForecastMonthPlan(String monthKey) async {
    try {
      final data = await client
          .from('forecast_month_plans')
          .select()
          .eq('id', monthKey)
          .maybeSingle();
      if (data == null) return null;
      return ForecastMonthPlan.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      logError('fetchForecastMonthPlan', e);
      return null;
    }
  }

  Future<bool> saveForecast(CollectionForecastRecord record) async {
    try {
      await client.from('forecasts').upsert(record.toJson());
      return true;
    } catch (e) {
      logError('saveForecast', e);
      return false;
    }
  }

  // ===================== إدارة أسابيع الشهر (Month Plan Week Config) =====================
  /// Save or update the week boundaries for a given month plan.
  /// The admin can define custom week start/end dates (e.g., Tue–Thu).
  Future<bool> saveForecastMonthPlan(ForecastMonthPlan monthPlan) async {
    try {
      await client.from('forecast_month_plans').upsert(monthPlan.toJson());
      return true;
    } catch (e) {
      logError('saveForecastMonthPlan', e);
      return false;
    }
  }

  /// Update the week definitions for an existing month plan.
  /// Each week in `weeks` should have a valid start/end date.
  Future<bool> updateMonthPlanWeeks(
      String monthKey, List<ForecastWeek> weeks) async {
    try {
      await client
          .from('forecast_month_plans')
          .update({'weeks': weeks.map((w) => w.toJson()).toList()})
          .eq('id', monthKey);
      return true;
    } catch (e) {
      logError('updateMonthPlanWeeks', e);
      return false;
    }
  }

  /// Close a month plan so no further forecasts can be submitted.
  Future<bool> closeMonthPlan(String monthKey, String closedBy) async {
    try {
      await client
          .from('forecast_month_plans')
          .update({
            'is_closed': true,
            'updated_by': closedBy,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', monthKey);
      return true;
    } catch (e) {
      logError('closeMonthPlan', e);
      return false;
    }
  }

  /// Create a new month plan with custom week boundaries.
  /// [weekBoundaries] is a list of {start, end, label} maps defining the weeks.
  Future<bool> createMonthPlan({
    required String monthKey,
    required int year,
    required int month,
    required String monthStart,
    required String monthEnd,
    required List<ForecastWeek> weeks,
    required String createdBy,
  }) async {
    try {
      final plan = ForecastMonthPlan(
        id: monthKey,
        year: year,
        month: month,
        monthStart: monthStart,
        monthEnd: monthEnd,
        weeks: weeks,
        isClosed: false,
        createdBy: createdBy,
        createdAt: DateTime.now().toIso8601String(),
      );
      await client.from('forecast_month_plans').insert(plan.toJson());
      return true;
    } catch (e) {
      logError('createMonthPlan', e);
      return false;
    }
  }

  /// Generate week boundaries for a month based on a custom week start weekday.
  /// [weekStartWeekday] is 1=Monday ... 7=Sunday in Dart's DateTime.
  /// This allows the admin to define weeks like Tue–Thu, Thu–Sat, etc.
  static List<ForecastWeek> generateCustomWeeks({
    required DateTime monthStart,
    required DateTime monthEnd,
    required int weekStartWeekday,
  }) {
    final weeks = <ForecastWeek>[];
    var currentDate = monthStart;
    var weekIndex = 1;

    while (currentDate.isBefore(monthEnd) ||
        (currentDate.year == monthEnd.year &&
            currentDate.month == monthEnd.month &&
            currentDate.day == monthEnd.day)) {
      // Find the start of this week (based on custom weekStartWeekday)
      var weekStart = _findWeekStart(currentDate, weekStartWeekday);
      if (weekStart.isBefore(monthStart)) {
        weekStart = monthStart;
      }

      // Find the end of this week (6 days later)
      var weekEnd = weekStart.add(const Duration(days: 6));
      if (weekEnd.isAfter(monthEnd)) {
        weekEnd = monthEnd;
      }

      weeks.add(ForecastWeek(
        index: weekIndex,
        start: DateFormat('yyyy-MM-dd').format(weekStart),
        end: DateFormat('yyyy-MM-dd').format(weekEnd),
        label: 'الأسبوع $weekIndex',
      ));

      weekIndex++;
      currentDate = weekEnd.add(const Duration(days: 1));
      if (currentDate.isAfter(monthEnd)) break;
    }

    return weeks;
  }

  static DateTime _findWeekStart(DateTime date, int weekStartWeekday) {
    var weekday = date.weekday;
    if (weekday < weekStartWeekday) {
      weekday += 7;
    }
    final daysToSubtract = weekday - weekStartWeekday;
    return date.subtract(Duration(days: daysToSubtract));
  }

  /// Public converter (mirrors the private helper that previously lived in
  /// models.dart so it can be shared across repositories).
  static String forecastStatusToString(ForecastStatusType status) {
    switch (status) {
      case ForecastStatusType.draft:
        return 'draft';
      case ForecastStatusType.submitted:
        return 'submitted';
      case ForecastStatusType.approved:
        return 'approved';
      case ForecastStatusType.changeRequested:
        return 'change_requested';
    }
  }
}
