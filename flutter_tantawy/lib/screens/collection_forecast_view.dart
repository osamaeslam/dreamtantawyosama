import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../services/repositories/forecast_repository.dart';
import '../services/role_access_controller.dart';
import '../theme/app_theme.dart';
import 'visits_dashboard_screen.dart';
import 'returns_screen.dart';

class CollectionForecastView extends StatefulWidget {
  final AppUser currentUser;
  final String? monthKey;
  const CollectionForecastView({super.key, required this.currentUser, this.monthKey});

  @override
  State<CollectionForecastView> createState() => _CollectionForecastViewState();
}

class _CollectionForecastViewState extends State<CollectionForecastView> {
  List<CollectionForecastRecord> _forecasts = [];
  List<CollectionForecastRecord> _allForecasts = [];
  List<Customer> _customers = [];
  List<AppUser> _representatives = [];
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

  Future<void> _openForecastForm() async {
    if (_customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد عملاء مسندون للمندوب', style: GoogleFonts.cairo())),
      );
      return;
    }
    final entry = await showDialog<_ForecastEntryData>(
      context: context,
      builder: (context) => _ForecastEntryDialog(
        customers: _customers,
        weeks: _monthPlan?.weeks ?? const [],
      ),
    );
    if (entry == null || !mounted) return;

