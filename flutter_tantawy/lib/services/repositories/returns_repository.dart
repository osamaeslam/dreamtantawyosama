import '../../models/models.dart';
import 'base_repository.dart';

/// All Supabase read/write operations for returns.
class ReturnsRepository extends BaseRepository {
  const ReturnsRepository();

  // ===================== المرتجعات (Returns) =====================
  Future<List<ReturnRecord>> fetchReturns({
    String? repName,
    String? branchName,
    String? invoiceNumber,
  }) async {
    try {
      var query = client.from('returns').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
        query = query.eq('invoice_number', invoiceNumber);
      }
      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>)
          .map((e) => ReturnRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchReturns', e);
      return [];
    }
  }

  Future<bool> createReturnRecord(ReturnRecord record) async {
    try {
      await client.from('returns').insert(record.toJson());
      return true;
    } catch (e) {
      logError('createReturnRecord', e);
      return false;
    }
  }
}
