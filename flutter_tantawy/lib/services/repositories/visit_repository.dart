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
      if (repName != null && repName.isNotEmpty) {
        query = query.or('mandoub_name.ilike.%$repName%,rep_name.ilike.%$repName%');
      }
      if (branchName != null && branchName.isNotEmpty && branchName != 'المركز الرئيسي' && branchName != 'كل الفروع') {
        query = query.ilike('branch', '%$branchName%');
      }
      final data = await query.order('id', ascending: false);
      return (data as List<dynamic>)
          .map((e) => CustomerVisit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchVisits', e);
      return [];
    }
  }

  Future<bool> logVisit(CustomerVisit visit) async {
    try {
      final payload = {
        'mandoub_id': visit.repId ?? '',
        'mandoub_name': visit.repName,
        'client_code': visit.customerCode ?? visit.customerId,
        'client_name': visit.customerName,
        'type': visit.type,
        'amount': visit.collectedAmount,
        'notes': visit.notes ?? '',
        'timestamp': DateTime.now().toIso8601String(),
        'branch': visit.branchName ?? 'المركز الرئيسي',
      };
      await client.from('visits').insert(payload);
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
