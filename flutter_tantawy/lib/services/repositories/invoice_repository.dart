import '../../models/models.dart';
import 'base_repository.dart';

/// All Supabase read/write operations for invoices (orders & their statuses).
class InvoiceRepository extends BaseRepository {
  const InvoiceRepository();

  // ===================== الطلبيات والفواتير (Orders & Invoices) =====================
  Future<List<OrderInvoice>> fetchInvoices({
    String? repName,
    String? status,
    String? branchName,
  }) async {
    try {
      var query = client.from('invoices').select();
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      if (status != null && status != 'الكل') {
        query = query.eq('status', status);
      }
      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>)
          .map((e) => OrderInvoice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchInvoices', e);
      return [];
    }
  }

  Future<bool> createInvoice(OrderInvoice invoice) async {
    try {
      await client.from('invoices').insert(invoice.toJson());
      return true;
    } catch (e) {
      logError('createInvoice', e);
      return false;
    }
  }

  /// اعتماد الفاتورة من المشرف
  Future<bool> updateInvoiceStatus(String invoiceId, String newStatus) async {
    try {
      await client
          .from('invoices')
          .update({'status': newStatus})
          .eq('id', invoiceId);
      return true;
    } catch (e) {
      logError('updateInvoiceStatus', e);
      return false;
    }
  }
}
