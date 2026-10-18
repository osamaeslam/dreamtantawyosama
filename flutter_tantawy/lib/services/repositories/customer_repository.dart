import '../../models/models.dart';
import 'base_repository.dart';

/// All Supabase read/write operations for customers and their comments.
class CustomerRepository extends BaseRepository {
  const CustomerRepository();

  Future<List<Customer>> fetchCustomers({
    String? repName,
    String? branchName,
  }) async {
    try {
      var query = client.from('customers').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      final data = await query.order('name');
      return (data as List<dynamic>)
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchCustomers', e);
      return [];
    }
  }

  // ===================== ملاحظات العملاء (Customer Comments) =====================
  Future<List<CustomerCommentRecord>> fetchCustomerComments({
    String? customerId,
    String? customerCode,
    String? branchName,
  }) async {
    try {
      var query = client.from('customer_comments').select();
      if (customerId != null && customerId.isNotEmpty) {
        query = query.eq('customer_id', customerId);
      }
      if (customerCode != null && customerCode.isNotEmpty) {
        query = query.eq('customer_code', customerCode);
      }
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((e) => CustomerCommentRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchCustomerComments', e);
      return [];
    }
  }

  Future<bool> addCustomerComment(CustomerCommentRecord comment) async {
    try {
      await client.from('customer_comments').insert(comment.toJson());
      return true;
    } catch (e) {
      logError('addCustomerComment', e);
      return false;
    }
  }
}
