import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'connectivity_service.dart';
import 'repositories/repositories.dart';

/// Facade المحافظ على واجهة برمجة SupabaseService القديمة (للتوافق العكسي)
/// لكنه يفوض كل عملية إلى Repository متخصص حسب المجال.
///
/// Migration path: screens and services should migrate to calling the
/// repository directly, e.g. `ProductRepository().fetchProducts(...)`.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  final ConnectivityService _connectivity = ConnectivityService.instance;

  /// Gatekeeper for financially-sensitive operations.
  ///
  /// Creating invoices, collecting payments, and transferring inventory
  /// **must** happen online to prevent concurrent-write conflicts
  /// (e.g. two reps exceeding a shared credit limit).
  /// This performs a *real* server probe — not just a network signal.
  Future<void> requireOnline() async {
    final status = _connectivity.currentStatus;
    if (status == ConnectionStatus.online) return;

    // Force a fresh real probe.
    final reachable = await _connectivity.pingServer();
    if (!reachable) {
      throw const SocketException('غير متصل بالخادم — العمليات المالية تتطلب اتصالاً نشطاً');
    }
  }

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
    final clean = username.trim();
    try {
      final response = await client
          .from('users')
          .select()
          .or('username.eq.$clean,phone.eq.$clean,email.eq.$clean')
          .maybeSingle();

      if (response != null) {
        final storedHash = response['password']?.toString() ?? '';
        final isActive = response['is_active'] as bool? ??
            (response['is_active'] == 1);

        if (isActive && _verifyPassword(password, storedHash)) {
          return AppUser.fromJson(Map<String, dynamic>.from(response));
        }

        debugPrint('Login failed for $clean — password mismatch or inactive user');
        return null;
      }
    } catch (e) {
      debugPrint('Supabase login query error (or offline mode): $e');
    }

    return null;
  }

  /// Verifies a plaintext password against a stored hash.
  /// Supports multiple formats:
  ///  - Django SHA256: sha256$iterations$salt$hash
  ///  - bcrypt: bcrypt$version$hash  (or $2b$...)
  ///  - argon2: argon2$...
  ///  - Plain text fallback (insecure, for development only)
  bool _verifyPassword(String password, String storedHash) {
    if (storedHash.isEmpty || password.isEmpty) return false;

    // Django SHA256 format: sha256$iterations$salt$hash
    if (storedHash.startsWith('sha256$')) {
      return _verifyDjangoSha256(password, storedHash);
    }

    // bcrypt format: $2a$, $2b$, $2y$
    if (storedHash.startsWith('\$2') || storedHash.toLowerCase().startsWith('bcrypt$')) {
      return _verifyBcrypt(password, storedHash);
    }

    // argon2 format
    if (storedHash.startsWith('argon2')) {
      // Argon2 verification would require additional package
      // For now, fall through to direct comparison as fallback
      return storedHash == password;
    }

    // Direct comparison (plain text / development fallback)
    return storedHash == password;
  }

  /// Django SHA256 password verification
  /// Format: sha256$iterations$salt$hash
  bool _verifyDjangoSha256(String password, String storedHash) {
    final parts = storedHash.split(r'$');
    if (parts.length != 4 || parts[0] != 'sha256') return false;

    try {
      final iterations = int.parse(parts[1]);
      final salt = parts[2];
      final expectedHash = parts[3];

      var bytes = utf8.encode(password + salt);
      for (int i = 0; i < iterations; i++) {
        bytes = sha256.convert(bytes).bytes;
      }

      return base64Encode(bytes) == expectedHash;
    } catch (e) {
      debugPrint('Django SHA256 verification error: $e');
      return false;
    }
  }

  /// bcrypt password verification
  /// Supports both bcrypt-prefixed and standard $2b$ formats
  bool _verifyBcrypt(String password, String storedHash) {
    try {
      // Handle bcrypt$ prefix format
      final hash = storedHash.toLowerCase().startsWith('bcrypt$')
          ? storedHash.substring(7)
          : storedHash;

      // BCrypt.checkpw returns true if password matches the hash
      return BCrypt.checkpw(password, hash);
    } catch (e) {
      debugPrint('bcrypt verification error: $e');
      return false;
    }
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

  // ===================== العملاء (Customers) =====================
  Future<List<Customer>> fetchCustomers({
    String? repName,
    String? repId,
    String? branchName,
  }) {
    return _customers.fetchCustomers(
      repName: repName,
      repId: repId,
      branchName: branchName,
    );
  }

  // ===================== الطلبيات والفواتين (Orders & Invoices) =====================
  Future<List<OrderInvoice>> fetchInvoices({
    String? repName,
    String? status,
    String? branchName,
    DateTime? startDate,
    DateTime? endDateExclusive,
  }) {
    return _invoices.fetchInvoices(
      repName: repName,
      status: status,
      branchName: branchName,
      startDate: startDate,
      endDateExclusive: endDateExclusive,
    );
  }

  Future<bool> createInvoice(OrderInvoice invoice) async {
    await requireOnline();
    return _invoices.createInvoice(invoice);
  }

  Future<bool> updateInvoiceStatus(String invoiceId, String newStatus) async {
    await requireOnline();
    return _invoices.updateInvoiceStatus(invoiceId, newStatus);
  }

  Future<bool> reserveStock({required String productId, required int cartonsToReserve}) async {
    await requireOnline();
    return _products.reserveStock(productId: productId, cartonsToReserve: cartonsToReserve);
  }

  // ===================== الزيارات الميدانية (Visits) =====================
  Future<List<CustomerVisit>> fetchVisits({
    String? repName,
    String? branchName,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDateExclusive,
  }) {
    return _visits.fetchVisits(
      repName: repName,
      branchName: branchName,
      date: date,
      startDate: startDate,
      endDateExclusive: endDateExclusive,
    );
  }

  Future<bool> logVisit(CustomerVisit visit) => _visits.logVisit(visit);

  Future<bool> archiveVisit({
    required String visitId,
    required String archivedBy,
  }) {
    return _visits.archiveVisit(
      visitId: visitId,
      archivedBy: archivedBy,
    );
  }

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
