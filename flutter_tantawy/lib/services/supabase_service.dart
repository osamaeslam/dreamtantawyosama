import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'role_access_controller.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient? _client;
  SupabaseClient get client {
    _client ??= Supabase.instance.client;
    return _client!;
  }

  // تهيئة الاتصال بقاعدة بيانات Supabase
  static Future<void> initialize({
    required String supabaseUrl,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: kDebugMode,
    );
  }

  // ===================== المنتجات (Products) =====================
  Future<List<Product>> fetchProducts({String? branchName, String? department}) async {
    try {
      var query = client.from('products').select();
      if (department != null && department != 'الكل') {
        query = query.eq('department', department);
      }
      final data = await query.order('name');
      return (data as List<dynamic>).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching products from Supabase: $e');
      return [];
    }
  }

  /// جلب منتجات مجمّعة مع متغيّرها (الألوان/النوافذ) — يطابق بنية ParentProduct في types.ts
  Future<List<ParentProduct>> fetchParentProducts({
    String? department,
    String? branchName,
    String? searchQuery,
  }) async {
    try {
      var query = client.from('parent_products').select('*, variants:variants!inner(*)');
      if (department != null && department != 'الكل') {
        query = query.eq('department', department);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,primary_code.ilike.%$searchQuery%,unified_code.ilike.%$searchQuery%');
      }
      final data = await query.order('name');
      return (data as List<dynamic>)
          .map((e) => ParentProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching parent products with variants: $e');
      // fallback: wrap flat products into ParentProduct
      final products = await fetchProducts(branchName: branchName, department: department);
      return products.map((p) {
        final fallbackVariant = ProductVariant(
          id: '${p.id}_default',
          productId: p.id,
          code: p.code,
          name: p.name,
          color: p.color ?? 'أبيض',
          branchStockActual: p.branchStockActual,
          branchStockReserved: p.branchStockReserved,
          cartonQuantity: p.cartonQuantity,
          piecePrice: p.piecePrice,
          cartonPrice: p.cartonPrice,
          promoPrice: p.promoPrice,
          status: p.status,
          imageUrl: p.imageUrl,
          unifiedCode: p.unifiedCode,
        );
        return ParentProduct(
          id: p.id,
          primaryCode: p.code,
          unifiedCode: p.unifiedCode,
          name: p.name,
          department: p.department,
          category: p.category,
          classification: p.classification,
          familyName: p.familyName,
          salesPriority: p.salesPriority,
          status: p.status,
          cartonQuantity: p.cartonQuantity,
          imageUrl: p.imageUrl,
          minPrice: p.cartonPrice,
          maxPrice: p.cartonPrice,
          totalBranchStock: p.availableStock,
          variants: [fallbackVariant],
          variantsCount: 1,
          hasMultipleVariants: false,
          defaultVariant: fallbackVariant,
        );
      }).toList();
    }
  }

  /// جلب متغيّرات منتج واحد (الألوان والنوافذ/الشبابيك)
  Future<List<ProductVariant>> fetchProductVariants({required String productId}) async {
    try {
      final data = await client
          .from('product_variants')
          .select()
          .eq('product_id', productId)
          .order('name');
      return (data as List<dynamic>)
          .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching product variants: $e');
      return [];
    }
  }

  // ===================== العروض الترويجية (Promotions) =====================
  Future<List<PromotionOffer>> fetchPromotions({
    bool activeOnly = true,
    String? branchName,
    String? productCode,
  }) async {
    try {
      var query = client.from('promotions').select();
      if (activeOnly) {
        final now = DateTime.now().toIso8601String();
        query = query.eq('status', 'نشط').gte('start_date', now).lte('end_date', now);
      }
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (productCode != null && productCode.isNotEmpty) {
        query = query.eq('product_code', productCode);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((e) => PromotionOffer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching promotions: $e');
      return [];
    }
  }

  // ===================== الفروع (Branches) =====================
  Future<List<Branch>> fetchBranches() async {
    try {
      final data = await client.from('branches').select();
      return (data as List<dynamic>).map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching branches: $e');
      return [];
    }
  }

  /// جلب أرصدة فرع محدد لمنتج — يدعم شاشة كتالوج المنتجات
  Future<Map<String, int>> fetchProductBranchStock(String productId, String branchName) async {
    try {
      final data = await client
          .from('product_stocks')
          .select('quantity_actual, quantity_reserved')
          .eq('product_id', productId)
          .eq('branch_name', branchName)
          .maybeSingle();
      if (data == null) return {};
      return {
        'actual': (data['quantity_actual'] as num?)?.toInt() ?? 0,
        'reserved': (data['quantity_reserved'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching product branch stock: $e');
      return {};
    }
  }

  // تحديث رصيد الصنف لمنع الحجز المزدوج
  Future<bool> reserveStock({
    required String productId,
    required int cartonsToReserve,
  }) async {
    try {
      final res = await client.rpc('reserve_product_stock', params: {
        'p_id': productId,
        'quantity': cartonsToReserve,
      });
      return res == true;
    } catch (e) {
      debugPrint('Error reserving stock: $e');
      return false;
    }
  }

  // ===================== العملاء (Customers) =====================
  Future<List<Customer>> fetchCustomers({String? repName, String? branchName}) async {
    try {
      var query = client.from('customers').select();
      if (repName != null && repName.isNotEmpty) {
        query = query.eq('rep_name', repName);
      }
      final data = await query.order('name');
      return (data as List<dynamic>).map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching customers from Supabase: $e');
      return [];
    }
  }

  // ===================== الطلبيات والفواتير (Orders & Invoices) =====================
  Future<List<OrderInvoice>> fetchInvoices({String? repName, String? status, String? branchName}) async {
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
      return (data as List<dynamic>).map((e) => OrderInvoice.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
      return [];
    }
  }

  Future<bool> createInvoice(OrderInvoice invoice) async {
    try {
      await client.from('invoices').insert(invoice.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving invoice: $e');
      return false;
    }
  }

  // اعتماد الفاتورة من المشرف
  Future<bool> updateInvoiceStatus(String invoiceId, String newStatus) async {
    try {
      await client.from('invoices').update({'status': newStatus}).eq('id', invoiceId);
      return true;
    } catch (e) {
      debugPrint('Error updating invoice status: $e');
      return false;
    }
  }

  // ===================== الزيارات الميدانية (Visits) =====================
  Future<List<CustomerVisit>> fetchVisits({String? repName, DateTime? date}) async {
    try {
      var query = client.from('visits').select();
      if (repName != null) {
        query = query.eq('rep_name', repName);
      }
      final data = await query.order('date', ascending: false);
      return (data as List<dynamic>).map((e) => CustomerVisit.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching visits: $e');
      return [];
    }
  }

  Future<bool> logVisit(CustomerVisit visit) async {
    try {
      await client.from('visits').insert(visit.toJson());
      return true;
    } catch (e) {
      debugPrint('Error logging visit: $e');
      return false;
    }
  }

  // ===================== الاشتراك اللحظي (Realtime Stream) =====================
  RealtimeChannel subscribeToOrders(Function(Map<String, dynamic> payload) onEvent) {
    return client
        .channel('public:invoices')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          callback: (payload) => onEvent(payload.newRecord),
        )
        .subscribe();
  }

  // ===================== معلومات الشركة (Company Info) =====================
  Future<CompanyInfo?> fetchCompanyInfo() async {
    try {
      final data = await client.from('company_info').select().maybeSingle();
      if (data == null) return null;
      return CompanyInfo.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching company info: $e');
      return null;
    }
  }

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
      debugPrint('Error fetching targets: $e');
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
      debugPrint('Error fetching customer comments: $e');
      return [];
    }
  }

  Future<bool> addCustomerComment(CustomerCommentRecord comment) async {
    try {
      await client.from('customer_comments').insert(comment.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving customer comment: $e');
      return false;
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
          .map((e) => InventoryTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching inventory transactions: $e');
      return [];
    }
  }

  // ===================== الشيتات والعروض الترويجية (Promotions) =====================

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
      debugPrint('Error fetching returns: $e');
      return [];
    }
  }

  Future<bool> createReturnRecord(ReturnRecord record) async {
    try {
      await client.from('returns').insert(record.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving return record: $e');
      return false;
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
        query = query.eq('status', _forecastStatusToString(status));
      }
      final data = await query.order('month_key', ascending: false);
      return (data as List<dynamic>)
          .map((e) => CollectionForecastRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching forecasts: $e');
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
      debugPrint('Error fetching forecast month plan: $e');
      return null;
    }
  }

  Future<bool> saveForecast(CollectionForecastRecord record) async {
    try {
      await client.from('forecasts').upsert(record.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving forecast: $e');
      return false;
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
        query = query.eq('action', _auditActionTypeToString(action));
      }
      if (invoiceId != null && invoiceId.isNotEmpty) {
        query = query.eq('invoice_id', invoiceId);
      }
      final data = await query.order('timestamp', ascending: false);
      return (data as List<dynamic>)
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
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
      debugPrint('Error fetching rep performance: $e');
      return [];
    }
  }

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
      debugPrint('Error fetching customer analytics: $e');
      return [];
    }
  }

  
  // ===================== إعدادات Cloudinary =====================
  Future<CloudinaryConfig?> fetchCloudinaryConfig() async {
    try {
      final data = await client.from('cloudinary_config').select().maybeSingle();
      if (data == null) return null;
      return CloudinaryConfig.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error fetching cloudinary config: $e');
      return null;
    }
   }
}
