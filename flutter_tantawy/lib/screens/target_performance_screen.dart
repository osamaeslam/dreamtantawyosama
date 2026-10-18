import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;
  int? _selectedMonth;

  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

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
      month: _selectedMonth,
    );
    final visible = rbac.filterTargets(data);

    if (data.isNotEmpty) {
      _targets = visible;
    } else {
      _targets = _generateMockTargets();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<TargetRecord> _generateMockTargets() {
    return [
      TargetRecord(
        id: 't1',
        branch: widget.currentUser.branchName,
        repName: 'محمد على',
        salesTarget: 500000,
        salesAchieved: 385000,
        salesPercentage: 77.0,
        collectionTarget: 400000,
        collectionAchieved: 340000,
        collectionPercentage: 85.0,
        date: '2026-10-01',
        month: 10,
        year: 2026,
        quarter: 'Q4',
        remainingSales: 115000,
        remainingCollection: 60000,
      ),
      TargetRecord(
        id: 't2',
        branch: widget.currentUser.branchName,
        repName: 'أحمد حسن',
        salesTarget: 500000,
        salesAchieved: 420000,
        salesPercentage: 84.0,
        collectionTarget: 400000,
        collectionAchieved: 360000,
        collectionPercentage: 90.0,
        date: '2026-10-01',
        month: 10,
        year: 2026,
        quarter: 'Q4',
        remainingSales: 80000,
        remainingCollection: 40000,
      ),
      TargetRecord(
        id: 't3',
        branch: widget.currentUser.branchName,
        repName: 'سارة مصطفى',
        salesTarget: 500000,
        salesAchieved: 515000,
        salesPercentage: 103.0,
        collectionTarget: 450000,
        collectionAchieved: 470000,
        collectionPercentage: 104.4,
        date: '2026-10-01',
        month: 10,
        year: 2026,
        quarter: 'Q4',
        remainingSales: -15000,
        remainingCollection: -20000,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final salesTotal = _targets.fold<double>(0, (s, t) => s + t.salesTarget);
    final salesAchieved =
        _targets.fold<double>(0, (s, t) => s + t.salesAchieved);
    final salesPct = salesTotal > 0 ? (salesAchieved / salesTotal) * 100 : 0.0;
    final collectionTotal =
        _targets.fold<double>(0, (s, t) => s + t.collectionTarget);
    final collectionAchieved =
        _targets.fold<double>(0, (s, t) => s + t.collectionAchieved);
    final collectionPct = collectionTotal > 0
        ? (collectionAchieved / collectionTotal) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
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
              icon:
                  const Icon(Icons.more_vert, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        widget.isManagerView
                            ? 'ملخص إنجاز الفريق لعام $_selectedYear'
                            : 'ملخص أهدافي لعام $_selectedYear',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${salesPct.toStringAsFixed(1)}%',
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _pctColor(salesPct),
                                ),
                              ),
                              Text('مبيعات',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: AppTheme.textMuted)),
                              Text(
                                '${_currencyFmt.format(salesAchieved)} / ${_currencyFmt.format(salesTotal)}',
                                style: GoogleFonts.cairo(
                                    fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppTheme.borderColor),
                          Column(
                            children: [
                              Text(
                                '${collectionPct.toStringAsFixed(1)}%',
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _pctColor(collectionPct),
                                ),
                              ),
                              Text('تحصيل',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: AppTheme.textMuted)),
                              Text(
                                '${_currencyFmt.format(collectionAchieved)} / ${_currencyFmt.format(collectionTotal)}',
                                style: GoogleFonts.cairo(
                                    fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Rep list
                Expanded(
                  child: _targets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.track_changes_outlined,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد أهداف مسجلة لهذه الفترة',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _targets.length,
                          itemBuilder: (context, index) {
                            final target = _targets[index];
                            return _buildRepCard(target);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRepCard(TargetRecord target) {
    final salesColor = _pctColor(target.salesPercentage);
    final collectionColor = _pctColor(target.collectionPercentage);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                  child:
                      Icon(Icons.person, color: AppTheme.primaryGold, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.repName,
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        target.quarter,
                        style: GoogleFonts.cairo(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: salesColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${target.salesPercentage.toStringAsFixed(1)}%',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: salesColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProgressRow(
              label: 'مبيعات',
              achieved: target.salesAchieved,
              target: target.salesTarget,
              percentage: target.salesPercentage,
              color: salesColor,
            ),
            const SizedBox(height: 8),
            _buildProgressRow(
              label: 'تحصيل',
              achieved: target.collectionAchieved,
              target: target.collectionTarget,
              percentage: target.collectionPercentage,
              color: collectionColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required double achieved,
    required double target,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label:',
                style:
                    GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
            Text(
              '${_currencyFmt.format(achieved)} / ${_currencyFmt.format(target)}',
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkSlate),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          percent: (percentage / 100).clamp(0, 1),
          progressColor: color,
          backgroundColor: AppTheme.borderColor,
          minHeight: 6,
          borderRadius: 3,
        ),
      ],
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 100) return AppTheme.emeraldGreen;
    if (pct >= 80) return AppTheme.primaryGold;
    return AppTheme.errorRed;
  }
}

class LinearPercentIndicator extends StatelessWidget {
  final double percent;
  final Color backgroundColor;
  final Color progressColor;
  final double minHeight;
  final double borderRadius;

  const LinearPercentIndicator({
    super.key,
    required this.percent,
    required this.progressColor,
    required this.backgroundColor,
    required this.minHeight,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final progressWidth = maxWidth * clampedPercent;

        return Stack(
          children: [
            Container(
              width: maxWidth,
              height: minHeight,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            if (clampedPercent > 0)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: progressWidth,
                height: minHeight,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(borderRadius),
                    right: clampedPercent >= 1.0
                        ? Radius.circular(borderRadius)
                        : Radius.zero,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