    final now = DateTime.now().toIso8601String();
    final rep = widget.currentUser;
    final record = CollectionForecastRecord(
      id: 'forecast_${rep.id}_${entry.customer.id}_${_selectedMonthKey}_${entry.weekIndex}',
      monthKey: _selectedMonthKey,
      weekIndex: entry.weekIndex,
      repId: rep.id,
      repName: rep.name,
      branchName: rep.branchName,
      supervisorId: rep.supervisorId,
      customerId: entry.customer.id,
      customerCode: entry.customer.code,
      customerName: entry.customer.name,
      collectionForecast: entry.collectionAmount,
      salesForecast: entry.salesAmount,
      repCollectionForecast: entry.collectionAmount,
      repSalesForecast: entry.salesAmount,
      status: ForecastStatusType.submitted,
      collectionMethod: entry.collectionMethod,
      returnExpected: entry.returnExpected,
      returnExpectedAmount: entry.returnAmount,
      submittedAt: now,
      approvalStage: rep.supervisorId != null || rep.supervisorName != null
          ? 'pending_supervisor'
          : 'pending_branch_manager',
      returnStatus: entry.returnExpected || entry.collectionAmount == 0
          ? 'pending_review'
          : 'none',
    );
    final success = await SupabaseService.instance.submitForecast(
      record,
      hasSupervisor: rep.supervisorId != null || rep.supervisorName != null,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'تم إرسال التوقع للمراجعة' : 'تعذر حفظ التوقع على الخادم',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: success ? AppTheme.emeraldGreen : AppTheme.errorRed,
      ),
    );
    if (success) await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rbac = RoleAccessController(widget.currentUser);
    try {
      final monthPlan = await SupabaseService.instance.fetchForecastMonthPlan(_selectedMonthKey);
      final forecasts = await SupabaseService.instance.fetchForecasts(monthKey: _selectedMonthKey);
      final customers = await SupabaseService.instance.fetchCustomers(
        repName: rbac.isSalesRep ? widget.currentUser.name : null,
        branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
      );
      final representatives = await SupabaseService.instance.fetchUsers(
        branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
        role: 'sales_rep',
      );
      if (!mounted) return;
      setState(() {
        _monthPlan = monthPlan;
        _customers = rbac.filterCustomerAccounts(customers);
        _representatives = representatives;
        _allForecasts = rbac.filterForecasts(forecasts);
        _forecasts = _allForecasts
            .where((forecast) => forecast.status == _selectedStatus)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _monthPlan = null;
        _customers = [];
        _allForecasts = [];
        _forecasts = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل التوقعات: $e', style: GoogleFonts.cairo())),
      );
    }
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
    final approvedForecasts = _allForecasts
      .where((forecast) => forecast.approvalStage == 'approved')
      .toList();
    final totalCollection = approvedForecasts.fold<double>(0, (sum, forecast) => sum + forecast.collectionForecast);
    final totalSales = approvedForecasts.fold<double>(0, (sum, forecast) => sum + forecast.salesForecast);
    final totalCheques = approvedForecasts
      .where((forecast) => forecast.collectionMethod == 'cheque')
      .fold<double>(0, (sum, forecast) => sum + forecast.collectionForecast);
    final openReturns = _allForecasts.where((forecast) => forecast.returnStatus == 'pending_review').toList();
    final totalReturnAmount = openReturns.fold<double>(0, (sum, forecast) => sum + forecast.returnExpectedAmount);

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
                                color: _monthPlan!.isClosed ? AppTheme.infoBlue.withValues(alpha: 0.15) : AppTheme.warningAmber.withValues(alpha: 0.15),
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
                                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSummaryMetric('الشيكات', totalCheques, AppTheme.warningAmber),
                      _buildSummaryMetric('مرتجعات معلقة (${openReturns.length})', totalReturnAmount, AppTheme.errorRed),
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
      floatingActionButton: rbac.isSalesRep
          ? FloatingActionButton.extended(
              onPressed: _openForecastForm,
              icon: const Icon(Icons.add),
              label: Text('إضافة توقع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.darkSlate,
            )
          : null,
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
                  backgroundColor: AppTheme.infoBlue.withValues(alpha: 0.15),
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
                        color: statusColor.withValues(alpha: 0.15),
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
            if (record.approvalStage != 'approved')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _approvalStageLabel(record.approvalStage),
                  style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.infoBlue),
                ),
              ),
            if (record.collectionMethod == 'cheque')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('متوقع بشيك', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.warningAmber)),
              ),
            if (record.returnExpected || record.collectionForecast == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'حالة المرتجع: ${_returnStatusLabel(record.returnStatus)}',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.errorRed),
                ),
              ),
            if (record.legalReferralStatus != 'none')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'الشؤون القانونية: ${record.legalReferralNote ?? 'تمت الإحالة'}',
                  style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.errorRed),
                ),
              ),
            _buildForecastActions(record),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 11, color: color)),
          const SizedBox(width: 8),
          Text(_currencyFmt.format(amount),
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _approvalStageLabel(String stage) {
    switch (stage) {
      case 'pending_supervisor':
        return 'بانتظار اعتماد المشرف';
      case 'pending_branch_manager':
        return 'بانتظار اعتماد مدير الفرع';
      case 'rep_changes_required':
        return 'مطلوب تعديل المندوب';
      default:
        return 'توقع مقدم';
    }
  }

  String _returnStatusLabel(String status) {
    switch (status) {
      case 'pending_review':
        return 'قيد الإفادة';
      case 'received':
        return 'تم استلام المرتجع';
      case 'no_return':
        return 'لا يوجد مرتجع';
      default:
        return 'لا يوجد';
    }
  }

  Widget _buildForecastActions(CollectionForecastRecord record) {
    final rbac = RoleAccessController(widget.currentUser);
    final canReview = rbac.isAdmin || rbac.isSupervisor || rbac.isBranchManager;
    final canApproveAsSupervisor = (rbac.isSupervisor || rbac.isAdmin) &&
        record.approvalStage == 'pending_supervisor';
    final canApproveAsManager = (rbac.isBranchManager || rbac.isAdmin) &&
        record.approvalStage == 'pending_branch_manager';
    final canSchedule = (rbac.isSupervisor || rbac.isBranchManager || rbac.isAdmin) &&
        record.approvalStage == 'approved' && record.scheduledVisitId == null;
    final hasActions = canApproveAsSupervisor || canApproveAsManager ||
        (canReview && record.approvalStage.startsWith('pending_')) ||
        (canReview && record.returnStatus == 'pending_review') ||
        record.legalReferralStatus == 'none' || canSchedule;
    if (!hasActions) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (canApproveAsSupervisor)
            OutlinedButton.icon(
              onPressed: () => _reviewForecast(record, supervisor: true),
              icon: const Icon(Icons.fact_check_outlined, size: 16),
              label: Text('اعتماد المشرف', style: GoogleFonts.cairo(fontSize: 10)),
            ),
          if (canApproveAsManager)
            FilledButton.tonalIcon(
              onPressed: () => _reviewForecast(record, supervisor: false),
              icon: const Icon(Icons.verified_outlined, size: 16),
              label: Text('اعتماد نهائي', style: GoogleFonts.cairo(fontSize: 10)),
            ),
          if (canReview && record.approvalStage.startsWith('pending_'))
            TextButton.icon(
              onPressed: () => _requestForecastChanges(record),
              icon: const Icon(Icons.edit_note, size: 16),
              label: Text('طلب تعديل', style: GoogleFonts.cairo(fontSize: 10)),
            ),
          if (canReview && record.returnStatus == 'pending_review')
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ReturnsScreen(currentUser: widget.currentUser),
              )),
              icon: const Icon(Icons.assignment_return_outlined, size: 16, color: AppTheme.errorRed),
              label: Text('متابعة المرتجع', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.errorRed)),
            ),
          if (record.legalReferralStatus == 'none')
            TextButton.icon(
              onPressed: () => _referToLegal(record),
              icon: const Icon(Icons.gavel_outlined, size: 16, color: AppTheme.errorRed),
              label: Text('إحالة قانونية', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.errorRed)),
            ),
          if (canSchedule)
            TextButton.icon(
              onPressed: () => _scheduleCustomerVisit(record),
              icon: const Icon(Icons.event_available_outlined, size: 16),
              label: Text('جدولة زيارة', style: GoogleFonts.cairo(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Future<void> _reviewForecast(
    CollectionForecastRecord record, {
    required bool supervisor,
  }) async {
    final collectionController = TextEditingController(text: record.collectionForecast.toStringAsFixed(0));
    final salesController = TextEditingController(text: record.salesForecast.toStringAsFixed(0));
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supervisor ? 'مراجعة المشرف' : 'اعتماد مدير الفرع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: collectionController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'المبلغ المتوقع للتحصيل', labelStyle: GoogleFonts.cairo()),
            ),
            TextField(
              controller: salesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'المبلغ المتوقع للمبيعات', labelStyle: GoogleFonts.cairo()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('رجوع', style: GoogleFonts.cairo())),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('اعتماد', style: GoogleFonts.cairo())),
        ],
      ),
    );
    if (approved != true || !mounted) return;

    final collection = double.tryParse(collectionController.text.trim());
    final sales = double.tryParse(salesController.text.trim());
    collectionController.dispose();
    salesController.dispose();
    final success = supervisor
        ? await SupabaseService.instance.approveForecastBySupervisor(
            forecastId: record.id,
            supervisorName: widget.currentUser.name,
            collectionForecast: collection,
            salesForecast: sales,
          )
        : await SupabaseService.instance.approveForecastByBranchManager(
            forecastId: record.id,
            managerName: widget.currentUser.name,
            collectionForecast: collection,
            salesForecast: sales,
          );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'تم تسجيل الاعتماد' : 'تعذر الاعتماد: راجع صلاحية المرحلة أو الاتصال', style: GoogleFonts.cairo()),
    ));
    if (success) await _loadData();
  }

  Future<void> _requestForecastChanges(CollectionForecastRecord record) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سبب طلب التعديل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(labelText: 'اكتب المطلوب تعديله', labelStyle: GoogleFonts.cairo()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo())),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('إرسال', style: GoogleFonts.cairo())),
        ],
      ),
    );
    controller.dispose();
    if (note == null || note.isEmpty || !mounted) return;
    final success = await SupabaseService.instance.requestForecastChanges(
      forecastId: record.id,
      reviewerName: widget.currentUser.name,
      note: note,
      currentStage: record.approvalStage,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'تم إرسال طلب التعديل للمندوب' : 'تعذر تسجيل طلب التعديل', style: GoogleFonts.cairo()),
    ));
    if (success) await _loadData();
  }

  Future<void> _referToLegal(CollectionForecastRecord record) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إحالة العميل للشؤون القانونية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(labelText: 'سبب الإحالة', labelStyle: GoogleFonts.cairo()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo())),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text('إحالة', style: GoogleFonts.cairo())),
        ],
      ),
    );
    controller.dispose();
    if (note == null || note.isEmpty || !mounted) return;
    final success = await SupabaseService.instance.updateForecastLegalReferral(
      forecastId: record.id,
      status: 'referred',
      handledBy: widget.currentUser.name,
      note: note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'تم تسجيل الإحالة القانونية' : 'تعذر تسجيل الإحالة', style: GoogleFonts.cairo()),
    ));
    if (success) await _loadData();
  }

  Future<void> _scheduleCustomerVisit(CollectionForecastRecord record) async {
    final customer = _customers.where((item) => item.code == record.customerCode || item.id == record.customerId).firstOrNull;
    final representative = _representatives.where((item) =>
        item.id == record.repId || item.name == record.repName).firstOrNull;
    if (customer == null || representative == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحديد العميل أو المندوب من قاعدة البيانات', style: GoogleFonts.cairo())),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'EG'),
    );
    if (picked == null || !mounted) return;
    final visitId = await SupabaseService.instance.scheduleVisit(
      customer: customer,
      representative: representative,
      scheduledAt: picked,
      scheduledBy: widget.currentUser.name,
      forecastId: record.id,
    );
    if (visitId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ الزيارة المجدولة', style: GoogleFonts.cairo())),
      );
      return;
    }
    final linked = await SupabaseService.instance.linkForecastScheduledVisit(
      forecastId: record.id,
      visitId: visitId,
      visitDate: DateFormat('yyyy-MM-dd').format(picked),
      scheduledBy: widget.currentUser.name,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        linked ? 'تمت جدولة الزيارة وربطها بالتوقع' : 'تم حفظ الزيارة لكن تعذر ربطها بالتوقع',
        style: GoogleFonts.cairo(),
      ),
    ));
    if (linked) await _loadData();
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

