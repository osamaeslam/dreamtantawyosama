import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'connectivity_service.dart';
import 'repositories/repositories.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  final ConnectivityService _connectivity = ConnectivityService.instance;

  Future<void> requireOnline() async {
    final status = _connectivity.currentStatus;
    if (status == ConnectionStatus.online) return;

    final reachable = await _connectivity.pingServer();
    if (!reachable) {
      throw const SocketException(
          'غير متصل بالخادم — العمليات المالية تتطلب اتصالاً نشطاً');
    }
  }

  static const ProductRepository _products = ProductRepository();
  static const CustomerRepository _customers = CustomerRepository();
  static const InvoiceRepository _invoices = InvoiceRepository();
  static const VisitRepository _visits = VisitRepository();
  static const ForecastRepository _forecasts = ForecastRepository();
  static const AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  static const ReturnsRepository _returns = ReturnsRepository();
  static const ExpenseRepository _expenses = ExpenseRepository();

  ReturnsRepository get returnsRepo => _returns;
  AnalyticsRepository get analyticsRepo => _analyticsRepo;
  ForecastRepository get forecastRepo => _forecasts;

  SupabaseClient? _client;
  SupabaseClient get client {
    _client ??= Supabase.instance.client;
    return _client!;
  }

  // تهيئة الاتصال بقاعدة بيانات Supabase
  static Future<void> initialize({
    required String supabaseUrl,
    required String publishableKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: publishableKey,
      debug: kDebugMode,
    );
  }

  // ===================== تسجيل الدخول والمصادقة (Authentication) =====================
  /// Validates credentials against the secure [app_login] RPC.
  ///
  /// The RPC is `security definer` so the anonymous role never reads the
  /// password column directly; RLS on [app_users] stays enabled and there
  /// is no client-side fallback query (which would be rejected by RLS).
  Future<AppUser?> login(String username, String password) async {
    final clean = username.trim();
    final cleanPass = password.trim();
    if (clean.isEmpty || cleanPass.isEmpty) return null;

    try {
      final res = await client.rpc(
        'app_login',
        params: {'p_username': clean, 'p_password': cleanPass},
      );

      if (res == null) return null;
      if (res is List && res.isNotEmpty) {
        return AppUser.fromJson(Map<String, dynamic>.from(res.first));
      }
      if (res is Map && res.isNotEmpty) {
        return AppUser.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('Supabase login RPC error: $e');
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
    if (storedHash.startsWith('sha256\$')) {
      return _verifyDjangoSha256(password, storedHash);
    }

    // bcrypt format: $2a$, $2b$, $2y$
    if (storedHash.startsWith('\$2') ||
        storedHash.toLowerCase().startsWith('bcrypt\$')) {
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

      List<int> bytes = utf8.encode(password + salt);
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
      final hash = storedHash.toLowerCase().startsWith('bcrypt\$')
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
  Future<List<Product>> fetchProducts(
      {String? branchName, String? department}) {
    return _products.fetchProducts(
        branchName: branchName, department: department);
  }

  Future<List<ParentProduct>> fetchParentProducts({
    String? department,
    String? branchName,
    String? searchQuery,
  }) {
    return _products.fetchParentProducts(
        department: department,
        branchName: branchName,
        searchQuery: searchQuery);
  }

  Future<List<ProductVariant>> fetchProductVariants(
      {required String productId}) {
    return _products.fetchProductVariants(productId: productId);
  }

  // ===================== العروض الترويجية (Promotions) =====================
  Future<List<PromotionOffer>> fetchPromotions({
    bool activeOnly = true,
    String? branchName,
    String? productCode,
  }) {
    return _products.fetchPromotions(
        activeOnly: activeOnly,
        branchName: branchName,
        productCode: productCode);
  }

  // ===================== الفروع (Branches) =====================
  Future<List<Branch>> fetchBranches() {
    return _products.fetchBranches();
  }

  Future<Map<String, int>> fetchProductBranchStock(
      String productId, String branchName) {
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

  Future<bool> reserveStock(
      {required String productId, required int cartonsToReserve}) async {
    await requireOnline();
    return _products.reserveStock(
        productId: productId, cartonsToReserve: cartonsToReserve);
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

  Future<String?> scheduleVisit({
    required Customer customer,
    required AppUser representative,
    required DateTime scheduledAt,
    required String scheduledBy,
    String? forecastId,
  }) =>
      _visits.scheduleVisit(
        customer: customer,
        representative: representative,
        scheduledAt: scheduledAt,
        scheduledBy: scheduledBy,
        forecastId: forecastId,
      );

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
  RealtimeChannel subscribeToOrders(
      void Function(Map<String, dynamic> payload) onEvent) {
    return _products.subscribeToOrders(onEvent);
  }

  // ===================== معلومات الشركة (Company Info) =====================
  Future<CompanyInfo?> fetchCompanyInfo() => _analyticsRepo.fetchCompanyInfo();

  // ===================== الأهداف والتارجت (Targets) =====================
  Future<List<TargetRecord>> fetchTargets({
    String? repName,
    String? branchName,
    int? month,
    int? year,
  }) {
    return _forecasts.fetchTargets(
        repName: repName, branchName: branchName, month: month, year: year);
  }

  Future<bool> insertTarget(TargetRecord target) {
    return _forecasts.insertTarget(target);
  }

  Future<bool> upsertTargets(List<Map<String, dynamic>> targets) {
    return _forecasts.upsertTargets(targets);
  }

  // ===================== ملاحظات العملاء (Customer Comments) =====================
  Future<List<CustomerCommentRecord>> fetchCustomerComments({
    String? customerId,
    String? customerCode,
    String? branchName,
  }) {
    return _customers.fetchCustomerComments(
        customerId: customerId,
        customerCode: customerCode,
        branchName: branchName);
  }

  Future<bool> addCustomerComment(CustomerCommentRecord comment) {
    return _customers.addCustomerComment(comment);
  }

  // ===================== المعاملات المخزنية (Inventory Transactions) =====================
  Future<List<InventoryTransaction>> fetchInventoryTransactions({
    String? productId,
    String? branchName,
    String? date,
  }) {
    return _analyticsRepo.fetchInventoryTransactions(
        productId: productId, branchName: branchName, date: date);
  }

  // ===================== المرتجعات (Returns) =====================
  Future<List<ReturnRecord>> fetchReturns(
      {String? repName, String? branchName, String? invoiceNumber}) {
    return _returns.fetchReturns(
        repName: repName, branchName: branchName, invoiceNumber: invoiceNumber);
  }

  Future<bool> createReturnRecord(ReturnRecord record) =>
      _returns.createReturnRecord(record);

  // ===================== التوقعات/التوقعات الأسبوعية (Forecasts) =====================
  Future<List<CollectionForecastRecord>> fetchForecasts({
    String? repName,
    String? monthKey,
    ForecastStatusType? status,
  }) {
    return _forecasts.fetchForecasts(
        repName: repName, monthKey: monthKey, status: status);
  }

  Future<ForecastMonthPlan?> fetchForecastMonthPlan(String monthKey) {
    return _forecasts.fetchForecastMonthPlan(monthKey);
  }

  Future<bool> saveForecast(CollectionForecastRecord record) =>
      _forecasts.saveForecast(record);

  Future<bool> submitForecast(
    CollectionForecastRecord record, {
    required bool hasSupervisor,
  }) =>
      _forecasts.submitForecast(record, hasSupervisor: hasSupervisor);

  Future<bool> approveForecastBySupervisor({
    required String forecastId,
    required String supervisorName,
    double? collectionForecast,
    double? salesForecast,
  }) =>
      _forecasts.approveForecastBySupervisor(
        forecastId: forecastId,
        supervisorName: supervisorName,
        collectionForecast: collectionForecast,
        salesForecast: salesForecast,
      );

  Future<bool> approveForecastByBranchManager({
    required String forecastId,
    required String managerName,
    double? collectionForecast,
    double? salesForecast,
  }) =>
      _forecasts.approveForecastByBranchManager(
        forecastId: forecastId,
        managerName: managerName,
        collectionForecast: collectionForecast,
        salesForecast: salesForecast,
      );

  Future<bool> requestForecastChanges({
    required String forecastId,
    required String reviewerName,
    required String note,
    required String currentStage,
  }) =>
      _forecasts.requestForecastChanges(
        forecastId: forecastId,
        reviewerName: reviewerName,
        note: note,
        currentStage: currentStage,
      );

  Future<bool> updateForecastReturnStatus({
    required String forecastId,
    required String status,
    required String handledBy,
    String? note,
  }) =>
      _forecasts.updateReturnStatus(
        forecastId: forecastId,
        status: status,
        handledBy: handledBy,
        note: note,
      );

  Future<bool> updateForecastLegalReferral({
    required String forecastId,
    required String status,
    required String handledBy,
    String? note,
  }) =>
      _forecasts.updateLegalReferral(
        forecastId: forecastId,
        status: status,
        handledBy: handledBy,
        note: note,
      );

  Future<bool> linkForecastScheduledVisit({
    required String forecastId,
    required String visitId,
    required String visitDate,
    required String scheduledBy,
  }) =>
      _forecasts.linkScheduledVisit(
        forecastId: forecastId,
        visitId: visitId,
        visitDate: visitDate,
        scheduledBy: scheduledBy,
      );

  // ===================== إدارة أسابيع الشهر (Month Plan Week Config) =====================
  Future<bool> saveForecastMonthPlan(ForecastMonthPlan monthPlan) =>
      _forecasts.saveForecastMonthPlan(monthPlan);

  Future<bool> updateMonthPlanWeeks(
          String monthKey, List<ForecastWeek> weeks) =>
      _forecasts.updateMonthPlanWeeks(monthKey, weeks);

  Future<bool> closeMonthPlan(String monthKey, String closedBy) =>
      _forecasts.closeMonthPlan(monthKey, closedBy);

  Future<bool> createMonthPlan({
    required String monthKey,
    required int year,
    required int month,
    required String monthStart,
    required String monthEnd,
    required List<ForecastWeek> weeks,
    required String createdBy,
  }) =>
      _forecasts.createMonthPlan(
        monthKey: monthKey,
        year: year,
        month: month,
        monthStart: monthStart,
        monthEnd: monthEnd,
        weeks: weeks,
        createdBy: createdBy,
      );

  List<ForecastWeek> generateCustomWeeks({
    required DateTime monthStart,
    required DateTime monthEnd,
    required int weekStartWeekday,
  }) =>
      ForecastRepository.generateCustomWeeks(
        monthStart: monthStart,
        monthEnd: monthEnd,
        weekStartWeekday: weekStartWeekday,
      );

  // ===================== سجلات التدقيق (Audit Logs) =====================
  Future<List<AuditLog>> fetchAuditLogs(
      {String? userName, AuditActionType? action, String? invoiceId}) {
    return _analyticsRepo.fetchAuditLogs(
        userName: userName, action: action, invoiceId: invoiceId);
  }

  // ===================== أداء المندوبين (Rep Performance) =====================
  Future<List<RepPerformance>> fetchRepPerformance(
      {String? branchName, int? month, int? year}) {
    return _analyticsRepo.fetchRepPerformance(
        branchName: branchName, month: month, year: year);
  }

  // ===================== تحليلات العملاء (Customer Analytics) =====================
  Future<List<CustomerAnalytics>> fetchCustomerAnalytics(
      {String? branchName, String? repName, String? tier}) {
    return _analyticsRepo.fetchCustomerAnalytics(
        branchName: branchName, repName: repName, tier: tier);
  }

  // ===================== إعدادات Cloudinary =====================
  Future<CloudinaryConfig?> fetchCloudinaryConfig() =>
      _analyticsRepo.fetchCloudinaryConfig();

  // ===================== المصروفات (Expenses) =====================
  Future<List<Expense>> fetchExpenses({
    String? branchName,
    String? repName,
    DateTime? startDate,
    DateTime? endDateExclusive,
  }) {
    return _expenses.fetchExpenses(
        branchName: branchName,
        repName: repName,
        startDate: startDate,
        endDateExclusive: endDateExclusive);
  }

  Future<double> sumExpenses({
    String? branchName,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _expenses.sumExpenses(
        branchName: branchName, startDate: startDate, endDate: endDate);
  }

  // ===================== إدارة الموظفين (Employee Management) =====================
  Future<List<AppUser>> fetchUsers({String? branchName, String? role}) async {
    try {
      var query = client.from('app_users').select();
      if (branchName != null && branchName.isNotEmpty) {
        query = query.eq('branch_name', branchName);
      }
      if (role != null && role.isNotEmpty) {
        query = query.eq('role', role);
      }
      final data = await query.order('name', ascending: true);
      return (data as List<dynamic>)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SupabaseService Error in fetchUsers: $e');
      return [];
    }
  }

  Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      await client
          .from('app_users')
          .update({'is_active': isActive}).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('SupabaseService Error in updateUserStatus: $e');
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      await client.from('app_users').update({'role': newRole}).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('SupabaseService Error in updateUserRole: $e');
      return false;
    }
  }

  Future<bool> updateUserBranch(String userId, String branchName) async {
    try {
      await client
          .from('app_users')
          .update({'branch_name': branchName}).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('SupabaseService Error in updateUserBranch: $e');
      return false;
    }
  }

  Future<bool> updateUserSupervisor(String userId, String? supervisorId) async {
    try {
      await client
          .from('app_users')
          .update({'supervisor_id': supervisorId}).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('SupabaseService Error in updateUserSupervisor: $e');
      return false;
    }
  }

  Future<bool> createUser(
    String name,
    String username,
    String password,
    String role,
    String branchName,
    String phone,
    String? email,
    String? supervisorName,
  ) async {
    try {
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
      await client.from('app_users').insert({
        'name': name,
        'username': username,
        'password_hash': hashedPassword,
        'role': role,
        'branch_name': branchName,
        'phone': phone,
        'email': email,
        'supervisor_name': supervisorName,
        'is_active': true,
        'approval_status': 'approved',
      });
      return true;
    } catch (e) {
      debugPrint('SupabaseService Error in createUser: $e');
      return false;
    }
  }

  Future<bool> updateUserPassword(String userId, String newPassword) async {
    try {
      await client.rpc('update_user_password', params: {
        'p_user_id': userId,
        'p_new_password': newPassword,
      });
      return true;
    } catch (e) {
      debugPrint('SupabaseService Error in updateUserPassword: $e');
      return false;
    }
  }
}
