import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';

/// نموذج بيانات إحصائيات المنطقة للزيارات
class RegionVisitStats {
  final String regionName;
  final int totalCustomers;
  final int visitedCustomers;
  final int remainingCustomers;
  final double coveragePercentage;

  RegionVisitStats({
    required this.regionName,
    required this.totalCustomers,
    required this.visitedCustomers,
    required this.remainingCustomers,
    required this.coveragePercentage,
  });
}

/// نموذج بيانات إحصائيات KPI للزيارات
class VisitKPIs {
  final int totalToday;
  final int successfulVisits;
  final int unsuccessfulVisits;
  final double coveragePercentage;
  final double totalCollected;
  final int totalReturns;

  VisitKPIs({
    required this.totalToday,
    required this.successfulVisits,
    required this.unsuccessfulVisits,
    required this.coveragePercentage,
    required this.totalCollected,
    required this.totalReturns,
  });
}

/// شاشة الزيارات الميدانية المحسّنة - تحويل Dialog منبثق إلى شاشة كاملة
/// مع داشبورد رقمي وتحليلات منطقة وربطها بقاعدة العملاء
class VisitsDashboardScreen extends StatefulWidget {
  final AppUser currentUser;
  final Customer? preselectedCustomer;

  const VisitsDashboardScreen({
    super.key,
    required this.currentUser,
    this.preselectedCustomer,
  });

  @override
  State<VisitsDashboardScreen> createState() => _VisitsDashboardScreenState();
}

class _VisitsDashboardScreenState extends State<VisitsDashboardScreen> {
  List<CustomerVisit> _visits = [];
  List<Customer> _customers = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;
  bool _isLoadingCustomers = true;
  bool _isLoadingProducts = false;
  bool _isOffline = false;
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;
  String? _selectedRegionFilter;
  String? _selectedOutcomeFilter;

  // لتتبع حالة فتح نموذج التسجيل
  bool _showVisitForm = false;
  Customer? _formCustomer;
  String? _formReason;

