import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class AllCustomersAnalyticsView extends StatefulWidget {
  final AppUser currentUser;
  const AllCustomersAnalyticsView({super.key, required this.currentUser});

  @override
  State<AllCustomersAnalyticsView> createState() => _AllCustomersAnalyticsViewState();
}

class _AllCustomersAnalyticsViewState extends State<AllCustomersAnalyticsView> {
  List<CustomerAnalytics> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTier = 'الكل';
  String _sortBy = 'total_sales';

  final NumberFormat _currencyFmt = NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);

  final List<String> _tiers = ['الكل', 'الذهب', 'الفضة', 'البرونز', 'جديد', 'متوقف'];
  final List<String> _sortFields = ['total_sales', 'total_collections', 'balance', 'orders_count', 'visits_count', 'returns_count'];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.fetchCustomerAnalytics(
      branchName: widget.currentUser.branchName,
    );

    if (data.isNotEmpty) {
      _customers = data;
    } else {
      _customers = _generateMockCustomers();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<CustomerAnalytics> _generateMockCustomers() {
    return [
      CustomerAnalytics(
        customerId: 'cust_1',
        customerName: 'مخازن البتروز',
        customerCode: 'CUST-001',
        branchName: widget.currentUser.branchName,
        totalSales: 125000,
        totalCollections: 110000,
        balance: 15000,
        overdueBalance: 5000,
        ordersCount: 12,
        visitsCount: 8,
        returnsCount: 1,
        lastOrderDate: '2026-10-15',
        lastVisitDate: '2026-10-14',
        tier: 'الذهب',
        hasDealtIn2026: true,
      ),
      CustomerAnalytics(
        customerId: 'cust_2',
        customerName: 'مجموعة السادة الكبرى',
        customerCode: 'CUST-002',
        branchName: widget.currentUser.branchName,
        totalSales: 85000,
        totalCollections: 85000,
        balance: 0,
        overdueBalance: 0,
        ordersCount: 8,
        visitsCount: 6,
        returnsCount: 0,
        lastOrderDate: '2026-10-10',
        lastVisitDate: '2026-10-09',
        tier: 'الفضة',
        hasDealtIn2026: true,
      ),
      CustomerAnalytics(
        customerId: 'cust_3',
        customerName: 'سوبر ماركت النيل',
        customerCode: 'CUST-003',
        branchName: widget.currentUser.branchName,
        totalSales: 45000,
        totalCollections: 32000,
        balance: 13000,
        overdueBalance: 13000,
        ordersCount: 5,
        visitsCount: 3,
        returnsCount: 2,
        lastOrderDate: '2026-10-05',
        lastVisitDate: '2026-09-28',
        tier: 'البرونز',
        hasDealtIn2026: false,
      ),
      CustomerAnalytics(
        customerId: 'cust_4',
        customerName: 'مطعم العربي الجديد',
        customerCode: 'CUST-004',
        branchName: widget.currentUser.branchName,
        totalSales: 15000,
        totalCollections: 5000,
        balance: 10000,
        overdueBalance: 10000,
        ordersCount: 2,
        visitsCount: 4,
        returnsCount: 0,
        lastOrderDate: '2026-09-20',
        lastVisitDate: '2026-10-12',
        tier: 'جديد',
        hasDealtIn2026: false,
      ),
    ];
  }

  List<CustomerAnalytics> get _filteredAndSorted {
    List<CustomerAnalytics> result = List.from(_customers);

    if (_selectedTier != 'الكل') {
      result = result.where((c) => (c.tier ?? '') == _selectedTier).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) =>
          c.customerName.toLowerCase().contains(q) ||
          (c.customerCode).toLowerCase().contains(q)).toList();
    }

    result.sort((a, b) {
      switch (_sortBy) {
        case 'total_sales': return (b.totalSales).compareTo(a.totalSales);
        case 'total_collections': return (b.totalCollections).compareTo(a.totalCollections);
        case 'balance': return (b.balance).compareTo(a.balance);
        case 'orders_count': return b.ordersCount.compareTo(a.ordersCount);
        case 'visits_count': return b.visitsCount.compareTo(a.visitsCount);
        case 'returns_count': return b.returnsCount.compareTo(a.returnsCount);
        default: return 0;
      }
    });

    return result;
  }

  Color _tierColor(String? tier) {
    switch (tier) {
      case 'الذهب': return AppTheme.primaryGold;
      case 'الفضة': return AppTheme.silver;
      case 'البرونز': return AppTheme.copper;
      case 'جديد': return AppTheme.infoBlue;
      case 'متوقف': return AppTheme.textMuted;
      default: return AppTheme.primaryGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAndSorted;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('تحليلات جميع العملاء',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: AppBar(
          backgroundColor: AppTheme.darkSlate,
          elevation: 0,
          title: Row(
            children: [
              // Search
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'بحث بالعميل أو الكود...',
                    hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 11),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 16),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tier filter
              DropdownButton<String>(
                value: _selectedTier,
                items: _tiers.map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.cairo()))).toList(),
                onChanged: (v) => setState(() => _selectedTier = v ?? 'الكل'),
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                dropdownColor: AppTheme.darkSlate,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.filter_alt_outlined, color: Colors.white70, size: 16),
              ),
              const SizedBox(width: 4),
              // Sort
              DropdownButton<String>(
                value: _sortBy,
                items: _sortFields.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.cairo()))).toList(),
                onChanged: (v) => setState(() => _sortBy = v ?? 'total_sales'),
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                dropdownColor: AppTheme.darkSlate,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.sort_outlined, color: Colors.white70, size: 16),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(children: [
                        Text('${filtered.length}',
                            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.infoBlue)),
                        Text('عملاء', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
                      ]),
                      Container(width: 1, height: 30, color: AppTheme.borderColor),
                      Column(children: [
                        Text(_currencyFmt.format(filtered.fold<double>(0, (s, c) => s + c.totalSales)),
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                        Text('مبيعات', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
                      ]),
                      Container(width: 1, height: 30, color: AppTheme.borderColor),
                      Column(children: [
                        Text(_currencyFmt.format(filtered.where((c) => c.overdueBalance > 0).fold<double>(0, (s, c) => s + c.overdueBalance)),
                            style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
                        Text('مستحق عوئد', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
                      ]),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Customer list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('لا يوجد عملاء مطابقين لمعايير البحث',
                                  style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final customer = filtered[index];
                            final tierColor = _tierColor(customer.tier);
                            final balanceColor = customer.balance > 0 ? AppTheme.errorRed : AppTheme.emeraldGreen;

                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: tierColor.withOpacity(0.15),
                                  child: Icon(Icons.storefront_outlined, color: tierColor, size: 18),
                                ),
                                title: Text(
                                  customer.customerName,
                                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${customer.customerCode}',
                                        style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _buildStat('${customer.ordersCount}', 'طل', AppTheme.infoBlue),
                                        const SizedBox(width: 8),
                                        _buildStat('${customer.visitsCount}', 'زيارة', AppTheme.emeraldGreen),
                                        const SizedBox(width: 8),
                                        _buildStat('${customer.returnsCount}', 'مرتجع', AppTheme.warningAmber),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _currencyFmt.format(customer.balance),
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: balanceColor,
                                      ),
                                    ),
                                    if (customer.overdueBalance > 0)
                                      Text(
                                        'عوئد ${_currencyFmt.format(customer.overdueBalance)}',
                                        style: GoogleFonts.cairo(fontSize: 9, color: AppTheme.errorRed),
                                      ),
                                    if (customer.tier != null)
                                      Text(
                                        customer.tier!,
                                        style: GoogleFonts.cairo(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: tierColor,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  // TODO: Navigate to customer detail
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Row(
      children: [
        Text(value, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 2),
        Text(label, style: GoogleFonts.cairo(fontSize: 8, color: AppTheme.textMuted)),
      ],
    );
  }
}
