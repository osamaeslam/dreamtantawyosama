import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final totalCollection = _forecasts.fold<double>(0, (s, f) => s + f.collectionForecast);
    final totalSales = _forecasts.fold<double>(0, (s, f) => s + f.salesForecast);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('توقعات التحصيل',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
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
              dropdownColor: AppTheme.darkSlate,
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
                // Month plan summary
                if (_monthPlan != null)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'خطة الشهر: ${_monthPlan!.monthStart} → ${_monthPlan!.monthEnd}',
                          style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
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
                  ),
                const Divider(height: 1),

                // Summary totals
                Container(
                  color: Colors.white,
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
                          Text('إجمالي التحصيل', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: AppTheme.borderColor),
                      Column(
                        children: [
                          Text(
                            _currencyFmt.format(totalSales),
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                          ),
                          Text('إجمالي المبيعات', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
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
                              const Icon(Icons.energy_saver, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('لا توجد توقعات للعرض',
                                  style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _forecasts.length,
                          itemBuilder: (context, index) {
                            final record = _forecasts[index];
                            return _buildForecastCard(record);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildForecastCard(CollectionForecastRecord record) {
    final statusColor = _statusColor(record.status);

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
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${record.customerCode} • ${record.repName}',
                        style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('توقع تحصيل', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
                    Text(
                      _currencyFmt.format(record.collectionForecast),
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('توقع مبيعات', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
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
                  style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
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
