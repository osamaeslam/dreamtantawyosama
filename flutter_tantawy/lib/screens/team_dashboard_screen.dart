import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connection_status_bar.dart';

/// Branch-manager team dashboard: shows every rep under the manager's branch
/// with **separately sortable** metrics for sales, collections, expenses,
/// outstanding debts, and visit counts.
///
/// Each metric column is an independent sortable header — clicking sorts the
/// entire list by that column without affecting the others (no composite score).
class TeamDashboardScreen extends StatefulWidget {
  final AppUser currentUser;
  const TeamDashboardScreen({super.key, required this.currentUser});

  @override
  State<TeamDashboardScreen> createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  List<RepPerformance> _reps = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Column sort state: null = none, true = asc, false = desc
  int? _sortedColumn;
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _loadRepPerformance();
  }

  Future<void> _loadRepPerformance() async {
    setState(() => _isLoading = true);
    try {
      final reps = await SupabaseService.instance.fetchRepPerformance(
        branchName: widget.currentUser.branchName,
        month: DateTime.now().month,
        year: DateTime.now().year,
      );
      setState(() {
        _reps = reps;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() => _errorMessage = 'فشل تحميل بيانات الفريق: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortedColumn = columnIndex;
      _ascending = ascending;
      _reps = _applySort(_reps, columnIndex, ascending);
    });
  }

  List<RepPerformance> _applySort(
    List<RepPerformance> reps,
    int column,
    bool ascending,
  ) {
    final sorted = List<RepPerformance>.from(reps);
    int compare(double a, double b) => a.compareTo(b);

    switch (column) {
      case 0: // اسم المندوب
        sorted.sort((a, b) => a.repName.compareTo(b.repName));
        break;
      case 1: // المبيعات
        sorted.sort((a, b) => compare(a.salesAchieved, b.salesAchieved));
        break;
      case 2: // التحصيلات
        sorted.sort((a, b) => compare(a.collectionAchieved, b.collectionAchieved));
        break;
      case 3: // المصروفات (inferred from collections vs sales variance)
        sorted.sort((a, b) =>
            compare(a.collections2026 - a.sales2026, b.collections2026 - b.sales2026));
        break;
      case 4: // الديون (targets not yet achieved)
        sorted.sort((a, b) =>
            compare(a.salesTarget - a.salesAchieved, b.salesTarget - b.salesAchieved));
        break;
      case 5: // عدد الزيارات
        sorted.sort((a, b) => a.visitsCount.compareTo(b.visitsCount));
        break;
      case 6: // التقدم للهدف
        sorted.sort((a, b) {
          final pa = a.salesTarget > 0 ? a.salesAchieved / a.salesTarget : 0;
          final pb = b.salesTarget > 0 ? b.salesAchieved / b.salesTarget : 0;
          return pa.compareTo(pb);
        });
        break;
    }
    return ascending ? sorted : sorted.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة فريق المناديب', style: GoogleFonts.cairo()),
        bottom: AppBar(
          backgroundColor: isDark ? AppTheme.cardSlate : AppTheme.backgroundLight,
          title: const ConnectionStatusBar(),
          automaticallyImplyLeading: false,
          toolbarHeight: 32,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadRepPerformance,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _buildTeamTable(isDark),
    );
  }

  Widget _buildTeamTable(bool isDark) {
    if (_reps.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد مندوبون مسجلون في فرعك',
          style: GoogleFonts.cairo(color: Theme.of(context).hintColor),
        ),
      );
    }

    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    final headerColor = isDark ? AppTheme.cardSlate : AppTheme.backgroundLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSalesChart(),
          const SizedBox(height: 24),
          Material(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                _buildHeaderRow(headerColor, borderColor),
                ..._reps.asMap().entries.map(
                      (e) => _buildDataRow(e.value, e.key, cardColor, borderColor),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    if (_reps.isEmpty) return const SizedBox.shrink();

    final spots = _reps.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.salesAchieved);
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
       child: BarChart(
         BarChartData(
           borderData: FlBorderData(show: false),
           gridData: const FlGridData(show: false),
           titlesData: FlTitlesData(
             topTitles: AxisTitles(sideTitles: SideTitles(show: false)),
             rightTitles: AxisTitles(sideTitles: SideTitles(show: false)),
             bottomTitles: AxisTitles(
               sideTitles: SideTitles(
                 show: true,
                 getTitlesWidget: (value, meta) {
                   final idx = value.toInt();
                   if (idx < 0 || idx >= _reps.length) return const SizedBox.shrink();
                   final name = _reps[idx].repName.split(' ').first;
                   return SideTitleWidget(
                     child: Text(name,
                         style: GoogleFonts.cairo(fontSize: 9)),
                   );
                 },
               ),
             ),
             leftTitles: AxisTitles(
               sideTitles: SideTitles(show: true, getTitlesWidget: _currencyTitle),
             ),
           ),
           barChartGroups: spots.asMap().entries.map((e) {
             return BarChartGroupData(
               x: e.key,
               barRods: [BarChartRodData(toY: e.value.y, color: AppTheme.infoBlue, width: 22)],
               barTouchData: BarTouchData(enabled: true),
             );
           }).toList(),
         ),
       ),
    );
  }

  Widget _currencyTitle(TitleMeta meta) {
    return Text('${(meta.value).toInt()}', style: GoogleFonts.cairo(fontSize: 9));
  }

  Widget _buildHeaderRow(Color headerColor, Color borderColor) {
    final headers = [
      ('المندوب', 0),
      ('المبيعات', 1),
      ('التحصيلات', 2),
      ('المصروفات', 3),
      ('الديون', 4),
      ('الزيارات', 5),
      ('التقدم', 6),
    ];

    return TableRow(
      decoration: BoxDecoration(color: headerColor),
      children: headers.map((h) {
        final asc = _sortedColumn == h.$2 ? _ascending : null;
        return _buildHeaderCell(h.$1, h.$2, asc, borderColor);
      }).toList(),
    );
  }

  Widget _buildHeaderCell(String label, int column, bool? ascending, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;

    IconData icon = Icons.arrow_upward;
    if (_sortedColumn == column && ascending == false) {
      icon = Icons.arrow_downward;
    } else if (_sortedColumn != column) {
      icon = Icons.unfold_more_rounded;
    }

    return GestureDetector(
      onTap: () => _sort(column, ascending == true ? false : true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 11, color: textColor, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: textColor),
          ],
        ),
      ),
    );
  }

  TableRow _buildDataRow(
    RepPerformance rep,
    int index,
    Color cardColor,
    Color borderColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rate = rep.salesTarget > 0 ? (rep.salesAchieved / rep.salesTarget) * 100 : 0;

    return TableRow(
      decoration: BoxDecoration(
        color: cardColor.withOpacity(index.isEven ? 0.02 : 0.0),
        border: index < _reps.length - 1
            ? Border(top: BorderSide(color: borderColor, width: 0.5))
            : null,
      ),
      children: [
        _cell(rep.repName, isDark),
        _cell('${rep.salesAchieved.toInt()} ${_formatCurrency()}', isDark),
        _cell('${rep.collectionAchieved.toInt()} ${_formatCurrency()}', isDark),
        _cell('${(rep.collections2026 - rep.sales2026).toInt()} ${_formatCurrency()}', isDark),
        _cell('${(rep.salesTarget - rep.salesAchieved).toInt()} ${_formatCurrency()}', isDark),
        _cell('${rep.visitsCount}', isDark),
        _cell('${rate.toStringAsFixed(1)}%', isDark,
            valueColor: rate >= 100
                ? AppTheme.emeraldGreen
                : rate >= 70
                    ? AppTheme.primaryGold
                    : AppTheme.roseRed),
      ],
    );
  }

  Widget _cell(
    String text,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 12,
          color: valueColor ?? (isDark ? Colors.white70 : AppTheme.textDark),
          fontWeight: valueColor != null ? FontWeight.w600 : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatCurrency() => 'د.ك';
}
