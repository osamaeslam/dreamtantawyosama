import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class RoleDashboardSummary extends StatefulWidget {
  final AppUser currentUser;

  const RoleDashboardSummary({super.key, required this.currentUser});

  @override
  State<RoleDashboardSummary> createState() => _RoleDashboardSummaryState();
}

class _RoleDashboardSummaryState extends State<RoleDashboardSummary> {
  late DateTime _fromDate;
  late DateTime _toDate;
  List<OrderInvoice> _invoices = [];
  List<CustomerVisit> _visits = [];
  List<TargetRecord> _targets = [];
  List<CustomerAnalytics> _customers = [];
  List<ParentProduct> _products = [];
  bool _isLoading = true;
  String? _error;

  RoleAccessController get _rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _fromDate = DateTime(today.year, today.month);
    _toDate = DateTime(today.year, today.month, today.day);
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final service = SupabaseService.instance;
    final repName = _rbac.isSalesRep ? widget.currentUser.name : null;
    final branchName = _rbac.isAdmin ? null : widget.currentUser.branchName;
    final endDateExclusive =
        DateTime(_toDate.year, _toDate.month, _toDate.day + 1);

    List<OrderInvoice> invoices = [];
    List<CustomerVisit> visits = [];
    List<TargetRecord> targets = [];
    List<CustomerAnalytics> customers = [];
    List<ParentProduct> products = [];