  static const String _cacheKey = 'visits_cache';

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _fetchVisits();
    _fetchCustomers();
    _fetchAllProducts();
    if (widget.preselectedCustomer != null) {
      _openVisitFormForCustomer(widget.preselectedCustomer!);
    }
  }

  void _openVisitFormForCustomer(Customer customer) {
    setState(() {
      _showVisitForm = true;
      _formCustomer = customer;
    });
  }

  Future<void> _fetchAllProducts() async {
    if (_allProducts.isNotEmpty) return;
    setState(() => _isLoadingProducts = true);
    try {
      final data = await SupabaseService.instance.fetchProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = data;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _fetchVisits() async {
    setState(() => _isLoading = true);
    List<CustomerVisit> data;
    try {
      data = await SupabaseService.instance.fetchVisits(
        repName: rbac.isSalesRep ? widget.currentUser.name : null,
        branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
        date: _selectedDate,
        startDate: _selectedDateRange?.start,
        endDateExclusive: _selectedDateRange?.end.add(const Duration(days: 1)),
      );
    } catch (e) {
      final cached = await _loadCache();
      if (!mounted) return;
      setState(() {
        _isOffline = true;
        _visits = rbac.filterVisits(_filterCachedVisits(cached)).toList();
        _isLoading = false;
      });
      if (_visits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل الزيارات: $e')),
        );
      }
      return;
    }

    _visits = rbac.filterVisits(data);
    if (mounted) {
      setState(() {
        _isOffline = false;
        _isLoading = false;
      });
    }
    if (_selectedDate == null && _selectedDateRange == null) {
      try {
        await _saveCache(data);
      } catch (e) {
        debugPrint('تعذر تحديث ذاكرة الزيارات المؤقتة: $e');
      }
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      final data = await SupabaseService.instance.fetchCustomers(
        repName: rbac.isSalesRep ? widget.currentUser.name : null,
        repId: rbac.isSalesRep ? widget.currentUser.id : null,
        branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
      );
      if (!mounted) return;
      setState(() {
        _customers = rbac.filterCustomerAccounts(data);
        _isLoadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل قائمة العملاء: $e')),
      );
    }
  }

  List<CustomerVisit> _filterCachedVisits(List<CustomerVisit> visits) {
    if (_selectedDate == null && _selectedDateRange == null) return visits;
    return visits.where((visit) {
      if (_selectedDate != null) {
        return visit.date.year == _selectedDate!.year &&
            visit.date.month == _selectedDate!.month &&
            visit.date.day == _selectedDate!.day;
      }
      if (_selectedDateRange != null) {
        return visit.date.isAtSameMomentAs(_selectedDateRange!.start) ||
            visit.date.isAfter(_selectedDateRange!.start) &&
                visit.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  Future<void> _saveCache(List<CustomerVisit> visits) async {
    final prefs = await SharedPreferences.getInstance();
    final json = visits.map((visit) => jsonEncode(visit.toJson())).toList();
    await prefs.setStringList(_cacheKey, json);
  }

  Future<List<CustomerVisit>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_cacheKey);
      if (cached == null || cached.isEmpty) return [];
      return cached
          .map((json) => CustomerVisit.fromJson(
                jsonDecode(json) as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      debugPrint('تعذر قراءة ذاكرة الزيارات المؤقتة: $e');
      return [];
    }
  }

  List<Product> _searchProducts(String query) {
    if (query.trim().isEmpty) return _allProducts.take(30).toList();
    final q = query.toLowerCase().trim();
    return _allProducts.where((p) {
      final name = p.name.toLowerCase();
      final code = p.code.toLowerCase();
      final barcode = (p.barcode ?? '').toLowerCase();
      return name.contains(q) || code.contains(q) || barcode.contains(q);
    }).take(40).toList();
  }

  // ===================== KPI Dashboard Calculations =====================
  VisitKPIs _calculateKPIs() {
    final today = DateTime.now();
    final todayVisits = _visits.where((v) =>
        v.date.year == today.year &&
        v.date.month == today.month &&
        v.date.day == today.day).toList();

    final totalToday = todayVisits.length;

    final successfulOutcomes = [
      'تم عمل طلبية',
      'تم التحصيل',
      'تحصيل فقط',
      'ناجحة',
    ];

    final unsuccessfulOutcomes = [
      'متابعة لاحقة',
      'لم يتم مقابلة العميل',
      'المحل مغلق',
      'رفض العرض',
      'غير ناجحة',
      'رفض',
    ];

    final successfulVisits = todayVisits.where((v) =>
        successfulOutcomes.contains(v.outcome.trim())).length;
    final unsuccessfulVisits = todayVisits.where((v) =>
        unsuccessfulOutcomes.contains(v.outcome.trim())).length;

    // حساب تغطية المنطقة بناءً على العملاء للمنطقة
    final totalCustomersInRegion = _customers.length;
    final visitedCustomers = todayVisits.length;
    final coverage = totalCustomersInRegion > 0
        ? ((visitedCustomers / totalCustomersInRegion) * 100).clamp(0, 100)
        : 0.0;

    final totalCollected = todayVisits.fold(0.0, (sum, v) => sum + v.collectedAmount);
    final totalReturns = todayVisits.where((v) => v.isReturn == true).length;

    return VisitKPIs(
      totalToday: totalToday,
      successfulVisits: successfulVisits,
      unsuccessfulVisits: unsuccessfulVisits,
      coveragePercentage: coverage.toDouble(),
      totalCollected: totalCollected,
      totalReturns: totalReturns,
    );
  }

  List<RegionVisitStats> _calculateRegionStats() {
    final today = DateTime.now();
    final todayVisits = _visits.where((v) =>
        v.date.year == today.year &&
        v.date.month == today.month &&
        v.date.day == today.day).toList();

    final regionMap = <String, List<Customer>>{};
    for (final customer in _customers) {
      final region = customer.region ?? customer.governorate ?? 'غير محدد';
      regionMap.putIfAbsent(region, () => []).add(customer);
    }

    final visitedCustomersByRegion = <String, Set<String>>{};
    for (final visit in todayVisits) {
      final customer = _customers.firstWhere(
        (c) => c.id == visit.customerId || c.code == visit.customerCode,
        orElse: () => Customer(
          id: visit.customerId,
          code: visit.customerCode ?? '',
          name: visit.customerName,
          storeName: visit.customerName,
          phone: '',
          branchName: visit.branchName ?? '',
          currentBalance: 0,
          creditLimit: 0,
          overdueBalance: 0,
          tier: 'عادي',
        ),
      );
      final region = customer.region ?? customer.governorate ?? 'غير محدد';
      visitedCustomersByRegion.putIfAbsent(region, () => {}).add(visit.customerId);
    }

    final stats = regionMap.entries.map((entry) {
      final region = entry.key;
      final customers = entry.value;
      final visited = visitedCustomersByRegion[region]?.length ?? 0;
      final remaining = customers.length - visited;
      final coverage = customers.isNotEmpty
          ? ((visited / customers.length) * 100).clamp(0, 100)
          : 0.0;
      return RegionVisitStats(
        regionName: region,
        totalCustomers: customers.length,
        visitedCustomers: visited,
        remainingCustomers: remaining > 0 ? remaining : 0,
        coveragePercentage: coverage.toDouble(),
      );
    }).toList();

    stats.sort((a, b) => b.coveragePercentage.compareTo(a.coveragePercentage));
    return stats;
  }

  // ===================== Visit Form =====================
  Future<void> _showNewVisitForm({Customer? customer}) async {
    setState(() {
      _showVisitForm = true;
      _formCustomer = customer ?? widget.preselectedCustomer;
    });
  }

  void _closeVisitForm() {
    setState(() {
      _showVisitForm = false;
      _formCustomer = null;
      _formReason = null;
    });
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
      helpText: 'اختر نطاق التواريخ للزيارات',
    );
    if (picked == null) return;
    setState(() {
      _selectedDateRange = picked;
      _selectedDate = null;
    });
    await _fetchVisits();
  }

  Future<void> _clearDateRange() async {
    setState(() {
      _selectedDateRange = null;
      _selectedDate = null;
    });
    await _fetchVisits();
  }

  List<CustomerVisit> _getFilteredVisits() {
    var filtered = List<CustomerVisit>.from(_visits);
    if (_selectedRegionFilter != null && _selectedRegionFilter!.isNotEmpty) {
      filtered = filtered.where((v) {
        final customer = _customers.firstWhere(
          (c) => c.id == v.customerId || c.code == v.customerCode,
          orElse: () => Customer(
            id: v.customerId,
            code: v.customerCode ?? '',
            name: v.customerName,
            storeName: v.customerName,
            phone: '',
            branchName: v.branchName ?? '',
            currentBalance: 0,
            creditLimit: 0,
            overdueBalance: 0,
            tier: 'عادي',
          ),
        );
        final region = customer.region ?? customer.governorate ?? '';
        return region == _selectedRegionFilter;
      }).toList();
    }
    if (_selectedOutcomeFilter != null && _selectedOutcomeFilter!.isNotEmpty) {
      filtered = filtered.where((v) => v.outcome.contains(_selectedOutcomeFilter!)).toList();
    }
    return filtered;
  }

  List<String> _getUniqueRegions() {
    final regions = _customers.map((c) => c.region ?? c.governorate ?? '').toSet();
    regions.remove('');
    return regions.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final kpis = _calculateKPIs();
    final regionStats = _calculateRegionStats();
    final filteredVisits = _getFilteredVisits();
    final uniqueRegions = _getUniqueRegions();

    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text(
          'سجل الزيارات الميدانية',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        actions: [
          if (_isOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.wifi_off_rounded, color: Colors.orange),
            ),
          if (_selectedDate != null || _selectedDateRange != null)
            IconButton(
              tooltip: 'إلغاء فلتر التاريخ',
              icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.white70),
              onPressed: _clearDateRange,
            ),
          IconButton(
            tooltip: 'فلترة حسب التاريخ',
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
            onPressed: _showDateRangePicker,
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none, color: Colors.white70),
                if (NotificationService.unreadVisitNotificationCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: _buildNotificationBadge(),
                  ),
              ],
            ),
            tooltip: 'الإشعارات',
            onPressed: _showNotificationsPanel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchVisits,
          ),
        ],
      ),
      floatingActionButton: _showVisitForm
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.darkSlate,
              icon: const Icon(Icons.add_rounded),
              label: Text('عمل زيارة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              onPressed: _selectedDate == null && _selectedDateRange == null
                  ? () => _showNewVisitForm()
                  : _showNewVisitForm,
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _showVisitForm
              ? _buildVisitForm(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    await _fetchVisits();
                    await _fetchCustomers();
                  },
                  child: _buildDashboard(
                      context, kpis, regionStats, filteredVisits, uniqueRegions),
                ),
    );
  }

  Widget _buildNotificationBadge() {
    final unreadCount = NotificationService.unreadVisitNotificationCount;
    if (unreadCount == 0) return const SizedBox.shrink();
    return Badge(
      backgroundColor: AppTheme.roseRed,
      label: Text('$unreadCount',
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 10)),
    );
  }

  void _showNotificationsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSlate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الإشعارات',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white)),
                if (NotificationService.unreadVisitNotificationCount > 0)
                  TextButton(
                    onPressed: () {
                      NotificationService.markAllVisitNotificationsAsRead();
                      setState(() {});
                    },
                    child: Text('تحديد الكل كمقروء',
                        style: GoogleFonts.cairo(
                            color: AppTheme.infoBlue, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(color: AppTheme.darkBorder),
          Flexible(
            child: NotificationService.visitNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('لا توجد إشعارات',
                            style: GoogleFonts.cairo(
                                color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount:
                        NotificationService.visitNotifications.length,
                    itemBuilder: (context, index) {
                      final notification =
                          NotificationService.visitNotifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(VisitNotification notification) {
    final typeColor = _notificationTypeColor(notification.type);
    return Card(
      color: notification.isRead
          ? AppTheme.cardSlate.withValues(alpha: 0.5)
          : AppTheme.cardSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? AppTheme.darkBorder
              : typeColor.withValues(alpha: 0.3),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_notificationTypeIcon(notification.type),
              color: typeColor, size: 20),
        ),
        title: Text(notification.title,
            style: GoogleFonts.cairo(
                fontWeight: notification.isRead
                    ? FontWeight.normal
                    : FontWeight.bold,
                fontSize: 13,
                color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body,
                style: GoogleFonts.cairo(
                    fontSize: 11, color: Colors.grey.shade400)),
            Text(
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(notification.timestamp),
                style: GoogleFonts.cairo(
                    fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
        trailing: notification.isRead
            ? null
            : const Icon(Icons.campaign_outlined,
                color: AppTheme.primaryGold, size: 12),
        onTap: () {
          setState(() {
            notification.isRead = true;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Color _notificationTypeColor(VisitNotificationType type) {
    switch (type) {
      case VisitNotificationType.registration:
        return AppTheme.infoBlue;
      case VisitNotificationType.unsuccessful:
        return AppTheme.warningAmber;
      case VisitNotificationType.lowCoverage:
        return AppTheme.roseRed;
      case VisitNotificationType.supervisorAssignment:
        return AppTheme.emeraldGreen;
    }
  }

  IconData _notificationTypeIcon(VisitNotificationType type) {
    switch (type) {
      case VisitNotificationType.registration:
        return Icons.location_on_outlined;
      case VisitNotificationType.unsuccessful:
        return Icons.warning_rounded;
      case VisitNotificationType.lowCoverage:
        return Icons.error_outline;
      case VisitNotificationType.supervisorAssignment:
        return Icons.assignment_ind_outlined;
    }
  }

  Widget _buildDashboard(
    BuildContext context,
    VisitKPIs kpis,
    List<RegionVisitStats> regionStats,
    List<CustomerVisit> filteredVisits,
    List<String> uniqueRegions,
  ) {
    return SingleChildScrollView(
      padding: ResponsiveBreakpoints.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ملخص الإحصائيات العلوي (Summary Cards - KPI)
          _buildKPISummary(kpis),
          const SizedBox(height: 24),

          // 2. توزيع الزيارات حسب المنطقة
          Text('تحليل الزيارات حسب المنطقة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 12),
          _buildRegionStatsTable(regionStats, uniqueRegions),
          const SizedBox(height: 24),

          // 3. جدول سجل الزيارات السابقة
          Text('سجل الزيارات',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
          const SizedBox(height: 12),
          _buildVisitsTable(filteredVisits),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKPISummary(VisitKPIs kpis) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final gridColumns = isDesktop ? 5 : (ResponsiveBreakpoints.isTablet(context) ? 3 : 2);

    return GridView.count(
      crossAxisCount: gridColumns,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildKPICard(
          context,
          title: 'زيارات اليوم',
          value: '${kpis.totalToday}',
          icon: Icons.location_on_outlined,
          color: AppTheme.infoBlue,
          subtitle: '${kpis.successfulVisits} ناجحة • ${kpis.unsuccessfulVisits} غير ناجحة',
        ),
        _buildKPICard(
          context,
          title: 'نسبة التغطية',
          value: '${kpis.coveragePercentage.toStringAsFixed(1)}%',
          icon: Icons.visibility_outlined,
          color: AppTheme.primaryGold,
          showProgress: true,
          progressValue: kpis.coveragePercentage / 100,
        ),
        _buildKPICard(
          context,
          title: 'إجمالي التحصيل',
          value: '${kpis.totalCollected.toStringAsFixed(0)} ج.م',
          icon: Icons.payments_outlined,
          color: AppTheme.emeraldGreen,
        ),
        _buildKPICard(
          context,
          title: 'المرتجعات',
          value: '${kpis.totalReturns}',
          icon: Icons.undo_outlined,
          color: AppTheme.roseRed,
        ),
        if (isDesktop)
          _buildKPICard(
            context,
            title: 'معدل النجاح',
            value: kpis.totalToday > 0
                ? '${((kpis.successfulVisits / kpis.totalToday) * 100).toStringAsFixed(0)}%'
                : '—',
            icon: Icons.trending_up_outlined,
            color: AppTheme.infoBlue,
          ),
      ],
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    bool showProgress = false,
    double progressValue = 0.0,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: AppTheme.cardSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.darkBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (showProgress)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progressValue,
                      backgroundColor: AppTheme.darkBorder,
                      color: color,
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 20, color: colorScheme.onSurface)),
            Text(title,
                style: GoogleFonts.cairo(fontSize: 11, color: colorScheme.onSurfaceVariant)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.cairo(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegionStatsTable(List<RegionVisitStats> stats, List<String> regions) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (regions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('الكل', style: TextStyle(color: Colors.white70)),
                selected: _selectedRegionFilter == null,
                onSelected: (_) => setState(() => _selectedRegionFilter = null),
                backgroundColor: AppTheme.darkBorder,
                selectedColor: AppTheme.primaryGold.withValues(alpha: 0.3),
                showCheckmark: false,
              ),
              ...regions.map((region) => ChoiceChip(
                    label: Text(region,
                        style: TextStyle(
                            color: _selectedRegionFilter == region ? AppTheme.darkSlate : Colors.white70,
                            fontSize: 11)),
                    selected: _selectedRegionFilter == region,
                    onSelected: (_) => setState(() => _selectedRegionFilter =
                        _selectedRegionFilter == region ? null : region),
                    backgroundColor: AppTheme.darkBorder,
                    selectedColor: AppTheme.primaryGold,
                    showCheckmark: false,
                  )),
            ],
          ),
        const SizedBox(height: 12),
        Container(
             decoration: BoxDecoration(
              color: AppTheme.cardSlate,
              borderRadius: BorderRadius.circular(12),
               border: const Border.all(color: AppTheme.darkBorder),
            ),
            child: stats.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('لا توجد بيانات مناطق',
                      style: GoogleFonts.cairo(color: Colors.grey.shade400)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text('توزيع الزيارات حسب المنطقة',
                          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
                    ),
                    DataTable(
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(AppTheme.darkBorder.withValues(alpha: 0.5)),
                  columns: [
                    DataColumn(
                        label: Text('المنطقة',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11))),
                    DataColumn(
                        label: Text('العملاء',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11))),
                    DataColumn(
                        label: Text('تمت الزيارة',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11))),
                    DataColumn(
                        label: Text('المتبقي',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11))),
                    DataColumn(
                        label: Text('التغطية',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11))),
                    DataColumn(
                        label: Text('', style: GoogleFonts.cairo(color: Colors.transparent, fontSize: 11)),
                    ),
                  ],
                  rows: stats.asMap().entries.map((entry) {
                    final s = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(s.regionName,
                          style: GoogleFonts.cairo(color: colorScheme.onSurface, fontSize: 12))),
                      DataCell(Text('${s.totalCustomers}',
                          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12))),
                      DataCell(Text('${s.visitedCustomers}',
                          style: GoogleFonts.cairo(color: AppTheme.emeraldGreen, fontSize: 12))),
                      DataCell(Text('${s.remainingCustomers}',
                          style: GoogleFonts.cairo(color: s.remainingCustomers > 0 ? Colors.orange : Colors.white70, fontSize: 12))),
                      DataCell(
                        Stack(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 14,
                              child: LinearProgressIndicator(
                                value: s.coveragePercentage / 100,
                                backgroundColor: AppTheme.darkBorder,
                                color: _coverageColor(s.coveragePercentage),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Text(
                              '${s.coveragePercentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 9, height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedRegionFilter = s.regionName;
                            });
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 14, color: AppTheme.primaryGold),
                          label: Text('زيارة',
                              style: GoogleFonts.cairo(color: AppTheme.primaryGold, fontSize: 10)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _coverageColor(double percentage) {
    if (percentage >= 75) return AppTheme.emeraldGreen;
    if (percentage >= 50) return AppTheme.primaryGold;
    return AppTheme.roseRed;
  }

  Widget _buildVisitsTable(List<CustomerVisit> visits) {
    if (visits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardSlate,
          borderRadius: BorderRadius.circular(12),
          border: const Border.all(color: AppTheme.darkBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.location_on_outlined, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 12),
              Text('لا توجد زيارات مسجلة',
                  style: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // فلاتر النتيجة
    final outcomeFilters = [
      'الكل',
      'تم عمل طلبية',
      'تم التحصيل',
      'متابعة لاحقة',
      'لم يتم مقابلة العميل',
      'المحل مغلق',
      'رفض العرض',
      'تم تسجيل مرتجع',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: outcomeFilters.map((filter) => ChoiceChip(
                label: Text(filter,
                    style: TextStyle(
                        color: _selectedOutcomeFilter == (filter == 'الكل' ? null : filter)
                            ? AppTheme.darkSlate
                            : Colors.white70,
                        fontSize: 11)),
                selected: _selectedOutcomeFilter == (filter == 'الكل' ? null : filter),
                onSelected: (_) => setState(() =>
                    _selectedOutcomeFilter = filter == 'الكل' ? null : filter),
                backgroundColor: AppTheme.darkBorder,
                selectedColor: AppTheme.primaryGold,
                showCheckmark: false,
              )).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardSlate,
            borderRadius: BorderRadius.circular(12),
          border: const Border.all(color: AppTheme.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('سجل الزيارات',
                      style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
                  const Spacer(),
                  if (_selectedOutcomeFilter != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _selectedOutcomeFilter = null),
                      icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                      label: Text('إلغاء فلتر', style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              PaginatedDataTable(
                columnSpacing: 16,
                horizontalMargin: 16,
                headingRowColor: WidgetStateProperty.all(AppTheme.darkBorder.withValues(alpha: 0.5)),
                rowsPerPage: 10,
                columns: const [
                  DataColumn(label: Text('العميل', style: TextStyle(color: Colors.white70, fontSize: 11))),
                  DataColumn(label: Text('المنطقة', style: TextStyle(color: Colors.white70, fontSize: 11))),
                  DataColumn(label: Text('الوقت', style: TextStyle(color: Colors.white70, fontSize: 11))),
                  DataColumn(label: Text('النتيجة', style: TextStyle(color: Colors.white70, fontSize: 11))),
                  DataColumn(label: Text('المبلغ', style: TextStyle(color: Colors.white70, fontSize: 11))),
                ],
                source: VisitDataTableSource(visits, _customers, context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== نموذج تسجيل الزيارة =====================
  Widget _buildVisitForm(BuildContext context) {
    return Padding(
      padding: ResponsiveBreakpoints.screenPadding(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // زر الإغلاق والعودة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _closeVisitForm,
                  icon: const Icon(Icons.close, color: Colors.white70),
                  label: Text('إلغاء الزيارة', style: GoogleFonts.cairo(color: Colors.white70)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // بطاقة العميل المحدد
            if (_formCustomer != null) ...[
              _buildSelectedCustomerCard(_formCustomer!),
              const SizedBox(height: 20),
            ],

            // نموذج تسجيل الزيارة
            _buildVisitFormFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCustomerCard(Customer customer) {
    final region = customer.region ?? customer.governorate ?? 'غير محدد';
    final tier = customer.tier;
    final balance = customer.currentBalance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGold.withValues(alpha: 0.1),
            AppTheme.primaryGold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: const BorderSide(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined, color: AppTheme.primaryGold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    Text('${customer.code} • ${customer.branchName}',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _tierColor(tier).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(tier,
                    style: GoogleFonts.cairo(fontSize: 10, color: _tierColor(tier))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildCustomerInfoChip(Icons.location_on_outlined, 'المنطقة', region, AppTheme.infoBlue),
              _buildCustomerInfoChip(Icons.account_balance_wallet_outlined, 'الرصيد',
                  '${balance.toStringAsFixed(0)} ج.م', balance > 0 ? AppTheme.roseRed : AppTheme.emeraldGreen),
              _buildCustomerInfoChip(Icons.star_outline, 'المستوى', tier, _tierColor(tier)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoChip(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text('$label: ', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade400)),
        Text(value, style: GoogleFonts.cairo(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _tierColor(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'ذهبي':
        return AppTheme.goldAccent;
      case 'فضي':
        return const Color(0xFF94A3B8);
      case 'برونزي':
        return AppTheme.copper;
      default:
        return AppTheme.silver;
    }
  }

  String _visitOutcome = 'تم عمل طلبية';
  String _visitType = 'زيارة بيع وطلبية';
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  final _visitReasonController = TextEditingController();
  List<Map<String, dynamic>> _returnItemsList = [];
  final List<String> _unsuccessfulReasons = [
    'السعر مرتفع',
    'البضاعة متوفرة عند المنافس',
    'المحل مغلق',
    'العميل مسافر',
    'رفض العرض',
    'عدم اهتمام',
    'أخرى',
  ];
  String? _selectedUnsuccessfulReason;

  Widget _buildVisitFormFields() {
    final showReasonField = !_isSuccessfulOutcome(_visitOutcome);

    return Card(
      color: AppTheme.cardSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اختيار العميل
            if (_formCustomer == null) ...[
              Text('اختر العميل',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 8),
              _buildCustomerDropdown(),
              const SizedBox(height: 16),
            ],

            // غرض الزيارة
            Text('غرض الزيارة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 8),
            _buildVisitTypeSelector(),
            const SizedBox(height: 20),

            // نتيجة الزيارة
            Text('نتيجة الزيارة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 8),
            _buildOutcomeSelector(),
            const SizedBox(height: 20),

            // سبب عدم النجاح (يظهر فقط عند النتائج غير الناجحة)
            if (showReasonField) ...[
              Text('سبب عدم البيع',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 8),
              _buildUnsuccessfulReasonSelector(),
              const SizedBox(height: 20),
            ],

            // المبلغ المحصل (يظهر للزيارات الناجحة فقط)
            if (!_isReturnOutcome(_visitOutcome)) ...[
              Text('المبلغ المحصل (ج.م)',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.cairo(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل المبلغ إن وجد',
                  hintStyle: GoogleFonts.cairo(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: AppTheme.darkSlate,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.darkBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryGold)),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ملاحظات
            Text('ملاحظات إضافية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: GoogleFonts.cairo(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'أدخل ملاحظات إضافية...',
                hintStyle: GoogleFonts.cairo(color: Colors.grey.shade500),
                filled: true,
                fillColor: AppTheme.darkSlate,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.darkBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryGold)),
              ),
            ),
            const SizedBox(height: 24),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: AppTheme.darkSlate,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.save_outlined),
                label: Text('حفظ الزيارة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _saveVisit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return DropdownButtonFormField<Customer>(
      initialValue: _formCustomer,
      isExpanded: true,
      dropdownColor: AppTheme.cardSlate,
      style: GoogleFonts.cairo(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'اختر العميل',
        hintStyle: GoogleFonts.cairo(color: Colors.grey.shade500),
        filled: true,
        fillColor: AppTheme.darkSlate,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryGold),
        ),
      ),
      items: _customers.map((customer) {
        final region = customer.region ?? customer.governorate ?? 'غير محدد';
        return DropdownMenuItem(
          value: customer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${customer.name} • ${customer.code}',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
              Text(region, style: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 10)),
            ],
          ),
        );
      }).toList(),
      onChanged: (customer) => setState(() => _formCustomer = customer),
    );
  }

  Widget _buildVisitTypeSelector() {
    final types = ['زيارة بيع وطلبية', 'زيارة تحصيل رصيد', 'زيارة دورية ومتابعة'];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: types.map((type) => ChoiceChip(
            label: Text(type,
                style: TextStyle(
                    color: _visitType == type ? AppTheme.darkSlate : Colors.white70, fontSize: 11)),
            selected: _visitType == type,
            onSelected: (_) => setState(() => _visitType = type),
            backgroundColor: AppTheme.darkBorder,
            selectedColor: AppTheme.primaryGold,
            showCheckmark: false,
          )).toList(),
    );
  }

  Widget _buildOutcomeSelector() {
    final outcomes = [
      'تم عمل طلبية',
      'تم التحصيل',
      'تم تسجيل مرتجع',
      'متابعة لاحقة',
      'لم يتم مقابلة العميل',
      'المحل مغلق',
      'رفض العرض',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: outcomes.map((outcome) {
        final color = _outcomeColor(outcome);
        return ChoiceChip(
          label: Text(outcome,
              style: TextStyle(
                  color: _visitOutcome == outcome ? AppTheme.darkSlate : Colors.white70, fontSize: 11)),
          selected: _visitOutcome == outcome,
          onSelected: (_) => setState(() {
            _visitOutcome = outcome;
            _selectedUnsuccessfulReason = null;
          }),
          backgroundColor: AppTheme.darkBorder.withValues(alpha: 0.5),
          selectedColor: color.withValues(alpha: 0.5),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Color _outcomeColor(String outcome) {
    if (outcome == 'تم عمل طلبية' || outcome == 'تم التحصيل') return AppTheme.emeraldGreen;
    if (outcome == 'تم تسجيل مرتجع') return AppTheme.roseRed;
    return AppTheme.warningAmber;
  }

  Widget _buildUnsuccessfulReasonSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _unsuccessfulReasons.map((reason) => ChoiceChip(
                label: Text(reason,
                    style: TextStyle(
                        color: _selectedUnsuccessfulReason == reason ? AppTheme.darkSlate : Colors.white70,
                        fontSize: 11)),
                selected: _selectedUnsuccessfulReason == reason,
                onSelected: (_) => setState(() => _selectedUnsuccessfulReason =
                    _selectedUnsuccessfulReason == reason ? null : reason),
                backgroundColor: AppTheme.darkBorder,
                selectedColor: AppTheme.primaryGold,
                showCheckmark: false,
              )).toList(),
        ),
        const SizedBox(height: 8),
        if (_selectedUnsuccessfulReason == 'أخرى')
          TextField(
            controller: _visitReasonController,
            decoration: InputDecoration(
              hintText: 'حدد السبب هنا...',
              hintStyle: GoogleFonts.cairo(color: Colors.grey.shade500),
              filled: true,
              fillColor: AppTheme.darkSlate,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.darkBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryGold),
              ),
            ),
            style: GoogleFonts.cairo(color: Colors.white),
          ),
      ],
    );
  }

  bool _isSuccessfulOutcome(String outcome) {
    return outcome == 'تم عمل طلبية' || outcome == 'تم التحصيل';
  }

  bool _isReturnOutcome(String outcome) {
    return outcome == 'تم تسجيل مرتجع';
  }

  Future<void> _saveVisit() async {
    final customer = _formCustomer;
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل')),
      );
      return;
    }

    final now = DateTime.now();
    final collectedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final reason = _visitReasonController.text.trim();
    final notes = _notesController.text.trim();
    final isReturn = _isReturnOutcome(_visitOutcome);

    final newVisit = CustomerVisit(
      id: 'vis_${now.millisecondsSinceEpoch}',
      customerId: customer.id,
      customerCode: customer.code,
      customerName: customer.name,
      repName: widget.currentUser.name,
      repId: widget.currentUser.id,
      branchName: widget.currentUser.branchName,
      date: now,
      checkInTime: now.toIso8601String(),
      type: _visitType,
      outcome: _visitOutcome,
      status: 'executed',
      collectedAmount: isReturn ? 0.0 : collectedAmount,
      notes: reason.isNotEmpty
          ? 'السبب: ${_selectedUnsuccessfulReason ?? reason}${notes.isNotEmpty ? '\nملاحظات: $notes' : ''}'
          : notes.isNotEmpty
              ? 'ملاحظات: $notes'
              : null,
      returnReason: isReturn ? reason : (_selectedUnsuccessfulReason),
      createdBy: widget.currentUser.id,
    );

    final success = await SupabaseService.instance.logVisit(newVisit);
    if (!mounted) return;

    if (success) {
      setState(() {
        _visits.insert(0, newVisit);
      });
      final customerRegion = customer.region ?? customer.governorate;
      NotificationService.notifyVisitRegistered(
        newVisit,
        supervisorName: widget.currentUser.supervisorName,
        region: customerRegion,
      );
      if (!_isSuccessfulOutcome(_visitOutcome)) {
        NotificationService.notifyUnsuccessfulVisit(
          newVisit,
          supervisorName: widget.currentUser.supervisorName,
          region: customerRegion,
        );
      }
      _checkAndNotifyLowCoverage();
      _closeVisitForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الزيارة بنجاح')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم حفظ الزيارة')),
      );
    }
  }

  void _checkAndNotifyLowCoverage() {
    final kpis = _calculateKPIs();
    if (kpis.coveragePercentage < 50) {
      final regions = _calculateRegionStats();
      for (final region in regions) {
        if (region.coveragePercentage < 50) {
          NotificationService.notifyLowCoverageWarning(
            region.regionName,
            region.coveragePercentage,
            supervisorName: widget.currentUser.supervisorName,
          );
        }
      }
    }
  }

  Future<void> _showDateFilterDialog() async {
    bool dateSelected = _selectedDate != null;
    bool rangeSelected = _selectedDateRange != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardSlate,
        title: Text('فلترة حسب التاريخ',
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked == null) return;
                setState(() {
                  _selectedDate = picked;
                  _selectedDateRange = null;
                });
                Navigator.pop(context);
                await _fetchVisits();
              },
              icon: const Icon(Icons.calendar_today_outlined, color: AppTheme.primaryGold),
              label: Text('تحديد تاريخ محدد', style: GoogleFonts.cairo(color: Colors.white)),
            ),
            TextButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  initialDateRange: _selectedDateRange,
                );
                if (picked == null) return;
                setState(() {
                  _selectedDateRange = picked;
                  _selectedDate = null;
                });
                Navigator.pop(context);
                await _fetchVisits();
              },
              icon: const Icon(Icons.date_range_outlined, color: AppTheme.primaryGold),
              label: Text('تحديد نطاق تواريخ', style: GoogleFonts.cairo(color: Colors.white)),
            ),
            if (_selectedDate != null || _selectedDateRange != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                    _selectedDateRange = null;
                  });
                  Navigator.pop(context);
                  _fetchVisits();
                },
                icon: const Icon(Icons.clear, color: AppTheme.roseRed),
                label: Text('إلغاء التصفية', style: GoogleFonts.cairo(color: AppTheme.roseRed)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Data source لجدول الزيارات
class VisitDataTableSource extends DataTableSource {
  final List<CustomerVisit> visits;
  final List<Customer> customers;
  final BuildContext context;

  VisitDataTableSource(this.visits, this.customers, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= visits.length) return null;
    final v = visits[index];
    final customer = customers.firstWhere(
      (c) => c.id == v.customerId || c.code == v.customerCode,
      orElse: () => Customer(
        id: v.customerId,
        code: v.customerCode ?? '',
        name: v.customerName,
        storeName: v.customerName,
        phone: '',
        branchName: v.branchName ?? '',
        currentBalance: 0,
        creditLimit: 0,
        overdueBalance: 0,
        tier: 'عادي',
      ),
    );

    final region = customer.region ?? customer.governorate ?? '-';
    final time = DateFormat('HH:mm\ndd/MM').format(v.date);
    final outcomeColor = _visitOutcomeColor(v.outcome);
    final isReturn = v.isReturn == true;

    return DataRow(cells: [
      DataCell(
        Row(
          children: [
            if (isReturn) const Icon(Icons.undo_outlined, color: Colors.red, size: 14),
            if (isReturn) const SizedBox(width: 4),
            Text(v.customerName, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      DataCell(Text(region, style: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 11))),
      DataCell(Text(time, style: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 11))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: outcomeColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(v.outcome,
            style: GoogleFonts.cairo(color: outcomeColor, fontSize: 10, fontWeight: FontWeight.w600)),
      )),
      DataCell(Text(v.collectedAmount > 0 ? '${v.collectedAmount.toStringAsFixed(0)} ج.م' : '-',
          style: GoogleFonts.cairo(color: AppTheme.emeraldGreen, fontSize: 11))),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => visits.length;

  @override
  int get selectedRowCount => 0;

  Color _visitOutcomeColor(String outcome) {
    if (outcome.contains('طلبية') || outcome.contains('تحصيل') || outcome.contains('ناجح')) {
      return AppTheme.emeraldGreen;
    }
    return AppTheme.warningAmber;
  }
}


