import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

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

  final NumberFormat _currencyFmt = NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);
  final List<String> _quarterOptions = ['ALL', 'Q1', 'Q2', 'Q3', 'Q4'];
  final List<String> _monthOptions = ['ALL', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  final bool isSuperAdmin = false;
  final bool isBranchMgr = false;
  final bool isSupervisor = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);

    final targets = await SupabaseService.instance.fetchTargets(
      branchName: widget.currentUser.branchName,
      year: _selectedYear,
    );
    final customers = await SupabaseService.instance.fetchCustomerAnalytics(
      branchName: widget.currentUser.branchName,
    );

    if (mounted) {
      setState(() {
        _targets = targets.isNotEmpty ? targets : _mockTargets();
        _customers = customers.isNotEmpty ? customers : _mockCustomers();
        _isLoading = false;
      });
    }
  }

  List<TargetRecord> _mockTargets() {
    return [
      TargetRecord(
        id: 't1', branch: 'فرع القاهرة الكبرى', repName: 'محمد على',
        salesTarget: 500000, salesAchieved: 450000, salesPercentage: 90.0,
        collectionTarget: 400000, collectionAchieved: 380000, collectionPercentage: 95.0,
        date: '2026-10-01', month: 10, year: 2026, quarter: 'Q4',
        remainingSales: 50000, remainingCollection: 20000,
      ),
      TargetRecord(
        id: 't2', branch: 'فرع القاهرة الكبرى', repName: 'أحمد حسن',
        salesTarget: 450000, salesAchieved: 380000, salesPercentage: 84.4,
        collectionTarget: 380000, collectionAchieved: 350000, collectionPercentage: 92.1,
        date: '2026-10-01', month: 10, year: 2026, quarter: 'Q4',
        remainingSales: 70000, remainingCollection: 30000,
      ),
    ];
  }

  List<CustomerAnalytics> _mockCustomers() {
    return [
      CustomerAnalytics(
        customerId: 'c1', customerName: 'مخازن البتروز', customerCode: 'CUST-001',
        branchName: widget.currentUser.branchName,
        totalSales: 125000, totalCollections: 110000, balance: 15000,
        overdueBalance: 5000, ordersCount: 12, visitsCount: 8, returnsCount: 1,
        lastOrderDate: '2026-10-15', lastVisitDate: '2026-10-14', tier: 'الذهب', hasDealtIn2026: true,
      ),
      CustomerAnalytics(
        customerId: 'c2', customerName: 'مجموعة السادة الكبرى', customerCode: 'CUST-002',
        branchName: widget.currentUser.branchName,
        totalSales: 85000, totalCollections: 85000, balance: 0,
        overdueBalance: 0, ordersCount: 8, visitsCount: 6, returnsCount: 0,
        lastOrderDate: '2026-10-10', lastVisitDate: '2026-10-09', tier: 'الفضة', hasDealtIn2026: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final salesTarget = _targets.fold<double>(0, (s, t) => s + t.salesTarget);
    final salesAchieved = _targets.fold<double>(0, (s, t) => s + t.salesAchieved);
    final salesRate = salesTarget > 0 ? (salesAchieved / salesTarget) * 100 : 0;
    final collectionTarget = _targets.fold<double>(0, (s, t) => s + t.collectionTarget);
    final collectionAchieved = _targets.fold<double>(0, (s, t) => s + t.collectionAchieved);
    final collectionRate = collectionTarget > 0 ? (collectionAchieved / collectionTarget) * 100 : 0;
    final totalDues = _customers.fold<double>(0, (s, c) => c.balance > 0 ? s + c.balance : s);
    final customersWithDues = _customers.where((c) => c.balance > 0).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('لوحة الإدارة والتحليل',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          DropdownButton<int>(
            value: _selectedYear,
            items: [2026, 2025, 2024].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
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
                    Text('ملخص التنفيذي', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildKPICard('مبيعات', _currencyFmt.format(salesAchieved), '${salesRate.toStringAsFixed(1)}%', salesRate, salesTarget, salesAchieved),
                        _buildKPICard('تحصيل', _currencyFmt.format(collectionAchieved), '${collectionRate.toStringAsFixed(1)}%', collectionRate, collectionTarget, collectionAchieved),
                        _buildKPICard('مستحقات', _currencyFmt.format(totalDues), '$customersWithDues عميل', 0, 0, 0, isCurrency: false),
                        _buildKPICard('مناديب', '${_targets.length} مندوب', 'فعّال', 0, 0, 0, isCurrency: false),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text('إنجاز المناديب', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
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

                    Text('العملاء ذوو المستحقات', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customers.where((c) => c.balance > 0).length,
                      itemBuilder: (context, index) {
                        final customer = _customers.where((c) => c.balance > 0).toList()[index];
                        return _buildCustomerRow(customer);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPICard(String label, String value, String subLabel, double rate, double target, double achieved, {bool isCurrency = true}) {
    final color = rate >= 90 ? AppTheme.emeraldGreen : rate >= 80 ? AppTheme.warningAmber : AppTheme.errorRed;
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
            Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkSlate)),
            if (subLabel.isNotEmpty)
              Text(subLabel, style: GoogleFonts.cairo(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRepRow(TargetRecord target) {
    final rate = target.salesPercentage;
    final color = rate >= 100 ? AppTheme.emeraldGreen : rate >= 80 ? AppTheme.warningAmber : AppTheme.errorRed;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.person, color: color, size: 18),
        ),
        title: Text(target.repName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${target.branch} • ${target.quarter}',
                style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${rate.toStringAsFixed(1)}%', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            Text('${_currencyFmt.format(target.salesAchieved)}/${_currencyFmt.format(target.salesTarget)}',
                style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerRow(CustomerAnalytics customer) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.infoBlue,
          child: Icon(Icons.storefront_outlined, color: Colors.white, size: 16),
        ),
        title: Text(customer.customerName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
        subtitle: Text('${customer.customerCode} • ${customer.tier ?? ''}',
            style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
        trailing: Text(
          '${_currencyFmt.format(customer.balance)}',
          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: customer.overdueBalance > 0 ? AppTheme.errorRed : AppTheme.emeraldGreen),
        ),
      ),
    );
  }
}