    try {
      await Future.wait([
        () async {
          invoices = await service.fetchInvoices(
            repName: repName,
            branchName: branchName,
            startDate: _fromDate,
            endDateExclusive: endDateExclusive,
          );
        }(),
        () async {
          visits = await service.fetchVisits(
            repName: repName,
            branchName: branchName,
            startDate: _fromDate,
            endDateExclusive: endDateExclusive,
          );
        }(),
        () async {
          final yearResults = await Future.wait(
            List.generate(
              _toDate.year - _fromDate.year + 1,
              (index) => service.fetchTargets(
                repName: repName,
                branchName: branchName,
                year: _fromDate.year + index,
              ),
            ),
          );
          targets = yearResults.expand((year) => year).toList();
        }(),
        () async {
          customers = await service.fetchCustomerAnalytics(
            branchName: branchName,
            repName: repName,
          );
        }(),
        () async {
          products = await service.fetchParentProducts(
            branchName: branchName,
          );
        }(),
      ]);

      if (!mounted) return;
      setState(() {
        _invoices = _rbac.filterInvoices(invoices).where((invoice) {
          return _isInRange(invoice.date);
        }).toList();
        _visits = _rbac.filterVisits(visits).where((visit) {
          return _isInRange(visit.date);
        }).toList();
        _targets = _rbac.filterTargets(targets).where((target) {
          if (target.month < 1 ||
              target.month > 12 ||
              target.year < 1) {
            return false;
          }
          final monthStart = DateTime(target.year, target.month);
          final monthEnd = DateTime(target.year, target.month + 1);
          return monthStart.isBefore(endDateExclusive) &&
              monthEnd.isAfter(_fromDate);
        }).toList();
        _customers = _rbac.filterCustomers(customers);
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل ملخص الأداء: $e';
        _isLoading = false;
      });
    }
  }

  bool _isInRange(DateTime date) {
    final start = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    final end = DateTime(_toDate.year, _toDate.month, _toDate.day + 1);
    return !date.isBefore(start) && date.isBefore(end);
  }

  Future<void> _chooseDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      helpText: 'حدد فترة التقرير',
      saveText: 'عرض',
    );
    if (range == null || !mounted) return;
    setState(() {
      _fromDate = DateTime(range.start.year, range.start.month, range.start.day);
      _toDate = DateTime(range.end.year, range.end.month, range.end.day);
    });
    await _loadData();
  }

  double get _salesTotal => _invoices
      .where((invoice) => !_isCancelledInvoice(invoice))
      .fold(0.0, (sum, invoice) => sum + invoice.totalAmount);

  double get _collectionTotal =>
      _visits.fold(0.0, (sum, visit) => sum + visit.collectedAmount);

  double get _salesTarget => _targets.fold<double>(
        0,
        (sum, target) => sum + _targetForSelectedDays(target.salesTarget, target),
      );

  double get _collectionTarget => _targets.fold<double>(
        0,
        (sum, target) =>
            sum + _targetForSelectedDays(target.collectionTarget, target),
      );

  bool _isCancelledInvoice(OrderInvoice invoice) {
    final status = invoice.status.toLowerCase();
    return status.contains('إلغاء') ||
        status.contains('ملغ') ||
        status.contains('مرفوض') ||
        status.contains('رفض') ||
        status.contains('cancel') ||
        status.contains('reject');
  }

  double _targetForSelectedDays(double monthlyTarget, TargetRecord target) {
    final monthStart = DateTime(target.year, target.month);
    final monthEnd = DateTime(target.year, target.month + 1);
    final effectiveStart =
        _fromDate.isAfter(monthStart) ? _fromDate : monthStart;
    final exclusiveEnd = DateTime(_toDate.year, _toDate.month, _toDate.day + 1);
    final effectiveEnd = exclusiveEnd.isBefore(monthEnd) ? exclusiveEnd : monthEnd;
    final daysInRange = _calendarDaysBetween(effectiveStart, effectiveEnd);
    final daysInMonth = _calendarDaysBetween(monthStart, monthEnd);
    if (daysInRange <= 0 || daysInMonth <= 0) return 0;
    return monthlyTarget * daysInRange / daysInMonth;
  }

  int _calendarDaysBetween(DateTime start, DateTime end) {
    return DateTime.utc(end.year, end.month, end.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
  }

  int get _pendingInvoiceCount => _invoices.where((invoice) {
        final status = invoice.status.toLowerCase();
        return status.contains('مراجعة') ||
            status.contains('معلق') ||
            status.contains('جديد') ||
            status.contains('review') ||
            status.contains('pending');
      }).length;

  double get _currentDebt => _customers.fold<double>(
        0,
        (sum, customer) => sum + (customer.balance > 0 ? customer.balance : 0),
      );

  int get _customersWithDebt =>
      _customers.where((customer) => customer.balance > 0).length;

  List<CustomerAnalytics> get _topDebtors {
    final debtors = _customers.where((customer) => customer.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    return debtors.take(3).toList();
  }

  int get _transferCandidates => _products.fold<int>(0, (sum, product) {
        if (product.variants.isEmpty) {
          return sum +
              (product.totalBranchStock == 0 && product.totalOctoberStock > 0
                  ? 1
                  : 0);
        }
        return sum +
            product.variants
                .where((variant) =>
                    variant.availableStock == 0 &&
                    variant.octoberAvailableStock > 0)
                .length;
      });

  int get _outOfStockCount => _products.fold<int>(0, (sum, product) {
        if (product.variants.isEmpty) {
          return sum + (product.totalBranchStock <= 0 ? 1 : 0);
        }
        return sum +
            product.variants
                .where((variant) => variant.availableStock <= 0)
                .length;
      });

  String get _salesLabel {
    if (_rbac.isSalesRep) return 'قيمة فواتيري';
    if (_rbac.isSupervisor) return 'قيمة فواتير الفريق';
    if (_rbac.isBranchManager) return 'قيمة فواتير الفرع';
    return 'قيمة الفواتير';
  }

  String get _collectionLabel {
    if (_rbac.isSalesRep) return 'تحصيلاتي';
    if (_rbac.isSupervisor) return 'تحصيل الفريق';
    if (_rbac.isBranchManager) return 'تحصيل الفرع';
    return 'تحصيل الزيارات';
  }

  String get _dashboardTitle {
    if (_rbac.isSalesRep) return 'لوحة المندوب';
    if (_rbac.isSupervisor) return 'لوحة المشرف';
    if (_rbac.isBranchManager) return 'لوحة مدير الفرع';
    return 'لوحة الإدارة';
  }

  List<MapEntry<String, double>> get _repSales {
    final totals = <String, double>{};
    for (final invoice in _invoices) {
      if (_isCancelledInvoice(invoice)) {
        continue;
      }
      totals.update(
        invoice.repName,
        (value) => value + invoice.totalAmount,
        ifAbsent: () => invoice.totalAmount,
      );
    }
    return totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);
    final dateFormat = DateFormat('yyyy/MM/dd');
    final salesProgress = _salesTarget > 0
        ? (_salesTotal / _salesTarget).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final collectionProgress = _collectionTarget > 0
        ? (_collectionTotal / _collectionTarget)
            .clamp(0.0, 1.0)
            .toDouble()
        : 0.0;
    final isTeamRole =
        _rbac.isAdmin || _rbac.isSupervisor || _rbac.isBranchManager;
    final hasData = _invoices.isNotEmpty ||
        _visits.isNotEmpty ||
        _targets.isNotEmpty ||
        _customers.isNotEmpty ||
        _products.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dashboardTitle,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${dateFormat.format(_fromDate)} — ${dateFormat.format(_toDate)}',
                        style: GoogleFonts.cairo(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'تغيير فترة التقرير',
                  onPressed: _isLoading ? null : _chooseDateRange,
                  icon: const Icon(Icons.date_range_rounded),
                ),
                IconButton(
                  tooltip: 'تحديث البيانات',
                  onPressed: _isLoading ? null : _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 3)
            else if (_error != null)
              _messagePanel(_error!, isError: true)
            else if (!hasData)
              _messagePanel('لا توجد بيانات مسجلة للفترة المحددة.')
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 850
                      ? 4
                      : constraints.maxWidth > 520
                          ? 3
                          : 2;
                  final width =
                      (constraints.maxWidth - (columns - 1) * 10) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _metricCard(
                        width: width,
                        title: _salesLabel,
                        value: currency.format(_salesTotal),
                        subtitle: _salesTarget > 0
                            ? 'من هدف الفترة ${currency.format(_salesTarget)}'
                            : '${_invoices.length} فاتورة',
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.infoBlue,
                        progress: _salesTarget > 0 ? salesProgress : null,
                      ),
                      _metricCard(
                        width: width,
                        title: _collectionLabel,
                        value: currency.format(_collectionTotal),
                        subtitle: _collectionTarget > 0
                            ? 'من هدف الفترة ${currency.format(_collectionTarget)}'
                            : '${_visits.length} زيارة',
                        icon: Icons.payments_outlined,
                        color: AppTheme.emeraldGreen,
                        progress:
                            _collectionTarget > 0 ? collectionProgress : null,
                      ),
                      _metricCard(
                        width: width,
                        title: 'الزيارات',
                        value: _visits.length.toString(),
                        subtitle: '${_visits.where((v) => v.latitude != null).length} بموقع مسجل',
                        icon: Icons.location_on_outlined,
                        color: AppTheme.warningAmber,
                      ),
                      _metricCard(
                        width: width,
                        title: 'الفواتير قيد المتابعة',
                        value: _pendingInvoiceCount.toString(),
                        subtitle: 'من ${_invoices.length} فاتورة',
                        icon: Icons.receipt_long_outlined,
                        color: AppTheme.roseRed,
                      ),
                      _metricCard(
                        width: width,
                        title: 'مديونية العملاء الحالية',
                        value: currency.format(_currentDebt),
                        subtitle: 'الرصيد الحالي • $_customersWithDebt عميل',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppTheme.primaryGold,
                      ),
                      _metricCard(
                        width: width,
                        title: _rbac.isAdmin
                            ? 'أصناف بلا رصيد في الفروع'
                            : 'أصناف نفد رصيدها بالفرع',
                        value: _outOfStockCount.toString(),
                        subtitle: 'حسب الأرصدة المتاحة الآن',
                        icon: Icons.inventory_2_outlined,
                        color: AppTheme.roseRed,
                      ),
                      _metricCard(
                        width: width,
                        title: 'مرشحة للتوريد',
                        value: _transferCandidates.toString(),
                        subtitle: 'أرصدة حالية متاحة في أكتوبر',
                        icon: Icons.local_shipping_outlined,
                        color: AppTheme.infoBlue,
                      ),
                    ],
                  );
                },
              ),
              if (isTeamRole && _repSales.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'أعلى المندوبين مبيعًا في الفترة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                ..._repSales.take(3).toList().asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final rep = entry.value;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: AppTheme.darkSlate,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      rep.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                    trailing: Text(
                      currency.format(rep.value),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
              if (_topDebtors.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'أعلى أرصدة العملاء الحالية',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                ..._topDebtors.map((customer) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.person_outline_rounded,
                        color: AppTheme.warningAmber,
                      ),
                      title: Text(
                        customer.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(fontSize: 12),
                      ),
                      subtitle: Text(
                        customer.overdueBalance > 0
                            ? 'متأخر: ${currency.format(customer.overdueBalance)}'
                            : 'رصيد مستحق',
                        style: GoogleFonts.cairo(fontSize: 10),
                      ),
                      trailing: Text(
                        currency.format(customer.balance),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: color.withOpacity(0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _messagePanel(String message, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? AppTheme.errorRed : AppTheme.infoBlue)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.cairo(
          fontSize: 12,
          color: isError ? AppTheme.errorRed : null,
        ),
      ),
    );
  }
}
