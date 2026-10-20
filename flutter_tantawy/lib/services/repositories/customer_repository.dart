import '../../models/models.dart';
import 'base_repository.dart';

/// All Supabase read/write operations for customers and their comments.
class CustomerRepository extends BaseRepository {
  const CustomerRepository();

  Future<List<Customer>> fetchCustomers({
    String? repName,
    String? repId,
    String? branchName,
  }) async {
    // 1. Try querying 'clients' table (user's real database table with clients)
    try {
      var query = client.from('clients').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.or('mandoub_name.ilike.%$repName%,rep_name.ilike.%$repName%');
      }
      if (branchName != null && branchName.isNotEmpty && branchName != 'المركز الرئيسي' && branchName != 'كل الفروع') {
        query = query.ilike('branch', '%$branchName%');
      }
      final data = await query.order('client_name');
      final list = (data as List<dynamic>)
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (e) {
      logError('fetchCustomers from clients', e);
    }

    // 2. Fallback to 'customers' table
    try {
      var query = client.from('customers').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      final data = await query.order('name');
      return (data as List<dynamic>)
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchCustomers from customers', e);
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
