import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class TargetPerformanceScreen extends StatefulWidget {
  final AppUser currentUser;
  final String? branchName;
  final bool isManagerView;
  const TargetPerformanceScreen({
    super.key,
    required this.currentUser,
    this.branchName,
    this.isManagerView = true,
  });

  @override
  State<TargetPerformanceScreen> createState() =>
      _TargetPerformanceScreenState();
}

class _TargetPerformanceScreenState extends State<TargetPerformanceScreen> {
  List<TargetRecord> _targets = [];
  List<TargetRecord> _filteredTargets = [];
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  String? _selectedBranch;
  String? _selectedRep;
  String? _selectedQuarter;

  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  List<String> _branches = [];
  List<String> _reps = [];

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  void _loadTargets() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.fetchTargets(
      repName: rbac.isSalesRep ? widget.currentUser.name : null,
      branchName: rbac.isAdmin
          ? null
          : (widget.branchName ?? widget.currentUser.branchName),
      year: _selectedYear,
    );
    final visible = rbac.filterTargets(data);
    _targets = visible;
    _extractFilters();
    _applyFilters();
    if (mounted) setState(() => _isLoading = false);
  }

  void _extractFilters() {
    final branchesSet = _targets.map((t) => t.branch).whereType<String>().toSet();
    final repsSet = _targets.map((t) => t.repName ?? t.salesRepName ?? '').where((r) => r.isNotEmpty).toSet();
    final quartersSet = _targets.map((t) => t.quarter).whereType<String>().toSet();
    _branches = ['الكل', ...branchesSet]..sort();
    _reps = ['الكل', ...repsSet]..sort();
    _selectedQuarter = quartersSet.isNotEmpty ? quartersSet.first : null;
  }

  void _applyFilters() {
    setState(() {
      _filteredTargets = _targets.where((t) {
        final branchMatch = _selectedBranch == null || _selectedBranch == 'الكل' || t.branch == _selectedBranch;
        final repMatch = _selectedRep == null || _selectedRep == 'الكل' ||
            (t.repName ?? t.salesRepName ?? '') == _selectedRep;
        final quarterMatch = _selectedQuarter == null || _selectedQuarter == 'الكل' || t.quarter == _selectedQuarter;
        return branchMatch && repMatch && quarterMatch;
      }).toList();
    });
  }

  List<TargetRecord> get _branchAggregates {
    final byBranch = <String, List<TargetRecord>>{};
    for (final t in _filteredTargets) {
      byBranch.putIfAbsent(t.branch, () => []).add(t);
    }
    return byBranch.entries.map((e) {
      final branch = e.key;
      final records = e.value;
      final salesTarget = records.fold<double>(0, (s, r) => s + r.salesTarget);
      final salesAchieved = records.fold<double>(0, (s, r) => s + r.salesAchieved);
      final collectionTarget = records.fold<double>(0, (s, r) => s + r.collectionTarget);
      final collectionAchieved = records.fold<double>(0, (s, r) => s + r.collectionAchieved);
      final salesPct = salesTarget > 0 ? (salesAchieved / salesTarget) * 100 : 0;
      final collectionPct = collectionTarget > 0 ? (collectionAchieved / collectionTarget) * 100 : 0;
      return TargetRecord(
        id: 'branch_${branch}',
        branch: branch,
        repName: records.length.toString(),
        salesTarget: salesTarget,
        salesAchieved: salesAchieved,
        salesPercentage: salesPct,
        collectionTarget: collectionTarget,
        collectionAchieved: collectionAchieved,
        collectionPercentage: collectionPct,
        date: '',
        quarter: records.first.quarter,
        remainingSales: salesTarget - salesAchieved,
        remainingCollection: collectionTarget - collectionAchieved,
      );
    }).toList()
      ..sort((a, b) => b.salesAchieved.compareTo(a.salesAchieved));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkCard : AppTheme.backgroundLight;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    final salesTotal = _filteredTargets.fold<double>(0, (s, t) => s + t.salesTarget);
    final salesAchieved = _filteredTargets.fold<double>(0, (s, t) => s + t.salesAchieved);
    final salesPct = salesTotal > 0 ? (salesAchieved / salesTotal) * 100 : 0.0;
    final collectionTotal = _filteredTargets.fold<double>(0, (s, t) => s + t.collectionTarget);
    final collectionAchieved = _filteredTargets.fold<double>(0, (s, t) => s + t.collectionAchieved);
    final collectionPct = collectionTotal > 0
        ? (collectionAchieved / collectionTotal) * 100
        : 0.0;

    final branchAgg = _branchAggregates;
    final activeBranches = branchAgg.length;
    final totalReps = _filteredTargets.fold<int>(0, (s, t) => s + (int.tryParse(t.repName ?? '0') ?? 0));

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text(
          widget.isManagerView ? 'أداء الفريق والأهداف' : 'أهدافي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<int>(
              value: _selectedYear,
              items: [2026, 2025, 2024]
                  .map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(y.toString(), style: GoogleFonts.cairo()),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedYear = v ?? DateTime.now().year);
                _loadTargets();
              },
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
              dropdownColor: AppTheme.darkSlate,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.more_vert, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadTargets(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === Summary Cards ===
                    _buildSummaryCards(
                      salesPct, salesAchieved, salesTotal,
                      collectionPct, collectionAchieved, collectionTotal,
                      branchAgg, totalReps, activeBranches,
                      textColor, mutedColor, borderColor, isDark,
                    ),

                    const SizedBox(height: 20),

                    // === Filters ===
                    _buildFilters(isDark, borderColor, surfaceColor, textColor),

                    const SizedBox(height: 20),

                    // === Charts ===
                    _buildCharts(isDark, surfaceColor, borderColor, textColor, mutedColor),

                    const SizedBox(height: 20),

                    // === Data Table ===
                    _buildDataTable(isDark, surfaceColor, borderColor, textColor, mutedColor),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards(
    double salesPct, double salesAchieved, double salesTotal,
    double collectionPct, double collectionAchieved, double collectionTotal,
    List<TargetRecord> branchAgg, int totalReps, int activeBranches,
    Color textColor, Color mutedColor, Color borderColor, bool isDark,
  ) {
    final cardColor = isDark ? AppTheme.cardSlate : Colors.white;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildSummaryCard(
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          mutedColor: mutedColor,
          title: 'مبيعات',
          value: '${salesPct.toStringAsFixed(1)}%',
          subtitle: '${_currencyFmt.format(salesAchieved)} / ${_currencyFmt.format(salesTotal)}',
          icon: Icons.trending_up,
          iconColor: _pctColor(salesPct),
          progress: salesPct / 100,
          progressColor: _pctColor(salesPct),
        ),
        _buildSummaryCard(
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          mutedColor: mutedColor,
          title: 'تحصيل',
          value: '${collectionPct.toStringAsFixed(1)}%',
          subtitle: '${_currencyFmt.format(collectionAchieved)} / ${_currencyFmt.format(collectionTotal)}',
          icon: Icons.account_balance_wallet,
          iconColor: _pctColor(collectionPct),
          progress: collectionPct / 100,
          progressColor: _pctColor(collectionPct),
        ),
        _buildSummaryCard(
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          mutedColor: mutedColor,
          title: 'فروع نشطة',
          value: activeBranches.toString(),
          subtitle: 'من إجمالي 7 فروع',
          icon: Icons.store,
          iconColor: AppTheme.primaryGold,
          showProgress: false,
        ),
        _buildSummaryCard(
          cardColor: cardColor,
          borderColor: borderColor,
          textColor: textColor,
          mutedColor: mutedColor,
          title: 'موظفين',
          value: totalReps.toString(),
          subtitle: 'مسجلين في الأهداف',
          icon: Icons.people,
          iconColor: AppTheme.infoBlue,
          showProgress: false,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    double progress = 0,
    required Color progressColor,
    bool showProgress = true,
  }) {
    return SizedBox(
      width: 280,
      child: Card(
        color: cardColor,
        elevation: isDark ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: GoogleFonts.cairo(fontSize: 12, color: mutedColor)),
                  Icon(icon, size: 18, color: iconColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(value, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
              if (showProgress) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    backgroundColor: borderColor,
                    color: progressColor,
                    minHeight: 5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark, Color borderColor, Color surfaceColor, Color textColor) {
    final fieldColor = isDark ? AppTheme.darkCard : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التصفية', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 150,
                child: _buildFilterDropdown<String>(
                  label: 'الفرع',
                  value: _selectedBranch,
                  items: _branches,
                  onChanged: (v) => setState(() => _selectedBranch = v),
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
              ),
              if (!rbac.isSalesRep)
                SizedBox(
                  width: 150,
                  child: _buildFilterDropdown<String>(
                    label: 'الموظف',
                    value: _selectedRep,
                    items: _reps,
                    onChanged: (v) => setState(() => _selectedRep = v),
                    isDark: isDark,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                ),
              SizedBox(
                width: 150,
                child: _buildFilterDropdown<String>(
                  label: 'الربع',
                  value: _selectedQuarter,
                  items: ['الكل', ...{'Q1', 'Q2', 'Q3', 'Q4'}],
                  onChanged: (v) => setState(() => _selectedQuarter = v),
                  isDark: isDark,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
  }) {
    final fieldColor = isDark ? AppTheme.darkCard : Colors.white;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 11, color: textColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(item.toString(), style: GoogleFonts.cairo(fontSize: 12, color: textColor)),
            );
          }).toList(),
          onChanged: (v) {
            onChanged(v as T?);
            _applyFilters();
          },
          style: GoogleFonts.cairo(color: textColor, fontSize: 13),
          dropdownColor: fieldColor,
          icon: Icon(Icons.arrow_drop_down, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
        ),
      ),
    );
  }

  Widget _buildCharts(bool isDark, Color surfaceColor, Color borderColor, Color textColor, Color mutedColor) {
    final cardColor = isDark ? AppTheme.cardSlate : Colors.white;
    final branchAgg = _branchAggregates;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مبيعات حسب الفرع (${_selectedYear})',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 12),
              if (branchAgg.isEmpty)
                Center(child: Text('لا توجد بيانات متاحة', style: GoogleFonts.cairo(fontSize: 12, color: mutedColor)))
              else
                _buildSalesBarChart(branchAgg, isDark, borderColor, textColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'توزيع المبيعات حسب الفرع',
                style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 12),
              if (branchAgg.isEmpty)
                Center(child: Text('لا توجد بيانات متاحة', style: GoogleFonts.cairo(fontSize: 12, color: mutedColor)))
              else
                _buildSalesPieChart(branchAgg, isDark, borderColor, textColor, mutedColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesBarChart(List<TargetRecord> branchAgg, bool isDark, Color borderColor, Color textColor) {
    final barGroups = branchAgg.asMap().entries.map((entry) {
      final index = entry.key;
      final t = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: t.salesTarget > 0 ? (t.salesAchieved.isNaN ? 0 : t.salesAchieved) : 0,
            color: AppTheme.primaryGold,
            width: 8,
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                show: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < branchAgg.length) {
                    final label = branchAgg[value.toInt()].branch.length > 8
                        ? branchAgg[value.toInt()].branch.substring(0, 8) + '...'
                        : branchAgg[value.toInt()].branch;
                    return SideTitleWidget(
                      child: Text(label, style: GoogleFonts.cairo(fontSize: 8, color: textColor)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                show: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}k', style: GoogleFonts.cairo(fontSize: 8, color: textColor));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesPieChart(List<TargetRecord> branchAgg, bool isDark, Color borderColor, Color textColor, Color mutedColor) {
    final totalSales = branchAgg.fold<double>(0, (s, t) => s + t.salesAchieved);
    final sectionColors = [
      AppTheme.primaryGold, AppTheme.infoBlue, AppTheme.emeraldGreen,
      AppTheme.secondaryGold, AppTheme.warningAmber, AppTheme.roseRed,
      AppTheme.silver,
    ];

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          pieTouchData: PieTouchData(),
          sections: branchAgg.asMap().entries.map((entry) {
            final index = entry.key;
            final t = entry.value;
            final percentage = totalSales > 0 ? (t.salesAchieved / totalSales) * 100 : 0;
            final percentageStr = percentage > 3 ? '${percentage.toStringAsFixed(0)}%' : '';
            return PieChartSectionData(
              title: percentageStr,
              titleStyle: GoogleFonts.cairo(fontSize: 9, color: Colors.white),
              titlePadding: EdgeInsets.zero,
              color: sectionColors[index % sectionColors.length],
              value: t.salesAchieved.isNaN ? 0 : t.salesAchieved,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataTable(bool isDark, Color surfaceColor, Color borderColor, Color textColor, Color mutedColor) {
    final cardColor = isDark ? AppTheme.cardSlate : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              alignItems: Center,
              children: [
                Text(
                  'تفاصيل الأهداف',
                  style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text('${_filteredTargets.length} صف', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_filteredTargets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('لا توجد أهداف مسجلة للفترة المحددة',
                    style: GoogleFonts.cairo(fontSize: 13, color: mutedColor)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 36,
                dataRowHeight: 44,
                headingTextStyle: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                dataTextStyle: GoogleFonts.cairo(fontSize: 12, color: textColor),
                decorator: BoxDecoration(color: cardColor),
                columns: [
                  DataColumn(label: Text('الموظف', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor))),
                  DataColumn(label: Text('الفرع', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor))),
                  DataColumn(label: Text('المبيعات', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)), numeric: true),
                  DataColumn(label: Text('محقق مبيعات', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)), numeric: true),
                  DataColumn(label: Text('% مبيعات', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)), numeric: true),
                  DataColumn(label: Text('التحصيل', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)), numeric: true),
                  DataColumn(label: Text('محقق تحصيل', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)), numeric: true),
                  DataColumn(label: Text('% تحصيل', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor)), numeric: true),
                  DataColumn(label: Text('الربع', style: GoogleFonts.cairo(fontSize: 11, color: mutedColor))),
                ],
                rows: _filteredTargets.map((t) {
                  return DataRow(
                    cells: [
                      DataCell(Text(t.repName.isNotEmpty ? t.repName : '—', style: GoogleFonts.cairo(fontSize: 12, color: textColor))),
                      DataCell(Text(t.branch, style: GoogleFonts.cairo(fontSize: 12, color: textColor))),
                      DataCell(Text(_currencyFmt.format(t.salesTarget), style: GoogleFonts.cairo(fontSize: 11, color: mutedColor))),
                      DataCell(Text(_currencyFmt.format(t.salesAchieved), style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: textColor))),
                      DataCell(_buildPercentageCell(t.salesPercentage, textColor)),
                      DataCell(Text(_currencyFmt.format(t.collectionTarget), style: GoogleFonts.cairo(fontSize: 11, color: mutedColor))),
                      DataCell(Text(_currencyFmt.format(t.collectionAchieved), style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: textColor))),
                      DataCell(_buildPercentageCell(t.collectionPercentage, textColor)),
                      DataCell(Text(t.quarter, style: GoogleFonts.cairo(fontSize: 11, color: textColor))),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPercentageCell(double pct, Color textColor) {
    final color = _pctColor(pct);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('${pct.toStringAsFixed(1)}%',
          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 100) return AppTheme.emeraldGreen;
    if (pct >= 80) return AppTheme.primaryGold;
    return AppTheme.errorRed;
  }
}
