import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class RepPerformanceScreen extends StatefulWidget {
  final AppUser currentUser;
  const RepPerformanceScreen({super.key, required this.currentUser});

  @override
  State<RepPerformanceScreen> createState() => _RepPerformanceScreenState();
}

class _RepPerformanceScreenState extends State<RepPerformanceScreen> {
  List<TargetRecord> _targets = [];
  bool _isLoading = true;
  String _selectedPeriod = '2025';
  int? _selectedMonth;

  final List<String> _periods = ['2026', '2025', '2024'];
  final List<String> _months = [
    'الكل', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

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
      branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
      year: int.tryParse(_selectedPeriod),
    );
    final visible = rbac.filterTargets(data);

    if (data.isEmpty) {
      _targets = _generateMockTargets();
    } else {
      _targets = visible;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<TargetRecord> _generateMockTargets() {
    return [
      TargetRecord(
        id: 't1',
        branch: widget.currentUser.branchName,
        repName: widget.currentUser.name,
        salesTarget: 500000,
        salesAchieved: 425000,
        salesPercentage: 85,
        collectionTarget: 400000,
        collectionAchieved: 350000,
        collectionPercentage: 87.5,
        date: '2026-10-01',
        month: 10,
        year: 2026,
        quarter: 'Q4',
        remainingSales: 75000,
        remainingCollection: 50000,
      ),
      TargetRecord(
        id: 't2',
        branch: widget.currentUser.branchName,
        repName: widget.currentUser.name,
        salesTarget: 450000,
        salesAchieved: 380000,
        salesPercentage: 84.4,
        collectionTarget: 380000,
        collectionAchieved: 320000,
        collectionPercentage: 84.2,
        date: '2026-09-01',
        month: 9,
        year: 2026,
        quarter: 'Q3',
        remainingSales: 70000,
        remainingCollection: 60000,
      ),
      TargetRecord(
        id: 't3',
        branch: widget.currentUser.branchName,
        repName: widget.currentUser.name,
        salesTarget: 480000,
        salesAchieved: 465000,
        salesPercentage: 96.9,
        collectionTarget: 400000,
        collectionAchieved: 390000,
        collectionPercentage: 97.5,
        date: '2026-08-01',
        month: 8,
        year: 2026,
        quarter: 'Q3',
        remainingSales: 15000,
        remainingCollection: 10000,
      ),
    ];
  }

  List<TargetRecord> get _filteredTargets {
    if (_selectedMonth != null && _selectedMonth! > 0) {
      return _targets.where((t) => t.month == _selectedMonth).toList();
    }
    return _targets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('أداءي وأهدافي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.cairo()))).toList(),
              onChanged: (val) {
                setState(() => _selectedPeriod = val!);
                _loadTargets();
              },
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
              dropdownColor: AppTheme.cardSlate,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<int>(
              value: _selectedMonth,
              items: [
                DropdownMenuItem(value: null, child: Text('الكل', style: GoogleFonts.cairo())),
                for (int i = 1; i <= 12; i++)
                  DropdownMenuItem(value: i, child: Text(_months[i], style: GoogleFonts.cairo())),
              ],
              onChanged: (val) {
                setState(() => _selectedMonth = val);
              },
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
              dropdownColor: AppTheme.cardSlate,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadTargets(),
              child: _filteredTargets.isEmpty
                  ? Center(child: Text('لا توجد أهداف للعرض', style: GoogleFonts.cairo(color: AppTheme.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredTargets.length,
                      itemBuilder: (context, index) {
                        final target = _filteredTargets[index];
                        return _buildTargetCard(target);
                      },
                    ),
            ),
    );
  }

  Widget _buildTargetCard(TargetRecord target) {
    final monthName = target.month > 0 && target.month <= 12 ? _months[target.month] : 'الكل';
    final salesPct = target.salesPercentage;
    final collectionPct = target.collectionPercentage;

    final salesProgress = (salesPct / 100).clamp(0.0, 1.0);
    final collectionProgress = (collectionPct / 100).clamp(0.0, 1.0);

    final isSalesOnTrack = salesPct >= 90;
    final isSalesBehind = salesPct < 80;
    final isCollectionOnTrack = collectionPct >= 90;
    final isCollectionBehind = collectionPct < 80;

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$monthName $targetPeriod',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkSlate),
                      ),
                      Text(
                        '${target.branch} • ${target.quarter}',
                        style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: salesPct >= 90
                        ? AppTheme.emeraldGreen.withOpacity(0.15)
                        : salesPct >= 80
                            ? AppTheme.primaryGold.withOpacity(0.15)
                            : AppTheme.roseRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${salesPct.toStringAsFixed(1)}%',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: salesPct >= 90
                          ? AppTheme.emeraldGreen
                          : salesPct >= 80
                              ? AppTheme.primaryGold
                              : AppTheme.roseRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Sales Target Progress
            _buildProgressRow(
              label: 'المبيعات',
              achieved: target.salesAchieved,
              target: target.salesTarget,
              percentage: salesPct,
              progress: salesProgress,
              color: isSalesOnTrack
                  ? AppTheme.emeraldGreen
                  : isSalesBehind
                      ? AppTheme.roseRed
                      : AppTheme.primaryGold,
              remaining: target.remainingSales,
            ),
            const SizedBox(height: 12),

            // Collection Target Progress
            _buildProgressRow(
              label: 'التحصيل',
              achieved: target.collectionAchieved,
              target: target.collectionTarget,
              percentage: collectionPct,
              progress: collectionProgress,
              color: isCollectionOnTrack
                  ? AppTheme.emeraldGreen
                  : isCollectionBehind
                      ? AppTheme.roseRed
                      : AppTheme.primaryGold,
              remaining: target.remainingCollection,
            ),
          ],
        ),
      ),
    );
  }

  String get targetPeriod {
    if (_selectedPeriod == DateTime.now().year.toString()) return 'العام الحالي';
    return 'عام $_selectedPeriod';
  }

  Widget _buildProgressRow({
    required String label,
    required double achieved,
    required double target,
    required double percentage,
    required double progress,
    required Color color,
    required double remaining,
  }) {
    final targetStr = target.toStringAsFixed(0);
    final achievedStr = achieved.toStringAsFixed(0);
    final remainingStr = remaining.toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label مبيعات:', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textMuted)),
            Text(
              '$achievedStr / $targetStr ج.م (${percentage.toStringAsFixed(1)}%)',
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          percent: progress,
          backgroundColor: const Color(0xFFE2E8F0),
          progressColor: color,
          minHeight: 10,
          borderRadius: 5,
        ),
        const SizedBox(height: 4),
        Text(
          'المتبقي: $remainingStr ج.م للوصول للهدف',
          style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

// Simple linear progress indicator widget (avoiding external dependencies)
class LinearPercentIndicator extends StatelessWidget {
  final double percent;
  final Color backgroundColor;
  final Color progressColor;
  final double minHeight;
  final double borderRadius;

  const LinearPercentIndicator({
    super.key,
    required this.percent,
    required this.backgroundColor,
    required this.progressColor,
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
                    right: clampedPercent >= 1.0 ? Radius.circular(borderRadius) : Radius.zero,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
