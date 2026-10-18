import '../../models/models.dart';
import 'base_repository.dart';

/// All Supabase read/write operations for field visits (GPS-tracked).
class VisitRepository extends BaseRepository {
  const VisitRepository();

  // ===================== الزيارات الميدانية (Visits) =====================
  Future<List<CustomerVisit>> fetchVisits({
    String? repName,
    DateTime? date,
  }) async {
    try {
      var query = client.from('visits').select();
      if (repName != null) {
        query = query.eq('rep_name', repName);
      }
      final data = await query.order('date', ascending: false);
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
      await client.from('visits').insert(visit.toJson());
      return true;
    } catch (e) {
      logError('logVisit', e);
      return false;
    }
  }
}
