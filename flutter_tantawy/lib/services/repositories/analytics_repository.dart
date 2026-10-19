import '../../models/models.dart';
import 'base_repository.dart';

/// All Supabase read operations for analytics, performance, company settings
/// and inventory transactions.
class AnalyticsRepository extends BaseRepository {
  const AnalyticsRepository();

  // ===================== تحليلات العملاء (Customer Analytics) =====================
  Future<List<CustomerAnalytics>> fetchCustomerAnalytics({
    String? branchName,
    String? repName,
    String? tier,
  }) async {
    try {
      var query = client.from('customer_analytics').select();
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      if (tier != null && tier.isNotEmpty) {
        query = query.eq('tier', tier);
      }
      final data = await query.order('total_sales', ascending: false);
      return (data as List<dynamic>)
          .map((e) => CustomerAnalytics.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchCustomerAnalytics', e);
      return [];
    }
  }

  // ===================== أداء المندوبين (Rep Performance) =====================
  Future<List<RepPerformance>> fetchRepPerformance({
    String? branchName,
    int? month,
    int? year,
  }) async {
    try {
      var query = client.from('rep_performance').select();
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (month != null) {
        query = query.eq('month', month);
      }
      if (year != null) {
        query = query.eq('year', year);
      }
      final data = await query.order('sales_achieved', ascending: false);
      return (data as List<dynamic>)
          .map((e) => RepPerformance.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchRepPerformance', e);
      return [];
    }
  }

  // ===================== معلومات الشركة (Company Info) =====================
  Future<CompanyInfo?> fetchCompanyInfo() async {
    try {
      final data =
          await client.from('company_info').select().maybeSingle();
      if (data == null) return null;
      return CompanyInfo.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      logError('fetchCompanyInfo', e);
      return null;
    }
  }

  // ===================== إعدادات Cloudinary =====================
  Future<CloudinaryConfig?> fetchCloudinaryConfig() async {
    try {
      final data =
          await client.from('cloudinary_config').select().maybeSingle();
      if (data == null) return null;
      return CloudinaryConfig.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      logError('fetchCloudinaryConfig', e);
      return null;
    }
  }

  // ===================== المعاملات المخزنية (Inventory Transactions) =====================
  Future<List<InventoryTransaction>> fetchInventoryTransactions({
    String? productId,
    String? branchName,
    String? date,
  }) async {
    try {
      var query = client.from('inventory_transactions').select();
      if (productId != null && productId.isNotEmpty) {
        query = query.eq('product_id', productId);
      }
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (date != null && date.isNotEmpty) {
        query = query.eq('date', date);
      }
      final data = await query.order('timestamp', ascending: false);
      return (data as List<dynamic>)
          .map((e) =>
              InventoryTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchInventoryTransactions', e);
      return [];
    }
  }

  // ===================== سجلات التدقيق (Audit Logs) =====================
  Future<List<AuditLog>> fetchAuditLogs({
    String? userName,
    AuditActionType? action,
    String? invoiceId,
  }) async {
    try {
      var query = client.from('audit_log').select();
      if (userName != null && userName.isNotEmpty) {
        query = query.eq('user_name', userName);
      }
      if (action != null) {
        query = query.eq('action', AnalyticsRepository.auditActionTypeToString(action));
      }
      if (invoiceId != null && invoiceId.isNotEmpty) {
        query = query.eq('invoice_id', invoiceId);
      }
      final data = await query.order('timestamp', ascending: false);
      return (data as List<dynamic>)
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('fetchAuditLogs', e);
      return [];
    }
  }

  /// Public converter for audit action enums (shared across repositories).
  static String auditActionTypeToString(AuditActionType action) {
    switch (action) {
      case AuditActionType.createInvoice:
        return 'create_invoice';
      case AuditActionType.updateInvoiceStatus:
        return 'update_invoice_status';
      case AuditActionType.approveInvoice:
        return 'approve_invoice';
      case AuditActionType.cancelInvoice:
        return 'cancel_invoice';
      case AuditActionType.returnInvoice:
        return 'return_invoice';
      case AuditActionType.deleteInvoice:
        return 'delete_invoice';
      case AuditActionType.importProducts:
        return 'import_products';
      case AuditActionType.stockAdjustment:
        return 'stock_adjustment';
      case AuditActionType.userLogin:
        return 'user_login';
      case AuditActionType.createUser:
        return 'create_user';
      case AuditActionType.updateUser:
        return 'update_user';
    }
  }
}
