import '../../models/models.dart';
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
