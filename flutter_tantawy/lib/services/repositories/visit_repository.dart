import '../../models/models.dart';
import 'base_repository.dart';

/// All Supabase read/write operations for field visits (GPS-tracked).
class VisitRepository extends BaseRepository {
  const VisitRepository();

  // ===================== الزيارات الميدانية (Visits) =====================
  Future<List<CustomerVisit>> fetchVisits({
    String? repName,
    String? branchName,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDateExclusive,
  }) async {
    try {
      var query = client.from('visits').select();
      if (repName != null) {
        query = query.eq('rep_name', repName);
      }
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (date != null) {
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));
        query = query
            .gte('date', start.toIso8601String())
            .lt('date', end.toIso8601String());
      } else {
        if (startDate != null) {
          query = query.gte('date', startDate.toIso8601String());
        }
        if (endDateExclusive != null) {
          query = query.lt('date', endDateExclusive.toIso8601String());
        }
      }
      query = query.or('is_archived.is.null,is_archived.eq.false');
      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>)
          .map((e) => CustomerVisit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchVisits', e);
      rethrow;
    }
  }

  Future<bool> logVisit(CustomerVisit visit) async {
    try {
      await client.from('visits').insert(visit.toJson());
      return true;
    } catch (e) {
      logError('logVisit', e);
      return false;
    }
  }

  Future<bool> archiveVisit({
    required String visitId,
    required String archivedBy,
  }) async {
    try {
      final result = await client
          .from('visits')
          .update({
            'is_archived': true,
            'archived_at': DateTime.now().toIso8601String(),
            'archived_by': archivedBy,
          })
          .eq('id', visitId)
          .select('id');
      return (result as List<dynamic>).isNotEmpty;
    } catch (e) {
      logError('archiveVisit', e);
      return false;
    }
  }
}
