import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/cart_service.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';

class ExecutiveAnalyticsDashboard extends StatefulWidget {
  final AppUser currentUser;
  const ExecutiveAnalyticsDashboard({super.key, required this.currentUser});

  @override
  State<ExecutiveAnalyticsDashboard> createState() =>
      _ExecutiveAnalyticsDashboardState();
}

class _ExecutiveAnalyticsDashboardState
    extends State<ExecutiveAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  List<OrderInvoice> _invoices = [];
  List<CustomerVisit> _visits = [];
  List<CustomerAnalytics> _customers = [];
  bool _isLoading = true;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideInAnimation;

  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);

  RoleAccessController get _rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _slideInAnimation =
        Tween<double>(begin: 50, end: 0).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final endDateExclusive =
        DateTime(_endDate.year, _endDate.month, _endDate.day + 1);
    try {
      final service = SupabaseService.instance;
      final branchName = _rbac.isAdmin ? null : widget.currentUser.branchName;
      final repName = _rbac.isSalesRep ? widget.currentUser.name : null;

      final results = await Future.wait([
        service.fetchInvoices(
          branchName: branchName,
          repName: repName,
          startDate: _startDate,
          endDateExclusive: endDateExclusive,
        ),
        service.fetchVisits(
          branchName: branchName,
          repName: repName,
          startDate: _startDate,
          endDateExclusive: endDateExclusive,
        ),
        if (_rbac.isAdmin || _rbac.isManagement || _rbac.isSupervisor)
          service.fetchCustomerAnalytics(
              branchName: branchName,
              repName: repName),
      ]);

      if (!mounted) return;
      setState(() {
        _invoices = results[0] as List<OrderInvoice>;
        _visits = results[1] as List<CustomerVisit>;
        _customers = _rbac.isAdmin || _rbac.isManagement || _rbac.isSupervisor
            ? (results[2] as List<CustomerAnalytics>)
            : [];
      });
      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double _totalSales(List<OrderInvoice> invoices) {
    return invoices.fold(0.0, (sum, e) => sum + e.totalAmount);
  }

  double _totalCollections(List<CustomerVisit> visits) {
    return visits.fold(0.0, (sum, v) => sum + v.collectedAmount);
  }

  double _totalReturns(List<OrderInvoice> invoices) {
    return invoices.fold(0.0, (sum, e) => sum + (e.totalRefundedAmount ?? 0));
  }

  double _totalBalances(List<OrderInvoice> invoices) {
    return invoices.fold(0.0,
        (sum, e) => sum + ((e.customerBalanceAfter ?? 0) - (e.totalAmount)));
  }

  double _totalExpenses(List<OrderInvoice> invoices) {
    return invoices.fold(0.0, (sum, e) => sum + (e.totalAmount - (e.customerBalanceAfter ?? 0) - (e.totalRefundedAmount ?? 0)));
  }

  double _collectionRate() {
    final sales = _totalSales(_invoices);
    final collections = _totalCollections(_visits);
    if (sales <= 0) return 0;
    return (collections / sales * 100).clamp(0.0, 100);
  }

  double _returnRate() {
    final sales = _totalSales(_invoices);
    final returns = _totalReturns(_invoices);
    if (sales <= 0) return 0;
    return (returns / sales * 100).clamp(0.0, 100);
  }

  double _balanceRate() {
    final sales = _totalSales(_invoices);
    final balances = _totalBalances(_invoices);
    if (sales <= 0) return 0;
    return (balances / sales * 100).clamp(0.0, 100);
  }

  Map<String, double> _salesByBranch(List<OrderInvoice> invoices) {
    final Map<String, double> result = {};
    for (final inv in invoices) {
      final branch = inv.branchName ?? 'غير محدد';
      result[branch] = (result[branch] ?? 0) + (inv.totalAmount ?? 0);
    }
    return result;
  }

  Map<String, double> _salesByCustomer(List<OrderInvoice> invoices) {
    final Map<String, double> result = {};
    for (final inv in invoices) {
      final customer = inv.customerName ?? 'غير محدد';
      result[customer] = (result[customer] ?? 0) + (inv.totalAmount ?? 0);
    }
    return result;
  }

  List<FlSpot> _dailySalesTrend(List<OrderInvoice> invoices) {
    final Map<String, double> dailyTotals = {};
    for (final inv in invoices) {
      if (inv.date != null) {
        final dayKey = DateFormat('yyyy-MM-dd').format(inv.date!);
        dailyTotals[dayKey] =
            (dailyTotals[dayKey] ?? 0) + (inv.totalAmount ?? 0);
      }
    }
    final sortedKeys = dailyTotals.keys.toList()..sort();
    return List<FlSpot>.generate(sortedKeys.length, (i) {
      return FlSpot(i.toDouble(), dailyTotals[sortedKeys[i]]!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppTheme.primaryGold,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'جاري تحميل لوحة التحليلات...',
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.roseRed, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'خطأ في تحميل البيانات',
                        style: GoogleFonts.cairo(
                            color: AppTheme.roseRed, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.cairo(color: Colors.grey.shade400),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: Text('إعادة المحاولة',
                            style: GoogleFonts.cairo()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: AppTheme.darkSlate,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop =
                            ResponsiveBreakpoints.isDesktop(context);
                        final isTablet =
                            ResponsiveBreakpoints.isTablet(context);

                        if (isDesktop || isTablet) {
                          return _buildDesktopLayout(constraints);
                        }
                        return _buildMobileLayout(constraints);
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    final salesByBranch = _salesByBranch(_invoices);

    return Padding(
      padding: ResponsiveBreakpoints.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildKpiCards(),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('اتجاه المبيعات'),
                    const SizedBox(height: 12),
                    _buildSalesTrendChart(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('أحدث العمليات'),
                    const SizedBox(height: 12),
                    _buildRecentOperationsTable(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('توزيع المبيعات'),
                    const SizedBox(height: 12),
                    _buildDoughnutChart(salesByBranch),
                    const SizedBox(height: 28),
                    _buildSummaryCards(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    final salesByBranch = _salesByBranch(_invoices);

    return Padding(
      padding: ResponsiveBreakpoints.screenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildKpiCards(),
          const SizedBox(height: 24),
          _buildSectionTitle('اتجاه المبيعات'),
          const SizedBox(height: 12),
          _buildSalesTrendChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('أحدث العمليات'),
          const SizedBox(height: 12),
          _buildRecentOperationsTable(),
          const SizedBox(height: 24),
          _buildSectionTitle('توزيع المبيعات'),
          const SizedBox(height: 12),
          _buildDoughnutChart(salesByBranch),
          const SizedBox(height: 24),
          _buildSummaryCards(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لوحة تحليلات التنفيذ',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.darkSlate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('yyyy/MM/dd').format(_startDate)} - ${DateFormat('yyyy/MM/dd').format(_endDate)}',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : AppTheme.textMuted,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildDateRangeButton(),
            const SizedBox(width: 12),
            _buildExportButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showDateRangePicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2B40) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? const Color(0xFF3A3A55) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              color: AppTheme.primaryGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'تحديد الفترة',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark ? Colors.white : AppTheme.darkSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تصدير التقرير بنجاح',
                style: GoogleFonts.cairo()),
            backgroundColor: AppTheme.emeraldGreen,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryGold, Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.file_download, color: AppTheme.darkSlate, size: 20),
            const SizedBox(width: 8),
            Text(
              'تصدير',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangePicker() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      saveroute: ThemeData.dark(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      _loadData();
    }
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : AppTheme.darkSlate,
      ),
    );
  }

  Widget _buildKpiCards() {
    final totalSales = _totalSales(_invoices);
    final totalCollections = _totalCollections(_visits);
    final totalBalances = _totalBalances(_invoices);
    final totalExpenses = _totalExpenses(_invoices);
    final collectionRate = _collectionRate();
    final returnRate = _returnRate();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final kpiData = [
      _KpiData(
        title: 'إجمالي المبيعات',
        value: _currencyFmt.format(totalSales),
        icon: Icons.currency_exchange,
        color: AppTheme.primaryGold,
        progress: 0.65,
        subtitle: '${_currencyFmt.format(totalSales)} من ${DateFormat('yyyy/MM/dd').format(_startDate)}',
      ),
      _KpiData(
        title: 'معدل التحصيل',
        value: '${collectionRate.toStringAsFixed(1)}%',
        icon: Icons.payments_outlined,
        color: AppTheme.emeraldGreen,
        progress: collectionRate / 100,
        subtitle: _currencyFmt.format(totalCollections),
      ),
      _KpiData(
        title: 'معدل المرتجعات',
        value: '${returnRate.toStringAsFixed(1)}%',
        icon: Icons.trending_down_outlined,
        color: AppTheme.roseRed,
        progress: returnRate / 100,
        subtitle: _currencyFmt.format(_totalReturns(_invoices)),
      ),
      _KpiData(
        title: isDark ? 'الأرصدة المعلقة' : 'أرصدة العملاء',
        value: _currencyFmt.format(totalBalances),
        icon: Icons.account_balance_wallet_outlined,
        color: AppTheme.infoBlue,
        progress: _balanceRate() / 100,
        subtitle: _balanceRate() > 50 ? '⚠️ مراجعة مستحقة' : 'ممتاز',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
                ? 2
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.9,
          ),
          itemCount: kpiData.length,
          itemBuilder: (context, index) {
            final data = kpiData[index];
            return _KpiCard(data: data);
          },
        );
      },
    );
  }

  Widget _buildSalesTrendChart() {
    final spots = _dailySalesTrend(_invoices);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (spots.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2B40) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('لا توجد بيانات مبيعات')),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2B40) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridEnable: false,
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: spots
              .map((e) => e.y)
              .reduce((a, b) => a > b ? a : b) *
              1.2,
          lineChartBarData: [
            LineChartBarData(
              spots: spots,
              color: AppTheme.primaryGold,
              barWidth: 3,
              isCurved: true,
              belowBarData: BelowBarData(
                show: true,
                color: AppTheme.primaryGold.withOpacity(0.15),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  color: AppTheme.secondaryGold,
                  radius: 4,
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                show: false,
                getTitlesWidget: (value, meta) => const SizedBox.shrink(),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                show: true,
                getTitlesStyle: (value) => GoogleFonts.cairo(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOperationsTable() {
    if (_invoices.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2B2B40)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('لا توجد فواتق حديثة')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sortedInvoices = List.of(_invoices)
      ..sort((a, b) => (b.date ?? DateTime.now())
          .compareTo(a.date ?? DateTime.now()));
    final recentInvoices = sortedInvoices.take(8).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2B40) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(
          dataTableTheme: DataTableThemeData(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            headingRowColor: MaterialStateColor.resolveWith(
              (states) => isDark
                  ? const Color(0xFF3A3A55)
                  : const Color(0xFFF1F5F9),
            ),
            dataRowColor: MaterialStateColor.resolveWith(
              (states) => isDark ? const Color(0xFF2B2B40) : Colors.white,
            ),
            dividerColor: isDark
                ? const Color(0xFF3A3A55)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: DataTable(
          columnSpacing: 18,
          headingRowHeight: 40,
          dataRowHeight: 48,
          columns: [
            _buildDataColumn('العميل', isDark),
            _buildDataColumn('المبلغ', isDark),
            _buildDataColumn('التاريخ', isDark),
            _buildDataColumn('الحالة', isDark),
          ],
          rows: recentInvoices.map((inv) {
            final status = inv.status ?? 'pending';
            final statusColor = status == 'paid'
                ? AppTheme.emeraldGreen
                : status == 'cancelled'
                    ? AppTheme.roseRed
                    : AppTheme.warningAmber;
            return DataRow(
              cells: [
                DataCell(Text(
                  inv.customerName ?? inv.branchName ?? 'غير محدد',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppTheme.darkSlate,
                  ),
                )),
                DataCell(Text(
                  _currencyFmt.format(inv.totalAmount ?? 0),
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.w600,
                  ),
                )),
                DataCell(Text(
                  inv.date != null
                      ? DateFormat('yyyy/MM/dd').format(inv.date!)
                      : '-',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : AppTheme.textMuted,
                  ),
                )),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(status),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String title, bool isDark) {
    return DataColumn(
      label: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade400 : AppTheme.textMuted,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'مدفوع';
      case 'cancelled':
        return 'ملغي';
      case 'pending':
      default:
        return 'جديد';
    }
  }

  Widget _buildDoughnutChart(Map<String, double> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2B2B40) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('لا توجد بيانات')),
      );
    }

    final colors = [
      AppTheme.primaryGold,
      AppTheme.emeraldGreen,
      AppTheme.infoBlue,
      AppTheme.roseRed,
      AppTheme.warningAmber,
      AppTheme.secondaryGold,
    ];

    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    final totalSales = data.values.fold(0.0, (a, b) => a + b);
    for (final entry in data.entries) {
      final percentage = totalSales > 0
          ? (entry.value / totalSales * 100).toStringAsFixed(1)
          : '0';
      sections.add(PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: entry.value,
        title: '$percentage%',
        titleStyle: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: 48,
        border: BorderSide(
          color: isDark ? const Color(0xFF2B2B40) : Colors.white,
          width: 2,
        ),
      ));
      colorIndex++;
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2B40) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerText: 'المبيعات',
                centerTextStyle: GoogleFonts.cairo(
                  color: isDark ? Colors.white70 : AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                sections: sections,
              ),
            ),
          ),
          _buildChartLegend(data, colors),
        ],
      ),
    );
  }

  Widget _buildChartLegend(Map<String, double> data, List<Color> colors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSales = data.values.fold(0.0, (a, b) => a + b);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final idx = data.keys.toList().indexOf(entry.key);
        final percentage = totalSales > 0
            ? (entry.value / totalSales * 100).toStringAsFixed(1)
            : '0';
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[idx % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDark
                            ? Colors.grey.shade300
                            : AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$_percentage%',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalInvoices = _invoices.length;
    final totalVisits = _visits.length;
    final avgInvoice =
        totalInvoices > 0 ? _totalSales(_invoices) / totalInvoices : 0;
    final avgVisit = totalVisits > 0 ? _totalCollections(_visits) / totalVisits : 0;
    final paidInvoices = _invoices.where((e) =>
        (e.status ?? '') == 'paid').length;
    final visitRate = totalInvoices > 0 ? paidInvoices / totalInvoices : 0;

    final cards = [
      _SummaryCard(
        title: 'إجمالي الفواتق',
        value: totalInvoices.toString(),
        icon: Icons.receipt_long_outlined,
        color: AppTheme.infoBlue,
        subtitle: _currencyFmt.format(_totalSales(_invoices)),
        isCurrency: true,
      ),
      _SummaryCard(
        title: 'الزيارات المسجلة',
        value: totalVisits.toString(),
        icon: Icons.location_on_outlined,
        color: AppTheme.emeraldGreen,
        subtitle: _currencyFmt.format(avgVisit),
        isCurrency: true,
      ),
      _SummaryCard(
        title: 'متوسط الفاتورة',
        value: _currencyFmt.format(avgInvoice),
        icon: Icons.calculate_outlined,
        color: AppTheme.primaryGold,
        subtitle: '${(visitRate * 100).toStringAsFixed(0)}% مدفوعة',
        isCurrency: false,
      ),
      _SummaryCard(
        title: 'معدل التحصيل',
        value: '${(_collectionRate()).toStringAsFixed(1)}%',
        icon: Icons.trending_up_outlined,
        color: AppTheme.secondaryGold,
        subtitle: _currencyFmt.format(_totalCollections(_visits)),
        isCurrency: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double progress;

  _KpiData({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? const Color(0xFF2B2B40) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    data.icon,
                    color: data.color,
                    size: 22,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(data.progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: data.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.value,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.darkSlate,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              data.title,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : AppTheme.textMuted,
              ),
            ),
            if (data.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                data.subtitle!,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.progress,
                backgroundColor: isDark
                    ? Colors.grey.shade700
                    : const Color(0xFFE2E8F0),
                color: data.color,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isCurrency;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2B40) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A55) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.darkSlate,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : AppTheme.textMuted,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}