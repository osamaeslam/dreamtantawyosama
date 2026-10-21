import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/repositories/forecast_repository.dart';
import '../services/role_access_controller.dart';
import '../theme/app_theme.dart';

class CollectionForecastView extends StatefulWidget {
  final AppUser currentUser;
  final String? monthKey;
  const CollectionForecastView({super.key, required this.currentUser, this.monthKey});

  @override
  State<CollectionForecastView> createState() => _CollectionForecastViewState();
}

class _CollectionForecastViewState extends State<CollectionForecastView> {
  List<CollectionForecastRecord> _forecasts = [];
  ForecastMonthPlan? _monthPlan;
  bool _isLoading = true;
  String _selectedMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
  ForecastStatusType _selectedStatus = ForecastStatusType.submitted;

  final NumberFormat _currencyFmt = NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _selectedMonthKey = widget.monthKey ?? _selectedMonthKey;
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    final monthPlan = await SupabaseService.instance.fetchForecastMonthPlan(_selectedMonthKey);
    final data = await SupabaseService.instance.fetchForecasts(
      monthKey: _selectedMonthKey,
      status: _selectedStatus,
    );

    if (mounted) {
      setState(() {
        _monthPlan = monthPlan;
        _forecasts = data.isNotEmpty ? data : _generateMockForecasts();
        _isLoading = false;
      });
    }
  }

  List<CollectionForecastRecord> _generateMockForecasts() {
    return [
      CollectionForecastRecord(
        id: 'f1',
        monthKey: _selectedMonthKey,
        weekIndex: 0,
        repId: 'rep_1',
        repName: 'محمد على',
        branchName: widget.currentUser.branchName,
        customerId: 'cust_1',
        customerCode: 'CUST-001',
        customerName: 'مخازن البتروز',
        collectionForecast: 45000,
        salesForecast: 50000,
        status: ForecastStatusType.submitted,
        submittedAt: '${_selectedMonthKey}-01T10:00:00',
      ),
      CollectionForecastRecord(
        id: 'f2',
        monthKey: _selectedMonthKey,
        weekIndex: 0,
        repId: 'rep_1',
        repName: 'محمد على',
        branchName: widget.currentUser.branchName,
        customerId: 'cust_2',
        customerCode: 'CUST-002',
        customerName: 'مجموعة السادة الكبرى',
        collectionForecast: 62000,
        salesForecast: 70000,
        status: ForecastStatusType.submitted,
        submittedAt: '${_selectedMonthKey}-01T10:15:00',
      ),
      CollectionForecastRecord(
        id: 'f3',
        monthKey: _selectedMonthKey,
        weekIndex: 0,
        repId: 'rep_2',
        repName: 'أحمد حسن',
        branchName: widget.currentUser.branchName,
        customerId: 'cust_3',
        customerCode: 'CUST-003',
        customerName: 'سوبر ماركت النيل',
        collectionForecast: 28000,
        salesForecast: 32000,
        status: ForecastStatusType.submitted,
        submittedAt: '${_selectedMonthKey}-01T11:00:00',
      ),
    ];
  }

  void _selectMonth() async {
    final now = DateTime.now();
    final initialDate = DateTime.tryParse('${_selectedMonthKey}-01') ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      setState(() {
        _selectedMonthKey = DateFormat('yyyy-MM').format(picked);
        _loadData();
      });
    }
  }

  void _openWeekConfig() async {
    final rbac = RoleAccessController(widget.currentUser);
    if (!rbac.isAdmin && !rbac.isBranchManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('غير مصرح لك بتعديل إعدادات الأسابيع',
            style: GoogleFonts.cairo())),
      );
      return;
    }

    final now = DateTime.now();
    final parsed = DateTime.tryParse('$_selectedMonthKey-01') ?? now;
    final monthStart = DateTime(parsed.year, parsed.month, 1);
    final monthEnd = DateTime(parsed.year, parsed.month + 1, 0);

    final defaultWeeks = ForecastRepository.generateCustomWeeks(
      monthStart: monthStart,
      monthEnd: monthEnd,
      weekStartWeekday: _monthPlan?.weeks?.isNotEmpty == true
          ? _parseWeekStart(_monthPlan!.weeks.first.start)
          : 1,
    );

    showDialog(
      context: context,
      builder: (context) => _WeekConfigDialog(
        monthKey: _selectedMonthKey,
        monthStart: monthStart,
        monthEnd: monthEnd,
        existingWeeks: _monthPlan?.weeks ?? defaultWeeks,
        isAdmin: rbac.isAdmin,
        onSaved: (weeks) async {
          setState(() => _isLoading = true);
          if (_monthPlan == null) {
            final startDateStr = DateFormat('yyyy-MM-dd').format(monthStart);
            final endDateStr = DateFormat('yyyy-MM-dd').format(monthEnd);
            await SupabaseService.instance.createMonthPlan(
              monthKey: _selectedMonthKey,
              year: parsed.year,
              month: parsed.month,
              monthStart: startDateStr,
              monthEnd: endDateStr,
              weeks: weeks,
              createdBy: widget.currentUser.name,
            );
          } else {
            await SupabaseService.instance.updateMonthPlanWeeks(_selectedMonthKey, weeks);
          }
          _loadData();
        },
      ),
    );
  }

  int _parseWeekStart(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 1;
    return date.weekday;
  }

  @override
  Widget build(BuildContext context) {
    final rbac = RoleAccessController(widget.currentUser);
    final canConfigureWeeks = rbac.isAdmin || rbac.isBranchManager;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCollection = _forecasts.fold<double>(0, (s, f) => s + f.collectionForecast);
    final totalSales = _forecasts.fold<double>(0, (s, f) => s + f.salesForecast);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.darkSlate,
        title: Text('توقعات التحصيل',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (canConfigureWeeks)
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              tooltip: 'إعدادات الأسابيع',
              onPressed: _openWeekConfig,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: _selectMonth,
              icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white70),
              label: Text(_selectedMonthKey, style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70)),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<ForecastStatusType>(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: ForecastStatusType.draft, child: Text('مسودة')),
                DropdownMenuItem(value: ForecastStatusType.submitted, child: Text('مرسل')),
                DropdownMenuItem(value: ForecastStatusType.approved, child: Text('موافق عليه')),
                DropdownMenuItem(value: ForecastStatusType.changeRequested, child: Text('مراجعة')),
              ],
              onChanged: (v) {
                setState(() => _selectedStatus = v ?? ForecastStatusType.submitted);
                _loadData();
              },
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
              dropdownColor: isDark ? AppTheme.darkCard : AppTheme.darkSlate,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month plan summary with week configuration
                if (_monthPlan != null)
                  Container(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'خطة الشهر: ${_monthPlan!.monthStart} → ${_monthPlan!.monthEnd}',
                              style: GoogleFonts.cairo(fontSize: 11, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _monthPlan!.isClosed ? AppTheme.infoBlue.withOpacity(0.15) : AppTheme.warningAmber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _monthPlan!.isClosed ? 'مغلق' : 'مفتوح',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _monthPlan!.isClosed ? AppTheme.infoBlue : AppTheme.warningAmber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_monthPlan!.weeks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 6,
                              children: _monthPlan!.weeks.map((week) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${week.label ?? ''}: ${week.start} → ${week.end}',
                                  style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.darkSlate),
                                ),
                              )).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 1),

                // Summary totals
                Container(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            _currencyFmt.format(totalCollection),
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                          ),
                          Text('إجمالي التحصيل', style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: isDark ? AppTheme.darkBorder : AppTheme.borderColor),
                      Column(
                        children: [
                          Text(
                            _currencyFmt.format(totalSales),
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                          ),
                          Text('إجمالي المبيعات', style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Forecast records list
                Expanded(
                  child: _forecasts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.energy_savings_leaf, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('لا توجد توقعات للعرض',
                                  style: GoogleFonts.cairo(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _forecasts.length,
                          itemBuilder: (context, index) {
                            final record = _forecasts[index];
                            return _buildForecastCard(record, isDark);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildForecastCard(CollectionForecastRecord record, bool isDark) {
    final statusColor = _statusColor(record.status);
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    final weekLabel = _monthPlan?.weeks?.isNotEmpty == true &&
            record.weekIndex < _monthPlan!.weeks.length
        ? _monthPlan!.weeks[record.weekIndex].label ??
            'الأسبوع ${record.weekIndex + 1}'
        : 'الأسبوع ${record.weekIndex + 1}';

    return Card(
      color: cardColor,
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
                  backgroundColor: AppTheme.infoBlue.withOpacity(0.15),
                  child: Icon(Icons.person, color: AppTheme.infoBlue, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.customerName,
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${record.customerCode} • ${record.repName}',
                        style: GoogleFonts.cairo(fontSize: 10, color: mutedColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(record.status),
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(weekLabel,
                        style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.infoBlue)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('توقع تحصيل', style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
                    Text(
                      _currencyFmt.format(record.collectionForecast),
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('توقع مبيعات', style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
                    Text(
                      _currencyFmt.format(record.salesForecast),
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    ),
                  ],
                ),
              ],
            ),

            if (record.submittedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'مرسل: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.tryParse(record.submittedAt!) ?? DateTime.now())}',
                  style: GoogleFonts.cairo(fontSize: 10, color: mutedColor),
                ),
              ),
            if (record.approvedBy != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'موافق: ${record.approvedBy}',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.emeraldGreen),
                ),
              ),
            if (record.changeRequestNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'ملاحظة: ${record.changeRequestNote}',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.warningAmber),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(ForecastStatusType status) {
    switch (status) {
      case ForecastStatusType.draft: return 'مسودة';
      case ForecastStatusType.submitted: return 'مرسل';
      case ForecastStatusType.approved: return 'موافق عليه';
      case ForecastStatusType.changeRequested: return 'مراجعة';
    }
  }

  Color _statusColor(ForecastStatusType status) {
    switch (status) {
      case ForecastStatusType.draft: return AppTheme.textMuted;
      case ForecastStatusType.submitted: return AppTheme.infoBlue;
      case ForecastStatusType.approved: return AppTheme.emeraldGreen;
      case ForecastStatusType.changeRequested: return AppTheme.warningAmber;
    }
  }
}

class _WeekConfigDialog extends StatefulWidget {
  final String monthKey;
  final DateTime monthStart;
  final DateTime monthEnd;
  final List<ForecastWeek> existingWeeks;
  final bool isAdmin;
  final void Function(List<ForecastWeek>) onSaved;

  const _WeekConfigDialog({
    required this.monthKey,
    required this.monthStart,
    required this.monthEnd,
    required this.existingWeeks,
    required this.isAdmin,
    required this.onSaved,
  });

  @override
  State<_WeekConfigDialog> createState() => _WeekConfigDialogState();
}

class _WeekConfigDialogState extends State<_WeekConfigDialog> {
  late List<ForecastWeek> _weeks;
  late int _weekStartWeekday;

  @override
  void initState() {
    super.initState();
    _weeks = List.from(widget.existingWeeks);
    if (_weeks.isNotEmpty) {
      final firstWeek = DateTime.tryParse(_weeks.first.start);
      _weekStartWeekday = firstWeek?.weekday ?? 1;
    } else {
      _weekStartWeekday = 1;
    }
  }

  void _regenerateWeeks() {
    setState(() {
      _weeks = ForecastRepository.generateCustomWeeks(
        monthStart: widget.monthStart,
        monthEnd: widget.monthEnd,
        weekStartWeekday: _weekStartWeekday,
      );
    });
  }

  void _save() {
    if (_weeks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب تحديد أسبوع واحد على الأقل',
            style: GoogleFonts.cairo())),
      );
      return;
    }

    widget.onSaved(_weeks);
    Navigator.of(context).pop();
  }

  String _weekdayName(int weekday) {
    const names = [
      '', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'
    ];
    return names[weekday.clamp(1, 7)];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;

    return AlertDialog(
      backgroundColor: cardColor,
      title: Text('إعداد أسابيع ${_weekName(widget.monthKey)}',
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkText : AppTheme.textDark)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Week start selector
            Row(
              children: [
                Text('بداية الأسبوع:',
                    style: GoogleFonts.cairo(fontSize: 12)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _weekStartWeekday,
                  items: List.generate(7, (i) {
                    final wd = i + 1;
                    return DropdownMenuItem(
                      value: wd,
                      child: Text(_weekdayName(wd),
                          style: GoogleFonts.cairo(fontSize: 12)),
                    );
                  }),
                  onChanged: (v) {
                    setState(() {
                      _weekStartWeekday = v ?? 1;
                      _regenerateWeeks();
                    });
                  },
                  style: GoogleFonts.cairo(color: isDark ? AppTheme.darkText : AppTheme.textDark),
                  dropdownColor: cardColor,
                  underline: const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Week list
            Expanded(
              child: ListView.builder(
                itemCount: _weeks.length,
                itemBuilder: (context, index) {
                  final week = _weeks[index];
                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الأسبوع ${week.index}',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: week.start,
                                  decoration: InputDecoration(
                                    labelText: 'بداية الأسبوع',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  style: GoogleFonts.cairo(fontSize: 12),
                                  onTap: () async {
                                    FocusScope.of(context).requestFocus(FocusNode());
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.tryParse(week.start) ?? widget.monthStart,
                                      firstDate: widget.monthStart,
                                      lastDate: widget.monthEnd,
                                      locale: const Locale('ar', 'EG'),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _weeks[index] = ForecastWeek(
                                          index: week.index,
                                          start: DateFormat('yyyy-MM-dd').format(picked),
                                          end: week.end,
                                          label: week.label,
                                        );
                                      });
                                    }
                                  },
                                  onChanged: (v) {
                                    setState(() {
                                      _weeks[index] = ForecastWeek(
                                        index: week.index,
                                        start: v,
                                        end: week.end,
                                        label: week.label,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: week.end,
                                  decoration: InputDecoration(
                                    labelText: 'نهاية الأسبوع',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  style: GoogleFonts.cairo(fontSize: 12),
                                  onTap: () async {
                                    FocusScope.of(context).requestFocus(FocusNode());
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.tryParse(week.end) ?? widget.monthEnd,
                                      firstDate: widget.monthStart,
                                      lastDate: widget.monthEnd,
                                      locale: const Locale('ar', 'EG'),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _weeks[index] = ForecastWeek(
                                          index: week.index,
                                          start: week.start,
                                          end: DateFormat('yyyy-MM-dd').format(picked),
                                          label: week.label,
                                        );
                                      });
                                    }
                                  },
                                  onChanged: (v) {
                                    setState(() {
                                      _weeks[index] = ForecastWeek(
                                        index: week.index,
                                        start: week.start,
                                        end: v,
                                        label: week.label,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        TextButton(
          onPressed: _save,
          child: Text('حفظ',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
        ),
      ],
    );
  }

  String _weekName(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length == 2) {
      const months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      final idx = int.tryParse(parts[1]) ?? 1;
      final monthName = idx >= 1 && idx <= 12 ? months[idx - 1] : '';
      return '$monthName ${parts[0]}';
    }
    return monthKey;
  }
}
