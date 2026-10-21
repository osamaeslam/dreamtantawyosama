import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';

class ManagementDashboard extends StatefulWidget {
  final AppUser currentUser;
  const ManagementDashboard({super.key, required this.currentUser});

  @override
  State<ManagementDashboard> createState() => _ManagementDashboardState();
}

class _ManagementDashboardState extends State<ManagementDashboard> {
  List<TargetRecord> _targets = [];
  List<CustomerAnalytics> _customers = [];
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  String _selectedQuarter = 'ALL';
  String _selectedMonth = 'ALL';

  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);
  final List<String> _quarterOptions = ['ALL', 'Q1', 'Q2', 'Q3', 'Q4'];
  final List<String> _monthOptions = [
    'ALL',
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    final targets = await SupabaseService.instance.fetchTargets(
      repName: rbac.isSalesRep ? widget.currentUser.name : null,
      branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
      year: _selectedYear,
    );
    final customers = await SupabaseService.instance.fetchCustomerAnalytics(
      branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
    );

    if (mounted) {
      setState(() {
        final filteredTargets = rbac.filterTargets(targets);
        final filteredCustomers = rbac.filterCustomers(customers);
        _targets = filteredTargets;
        _customers = filteredCustomers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesTarget = _targets.fold<double>(0, (s, t) => s + t.salesTarget);
    final salesAchieved =
        _targets.fold<double>(0, (s, t) => s + t.salesAchieved);
    final salesRate =
        salesTarget > 0 ? (salesAchieved / salesTarget) * 100 : 0.0;
    final collectionTarget =
        _targets.fold<double>(0, (s, t) => s + t.collectionTarget);
    final collectionAchieved =
        _targets.fold<double>(0, (s, t) => s + t.collectionAchieved);
    final collectionRate = collectionTarget > 0
        ? (collectionAchieved / collectionTarget) * 100
        : 0.0;
    final totalDues =
        _customers.fold<double>(0, (s, c) => c.balance > 0 ? s + c.balance : s);
    final customersWithDues = _customers.where((c) => c.balance > 0).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('لوحة الإدارة والتحليل',
            style:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          DropdownButton<int>(
            value: _selectedYear,
            items: List.generate(6, (index) => DateTime.now().year - index)
                .map((y) =>
                    DropdownMenuItem(value: y, child: Text(y.toString())))
                .toList(),
            onChanged: (v) {
              setState(() => _selectedYear = v ?? DateTime.now().year);
              _loadData();
            },
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
            dropdownColor: AppTheme.darkSlate,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_targets.isEmpty && _customers.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'لا توجد بيانات فعلية للأهداف أو العملاء في النطاق المحدد.',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                      ),
                    ],
                    Text('ملخص التنفيذي',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildKPICard(
                            'مبيعات',
                            _currencyFmt.format(salesAchieved),
                            '${salesRate.toStringAsFixed(1)}%',
                            salesRate,
                            salesTarget,
                            salesAchieved),
                        _buildKPICard(
                            'تحصيل',
                            _currencyFmt.format(collectionAchieved),
                            '${collectionRate.toStringAsFixed(1)}%',
                            collectionRate,
                            collectionTarget,
                            collectionAchieved),
                        _buildKPICard('مستحقات', _currencyFmt.format(totalDues),
                            '$customersWithDues عميل', 0, 0, 0,
                            isCurrency: false),
                        _buildKPICard('مناديب', '${_targets.length} مندوب',
                            'فعّال', 0, 0, 0,
                            isCurrency: false),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('رسم بياني للمبيعات والتحصيل',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate)),
                    const SizedBox(height: 10),
                    ResponsiveLayout(
                      mobile: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRepPerformanceBarChart(),
                          const SizedBox(height: 20),
                          Text('توزيع المستحقات على العملاء',
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkSlate)),
                          const SizedBox(height: 10),
                          _buildCustomerBalancePieChart(),
                        ],
                      ),
                      tablet: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildRepPerformanceBarChart()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildCustomerBalancePieChart()),
                        ],
                      ),
                      desktop: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildRepPerformanceBarChart()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildCustomerBalancePieChart()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('إنجاز المناديب',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _targets.length,
                      itemBuilder: (context, index) {
                        final target = _targets[index];
                        return _buildRepRow(target);
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('العملاء ذوو المستحقات',
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkSlate)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customers.where((c) => c.balance > 0).length,
                      itemBuilder: (context, index) {
                        final customer = _customers
                            .where((c) => c.balance > 0)
                            .toList()[index];
                        return _buildCustomerRow(customer);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPICard(String label, String value, String subLabel, double rate,
      double target, double achieved,
      {bool isCurrency = true}) {
    final color = rate >= 90
        ? AppTheme.emeraldGreen
        : rate >= 80
            ? AppTheme.warningAmber
            : AppTheme.errorRed;
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate)),
            if (subLabel.isNotEmpty)
              Text(subLabel,
                  style: GoogleFonts.cairo(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRepRow(TargetRecord target) {
    final rate = target.salesPercentage;
    final color = rate >= 100
        ? AppTheme.emeraldGreen
        : rate >= 80
            ? AppTheme.warningAmber
            : AppTheme.errorRed;

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.15),
          backgroundImage: target.repAvatar != null
              ? NetworkImage(target.repAvatar!)
              : null,
          child: target.repAvatar == null || target.repAvatar!.isEmpty
              ? Icon(Icons.person, color: color, size: 20)
              : null,
        ),
        title: Row(
          children: [
            Text(target.repName,
                style:
                    GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 6),
            if (target.salesPriority != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: target.salesPriority == 'مرتفع'
                      ? AppTheme.errorRed.withOpacity(0.15)
                      : target.salesPriority == 'متوسط'
                          ? AppTheme.warningAmber.withOpacity(0.15)
                          : AppTheme.emeraldGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  target.salesPriority ?? 'عادي',
                  style: GoogleFonts.cairo(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: target.salesPriority == 'مرتفع'
                        ? AppTheme.errorRed
                        : target.salesPriority == 'متوسط'
                            ? AppTheme.warningAmber
                            : AppTheme.emeraldGreen,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${target.branch} • ${target.quarter}',
                style:
                    GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
            const SizedBox(height: 2),
            Text('${target.supervisorName ?? ''} • ${(target.salesRepName ?? '')}',
                style: GoogleFonts.cairo(fontSize: 9, color: AppTheme.textMuted)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${rate.toStringAsFixed(1)}%',
                style: GoogleFonts.cairo(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            Text(
                '${_currencyFmt.format(target.salesAchieved)}/${_currencyFmt.format(target.salesTarget)}',
                style:
                    GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerRow(CustomerAnalytics customer) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.infoBlue,
          child: Icon(Icons.storefront_outlined, color: Colors.white, size: 16),
        ),
        title: Text(customer.customerName,
            style:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
        subtitle: Text('${customer.customerCode} • ${customer.tier ?? ''}',
            style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
        trailing: Text('${_currencyFmt.format(customer.balance)}',
            style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: customer.overdueBalance > 0
                    ? AppTheme.errorRed
                    : AppTheme.emeraldGreen)),
      ),
    );
  }

  Widget _buildRepPerformanceBarChart() {
    if (_targets.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('-')));
    }

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < _targets.length; i++) {
      final t = _targets[i];
      final rate = t.salesPercentage;
      final barColor = rate >= 100
          ? AppTheme.emeraldGreen
          : rate >= 80
              ? AppTheme.warningAmber
              : AppTheme.errorRed;

      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: t.salesTarget > 0
                ? (t.salesAchieved / t.salesTarget).clamp(0.0, 1.0) * 100
                : 0,
            color: barColor.withOpacity(0.8),
            width: 16,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [barColor.withOpacity(0.7), barColor.withOpacity(0.4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          BarChartRodData(
            toY: t.collectionTarget > 0
                ? (t.collectionAchieved / t.collectionTarget).clamp(0.0, 1.0) *
                    100
                : 0,
            color: AppTheme.infoBlue.withOpacity(0.8),
            width: 16,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [AppTheme.infoBlue.withOpacity(0.7), AppTheme.infoBlue.withOpacity(0.4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
        barsSpace: 6,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryGold)),
              const SizedBox(width: 4),
              Text('مبيعات', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
              const SizedBox(width: 12),
              Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.infoBlue)),
              const SizedBox(width: 4),
              Text('تحصيل', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: 120,
                barGroups: barGroups,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                    show: true,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (i) =>
                        FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 0.5)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: sideTitlesForNames()),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, _) => Text('${val.toInt()}%',
                              style: GoogleFonts.cairo(
                                  fontSize: 9, color: AppTheme.textMuted)))),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                 barTouchData: BarTouchData(
                   touchCallback: (event, response) {}
                 ),
               ),
             ),
           ),
       ],
      ),
    );
  }

  SideTitles sideTitlesForNames() => SideTitles(
        showTitles: true,
        getTitlesWidget: (val, meta) {
          final idx = val.toInt();
          if (idx < 0 || idx >= _targets.length) return const SizedBox.shrink();
          final name = _targets[idx].repName;
          return SizedBox(
            width: 60,
            child: Text(name,
                style: GoogleFonts.cairo(fontSize: 8, color: AppTheme.textDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
          );
        },
      );

  Widget _buildCustomerBalancePieChart() {
    final duesCustomers = _customers.where((c) => c.balance > 0).toList();
    if (duesCustomers.isEmpty) {
      return const SizedBox(
          height: 160, child: Center(child: Text('لا توجد مستحقات')));
    }

    final sections = <PieChartSectionData>[];
    final chartColors = [
      AppTheme.errorRed,
      AppTheme.warningAmber,
      AppTheme.infoBlue,
      AppTheme.emeraldGreen,
      AppTheme.primaryGold,
      AppTheme.roseRed,
      AppTheme.silver,
    ];

    final totalDues = duesCustomers.fold<double>(0, (sum, c) => sum + c.balance);

    for (var i = 0; i < duesCustomers.length; i++) {
      final c = duesCustomers[i];
      final color = chartColors[i % chartColors.length];
      final percentage = totalDues > 0 ? (c.balance / totalDues) * 100 : 0;
      final isOverdue = c.overdueBalance > 0;

      sections.add(PieChartSectionData(
        color: color,
        value: c.balance,
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: GoogleFonts.cairo(
            fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
        borderSide: BorderSide(
          color: isOverdue ? AppTheme.errorRed : Colors.transparent,
          width: isOverdue ? 2 : 0,
        ),
        radius: 44,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sections: sections,
                borderData: FlBorderData(show: false),
                pieTouchData: PieTouchData(touchCallback: (event, resp) {}),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('إجمالي المستحقات',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
                Text('${_currencyFmt.format(totalDues)}',
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