class _ForecastEntryData {
  final Customer customer;
  final int weekIndex;
  final double collectionAmount;
  final double salesAmount;
  final String collectionMethod;
  final bool returnExpected;
  final double returnAmount;

  const _ForecastEntryData({
    required this.customer,
    required this.weekIndex,
    required this.collectionAmount,
    required this.salesAmount,
    required this.collectionMethod,
    required this.returnExpected,
    required this.returnAmount,
  });
}

class _ForecastEntryDialog extends StatefulWidget {
  final List<Customer> customers;
  final List<ForecastWeek> weeks;

  const _ForecastEntryDialog({required this.customers, required this.weeks});

  @override
  State<_ForecastEntryDialog> createState() => _ForecastEntryDialogState();
}

class _ForecastEntryDialogState extends State<_ForecastEntryDialog> {
  late Customer _customer = widget.customers.first;
  int _weekIndex = 0;
  String _collectionMethod = 'cash';
  bool _returnExpected = false;
  final _collectionController = TextEditingController();
  final _salesController = TextEditingController();
  final _returnController = TextEditingController();

  @override
  void dispose() {
    _collectionController.dispose();
    _salesController.dispose();
    _returnController.dispose();
    super.dispose();
  }

  double _amount(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final weeks = widget.weeks;
    final balance = _customer.balance ?? _customer.currentBalance;
    final guarantee = _customer.guaranteeAmount ?? 0;

    return AlertDialog(
      title: Text('توقع تحصيل العميل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Customer>(
                initialValue: _customer,
                decoration: InputDecoration(
                  labelText: 'العميل',
                  labelStyle: GoogleFonts.cairo(),
                  border: const OutlineInputBorder(),
                ),
                items: widget.customers.map((customer) => DropdownMenuItem(
                  value: customer,
                  child: Text('${customer.name} • ${customer.code}',
                      overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 12)),
                )).toList(),
                onChanged: (customer) {
                  if (customer != null) setState(() => _customer = customer);
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(label: Text('المديونية ${balance.toStringAsFixed(0)} ج.م')),
                  Chip(label: Text('الحد الائتماني ${_customer.creditLimit.toStringAsFixed(0)} ج.م')),
                  Chip(label: Text('الضمان ${guarantee.toStringAsFixed(0)} ج.م')),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _weekIndex,
                decoration: InputDecoration(
                  labelText: 'الفترة',
                  labelStyle: GoogleFonts.cairo(),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('الشهر بالكامل')),
                  ...weeks.asMap().entries.map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value.label ?? 'الأسبوع ${entry.key + 1}'),
                  )),
                ],
                onChanged: (value) => setState(() => _weekIndex = value ?? 0),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _salesController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'متوقع المبيعات',
                  suffixText: 'ج.م',
                  labelStyle: GoogleFonts.cairo(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _collectionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'متوقع التحصيل',
                  suffixText: 'ج.م',
                  labelStyle: GoogleFonts.cairo(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'cash', label: Text('نقدي')),
                  ButtonSegment(value: 'cheque', label: Text('شيك')),
                ],
                selected: {_collectionMethod},
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(
                    _collectionMethod == 'cheque' ? AppTheme.warningAmber : AppTheme.darkSlate,
                  ),
                ),
                onSelectionChanged: (value) => setState(() => _collectionMethod = value.first),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _returnExpected,
                title: Text('يوجد مرتجع متوقع', style: GoogleFonts.cairo(fontSize: 12)),
                activeColor: AppTheme.errorRed,
                onChanged: (value) => setState(() => _returnExpected = value ?? false),
              ),
              if (_returnExpected)
                TextField(
                  controller: _returnController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'قيمة المرتجع المتوقعة',
                    suffixText: 'ج.م',
                    labelStyle: GoogleFonts.cairo(),
                    border: const OutlineInputBorder(),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo())),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ForecastEntryData(
              customer: _customer,
              weekIndex: _weekIndex,
              collectionAmount: _amount(_collectionController),
              salesAmount: _amount(_salesController),
              collectionMethod: _collectionMethod,
              returnExpected: _returnExpected,
              returnAmount: _amount(_returnController),
            ),
          ),
          child: Text('إرسال للمشرف', style: GoogleFonts.cairo()),
        ),
      ],
    );
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


