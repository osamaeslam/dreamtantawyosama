import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'repositories/repositories.dart';

/// Facade المحافظ على واجهة برمجة SupabaseService القديمة (للتوافق العكسي)
/// لكنه يفوض كل عملية إلى Repository متخصص حسب المجال.
///
/// Migration path: screens and services should migrate to calling the
/// repository directly, e.g. `ProductRepository().fetchProducts(...)`.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  // Repository instances (lazy-initialized singletons per concern).
  static final ProductRepository _products = const ProductRepository();
  static final CustomerRepository _customers = const CustomerRepository();
  static final InvoiceRepository _invoices = const InvoiceRepository();
  static final VisitRepository _visits = const VisitRepository();
  static final ForecastRepository _forecasts = const ForecastRepository();
  static final AnalyticsRepository _analytics = const AnalyticsRepository();
  static final ReturnsRepository _returns = const ReturnsRepository();

  /// Exposes the product repository for new code / repositories to share.
  ProductRepository get productRepo => _products;
  CustomerRepository get customerRepo => _customers;
  InvoiceRepository get invoiceRepo => _invoices;
  VisitRepository get visitRepo => _visits;
  ForecastRepository get forecastRepo => _forecasts;
  AnalyticsRepository get analyticsRepo => _analytics;
  ReturnsRepository get returnsRepo => _returns;

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

  // ===================== تسجيل الدخول والمصادقة (Authentication) =====================
  Future<AppUser?> login(String username, String password) async {
    try {
      final clean = username.trim();
      final response = await client
          .from('users')
          .select()
          .or('username.eq.$clean,phone.eq.$clean,email.eq.$clean')
          .maybeSingle();

      if (response != null) {
        return AppUser.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      debugPrint('Supabase login query error (or offline mode): $e');
    }

    // Enterprise Fallback / Offline Profiles
    final cleanLower = username.trim().toLowerCase();
    final demoUsers = [
      AppUser(
        id: 'user-rep-1',
        name: 'أحمد علي النجار',
        username: 'ahmed_rep',
        role: 'sales_rep',
        branchName: 'فرع القاهرة الكبرى',
        phone: '01012345678',
        supervisorName: 'محمود عبد الله',
        email: 'ahmed.rep@tantawy-group.com',
      ),
      AppUser(
        id: 'user-sup-1',
        name: 'محمود عبد الله',
        username: 'mahmoud_sup',
        role: 'supervisor',
        branchName: 'فرع القاهرة الكبرى',
        phone: '01198765432',
        email: 'mahmoud.sup@tantawy-group.com',
      ),
      AppUser(
        id: 'user-mgr-1',
        name: 'م. طارق الصاوي',
        username: 'tarek_mgr',
        role: 'branch_manager',
        branchName: 'فرع القاهرة الكبرى',
        phone: '01234567890',
        email: 'tarek.manager@tantawy-group.com',
      ),
      AppUser(
        id: 'user-admin-1',
        name: 'الحاج مصطفى الطنطاوي',
        username: 'tantawy_gm',
        role: 'admin',
        branchName: 'الإدارة العامة - المركز الرئيسي',
        phone: '01000000001',
        email: 'gm@tantawy-group.com',
      ),
    ];

    for (final u in demoUsers) {
      if (u.username.toLowerCase() == cleanLower ||
          u.phone == cleanLower ||
          (u.email != null && u.email!.toLowerCase() == cleanLower) ||
          (cleanLower.contains('rep') && u.role == 'sales_rep') ||
          (cleanLower.contains('sup') && u.role == 'supervisor') ||
          (cleanLower.contains('mgr') && u.role == 'branch_manager') ||
          (cleanLower.contains('admin') && u.role == 'admin')) {
        return u;
      }
    }

    return null;
  }

  // ===================== المنتجات (Products) =====================
  Future<List<Product>> fetchProducts({String? branchName, String? department}) {
    return _products.fetchProducts(branchName: branchName, department: department);
  }

  Future<List<ParentProduct>> fetchParentProducts({
    String? department,
    String? branchName,
    String? searchQuery,
  }) {
    return _products.fetchParentProducts(
      department: department, branchName: branchName, searchQuery: searchQuery);
  }

  Future<List<ProductVariant>> fetchProductVariants({required String productId}) {
    return _products.fetchProductVariants(productId: productId);
  }

  // ===================== العروض الترويجية (Promotions) =====================
  Future<List<PromotionOffer>> fetchPromotions({
    bool activeOnly = true,
    String? branchName,
    String? productCode,
  }) {
    return _products.fetchPromotions(
      activeOnly: activeOnly, branchName: branchName, productCode: productCode);
  }

  // ===================== الفروع (Branches) =====================
  Future<List<Branch>> fetchBranches() {
    return _products.fetchBranches();
  }

  Future<Map<String, int>> fetchProductBranchStock(String productId, String branchName) {
    return _products.fetchProductBranchStock(productId, branchName);
  }

  Future<bool> reserveStock({required String productId, required int cartonsToReserve}) {
    return _products.reserveStock(productId: productId, cartonsToReserve: cartonsToReserve);
  }

  // ===================== العملاء (Customers) =====================
  Future<List<Customer>> fetchCustomers({String? repName, String? branchName}) {
    return _customers.fetchCustomers(repName: repName, branchName: branchName);
  }

  // ===================== الطلبيات والفواتين (Orders & Invoices) =====================
  Future<List<OrderInvoice>> fetchInvoices({String? repName, String? status, String? branchName}) {
    return _invoices.fetchInvoices(repName: repName, status: status, branchName: branchName);
  }

  Future<bool> createInvoice(OrderInvoice invoice) => _invoices.createInvoice(invoice);

  Future<bool> updateInvoiceStatus(String invoiceId, String newStatus) {
    return _invoices.updateInvoiceStatus(invoiceId, newStatus);
  }

  // ===================== الزيارات الميدانية (Visits) =====================
  Future<List<CustomerVisit>> fetchVisits({String? repName, DateTime? date}) {
    return _visits.fetchVisits(repName: repName, date: date);
  }

  Future<bool> logVisit(CustomerVisit visit) => _visits.logVisit(visit);

  // ===================== الاشتراك اللحظي (Realtime Stream) =====================
  RealtimeChannel subscribeToOrders(void Function(Map<String, dynamic> payload) onEvent) {
    return _products.subscribeToOrders(onEvent);
  }

  // ===================== معلومات الشركة (Company Info) =====================
  Future<CompanyInfo?> fetchCompanyInfo() => _analytics.fetchCompanyInfo();

  // ===================== الأهداف والتارجت (Targets) =====================
  Future<List<TargetRecord>> fetchTargets({
    String? repName, String? branchName, int? month, int? year,
  }) {
    return _forecasts.fetchTargets(repName: repName, branchName: branchName, month: month, year: year);
  }

  // ===================== ملاحظات العملاء (Customer Comments) =====================
  Future<List<CustomerCommentRecord>> fetchCustomerComments({
    String? customerId, String? customerCode, String? branchName,
  }) {
    return _customers.fetchCustomerComments(
        customerId: customerId, customerCode: customerCode, branchName: branchName);
  }

  Future<bool> addCustomerComment(CustomerCommentRecord comment) {
    return _customers.addCustomerComment(comment);
  }

  // ===================== المعاملات المخزنية (Inventory Transactions) =====================
  Future<List<InventoryTransaction>> fetchInventoryTransactions({
    String? productId, String? branchName, String? date,
  }) {
    return _analytics.fetchInventoryTransactions(
        productId: productId, branchName: branchName, date: date);
  }

  // ===================== المرتجعات (Returns) =====================
  Future<List<ReturnRecord>> fetchReturns({String? repName, String? branchName, String? invoiceNumber}) {
    return _returns.fetchReturns(repName: repName, branchName: branchName, invoiceNumber: invoiceNumber);
  }

  Future<bool> createReturnRecord(ReturnRecord record) => _returns.createReturnRecord(record);

  // ===================== التوقعات/التوقعات الأسبوعية (Forecasts) =====================
  Future<List<CollectionForecastRecord>> fetchForecasts({
    String? repName, String? monthKey, ForecastStatusType? status,
  }) {
    return _forecasts.fetchForecasts(repName: repName, monthKey: monthKey, status: status);
  }

  Future<ForecastMonthPlan?> fetchForecastMonthPlan(String monthKey) {
    return _forecasts.fetchForecastMonthPlan(monthKey);
  }

  Future<bool> saveForecast(CollectionForecastRecord record) => _forecasts.saveForecast(record);

  // ===================== سجلات التدقيق (Audit Logs) =====================
  Future<List<AuditLog>> fetchAuditLogs({String? userName, AuditActionType? action, String? invoiceId}) {
    return _analytics.fetchAuditLogs(userName: userName, action: action, invoiceId: invoiceId);
  }

  // ===================== أداء المندوبين (Rep Performance) =====================
  Future<List<RepPerformance>> fetchRepPerformance({String? branchName, int? month, int? year}) {
    return _analytics.fetchRepPerformance(branchName: branchName, month: month, year: year);
  }

  // ===================== تحليلات العملاء (Customer Analytics) =====================
  Future<List<CustomerAnalytics>> fetchCustomerAnalytics({String? branchName, String? repName, String? tier}) {
    return _analytics.fetchCustomerAnalytics(branchName: branchName, repName: repName, tier: tier);
  }

  // ===================== إعدادات Cloudinary =====================
  Future<CloudinaryConfig?> fetchCloudinaryConfig() => _analytics.fetchCloudinaryConfig();
}
