import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'visits_dashboard_screen.dart';
import 'customer_detail_dialog.dart';

class AllCustomersAnalyticsView extends StatefulWidget {
  final AppUser currentUser;
  const AllCustomersAnalyticsView({super.key, required this.currentUser});

  @override
  State<AllCustomersAnalyticsView> createState() => _AllCustomersAnalyticsViewState();
}

class _AllCustomersAnalyticsViewState extends State<AllCustomersAnalyticsView> {
  List<CustomerAnalytics> _allCustomers = [];
  List<CustomerAnalytics> _visibleCustomers = [];
  List<AppUser> _allReps = [];
  List<Branch> _allBranches = [];
  bool _isLoading = true;
  bool _isFiltersLoading = true;
  String _searchQuery = '';
  String _selectedBranch = 'الكل';
  String _selectedRep = 'الكل';
  String _selectedTier = 'الكل';

  final int _pageSize = 10;
  int _currentPage = 0;

  final NumberFormat _currencyFmt = NumberFormat.currency(locale: 'ar_EG', decimalDigits: 0);

  final List<String> _tiers = ['الكل', 'الذهب', 'الفضة', 'البرونز', 'جديد', 'متوقف'];

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _loadFilters();
  }

  void _loadCustomers() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.fetchCustomerAnalytics(
      branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
    );
    final visible = rbac.filterCustomers(data);
    _allCustomers = visible;
    _applyFilters();
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadFilters() async {
    _allBranches = await SupabaseService.instance.fetchBranches();
    _allReps = await SupabaseService.instance.fetchUsers(
      branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
    );
    if (mounted) setState(() => _isFiltersLoading = false);
  }

  String _normalizeSearchText(String value) {
    if (value.isEmpty) return '';
    return value
        .toLowerCase()
        .replaceAll(RegExp('[إأآا]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp('[ىي]'), 'ي')
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .trim();
  }

  void _applyFilters() {
    final query = _normalizeSearchText(_searchQuery);
    var result = _allCustomers.where((c) {
      final branchMatch = _selectedBranch == 'الكل' || c.branchName == _selectedBranch;
      final repMatch = _selectedRep == 'الكل' || (c.salesRepName ?? c.branchName) == _selectedRep;
      final tierMatch = _selectedTier == 'الكل' || (c.tier ?? '') == _selectedTier;

      if (!branchMatch || !repMatch || !tierMatch) return false;

      if (query.isEmpty) return true;

      final nameMatch = _normalizeSearchText(c.customerName).contains(query);
      final codeMatch = _normalizeSearchText(c.customerCode).contains(query);
      final branchNameMatch = _normalizeSearchText(c.branchName).contains(query);

      return nameMatch || codeMatch || branchNameMatch;
    }).toList();

    result.sort((a, b) => (b.totalSales).compareTo(a.totalSales));

    _currentPage = 0;
    _paginate(result);
  }

  void _paginate(List<CustomerAnalytics> fullList) {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, fullList.length);
    setState(() {
      _visibleCustomers = fullList.sublist(start, end);
    });
  }

  void _loadMore() {
    final fullList = _filteredAndSorted;
    final start = (_currentPage + 1) * _pageSize;
    if (start >= fullList.length) return;
    _currentPage++;
    _paginate(fullList);
  }

  List<CustomerAnalytics> get _filteredAndSorted {
    final query = _normalizeSearchText(_searchQuery);
    var result = _allCustomers.where((c) {
      final branchMatch = _selectedBranch == 'الكل' || c.branchName == _selectedBranch;
      final repMatch = _selectedRep == 'الكل' || (c.salesRepName ?? c.branchName) == _selectedRep;
      final tierMatch = _selectedTier == 'الكل' || (c.tier ?? '') == _selectedTier;

      if (!branchMatch || !repMatch || !tierMatch) return false;

      if (query.isEmpty) return true;

      final nameMatch = _normalizeSearchText(c.customerName).contains(query);
      final codeMatch = _normalizeSearchText(c.customerCode).contains(query);
      final branchNameMatch = _normalizeSearchText(c.branchName).contains(query);

      return nameMatch || codeMatch || branchNameMatch;
    }).toList();

    result.sort((a, b) => (b.totalSales).compareTo(a.totalSales));
    return result;
  }

  // === Segmentation ===
  int get _activeCustomersCount {
    return _filteredAndSorted.where((c) => c.hasDealtIn2026).length;
  }

  int get _inactiveCustomersCount {
    return _filteredAndSorted.where((c) => !c.hasDealtIn2026 && c.totalSales == 0).length;
  }

  int get _possibleCustomersCount {
    return _filteredAndSorted.where((c) => !c.hasDealtIn2026 && c.totalSales > 0).length;
  }

  int get _problemCustomersCount {
    return _filteredAndSorted.where((c) => c.overdueBalance > 0 || (c.balance > 0 && c.totalSales > 0)).length;
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

  Widget _buildSummaryRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    final cardColor = isDark ? AppTheme.cardSlate : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(title, style: GoogleFonts.cairo(fontSize: 10, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted)),
            Text(value, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.darkBackground : AppTheme.backgroundLight;
    final surfaceColor = isDark ? AppTheme.cardSlate : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.textDark;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    final filtered = _filteredAndSorted;
    final hasMore = filtered.length > (_currentPage + 1) * _pageSize;

    final totalSales = filtered.fold<double>(0, (s, c) => s + c.totalSales);
    final totalCollections = filtered.fold<double>(0, (s, c) => s + c.totalCollections);
    final totalBalance = filtered.fold<double>(0, (s, c) => s + c.balance);
    final totalOverdue = filtered.fold<double>(0, (s, c) => s + c.overdueBalance);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('تحليلات جميع العملاء', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: AppBar(
          backgroundColor: AppTheme.darkSlate,
          elevation: 0,
          title: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالعميل، الكود، أو الفرع...',
                        hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 11),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 16),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterDropdown<String>(
                    value: _selectedBranch,
                    items: ['الكل', ..._allBranches.map((b) => b.name)],
                    label: 'الفرع',
                    onChanged: (v) => setState(() { _selectedBranch = v ?? 'الكل'; _applyFilters(); }),
                    isDark: isDark,
                    borderColor: borderColor,
                  ),
                  const SizedBox(width: 8),
                  if (!rbac.isSalesRep)
                    _buildFilterDropdown<String>(
                      value: _selectedRep,
                      items: ['الكل', ..._allReps.map((r) => r.name)],
                      label: 'الموظف',
                      onChanged: (v) => setState(() { _selectedRep = v ?? 'الكل'; _applyFilters(); }),
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                  const SizedBox(width: 8),
                  if (!rbac.isSalesRep)
                    _buildFilterDropdown<String>(
                      value: _selectedTier,
                      items: _tiers,
                      label: 'الفئة',
                      onChanged: (v) => setState(() { _selectedTier = v ?? 'الكل'; _applyFilters(); }),
                      isDark: isDark,
                      borderColor: borderColor,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _buildSegmentationTabs(isDark, borderColor, surfaceColor, textColor, mutedColor),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary cards
                Container(
                  color: surfaceColor,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSummaryRow(icon: Icons.people, title: 'عملاء', value: filtered.length.toString(), color: AppTheme.infoBlue, isDark: isDark),
                      _buildSummaryRow(icon: Icons.trending_up, title: 'مبيعات', value: _currencyFmt.format(totalSales), color: AppTheme.primaryGold, isDark: isDark),
                      _buildSummaryRow(icon: Icons.account_balance_wallet, title: 'تحصيلات', value: _currencyFmt.format(totalCollections), color: AppTheme.emeraldGreen, isDark: isDark),
                      _buildSummaryRow(icon: Icons.warning, title: 'مستحقات', value: _currencyFmt.format(totalOverdue), color: AppTheme.errorRed, isDark: isDark),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Customer list (paginated)
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('لا يوجد عملاء مطابقين لمعايير البحث',
                                  style: GoogleFonts.cairo(fontSize: 13, color: mutedColor)),
                            ],
                          ),
                        )
                      : NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            final metrics = notification.metrics;
                            if (metrics.extentAfter < 200 && hasMore) {
                              _loadMore();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _visibleCustomers.length + (hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _visibleCustomers.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: CircularProgressIndicator(color: AppTheme.primaryGold),
                                  ),
                                );
                              }
                              final customer = _visibleCustomers[index];
                              return _buildCustomerCard(customer, isDark, surfaceColor, borderColor, textColor, mutedColor);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSegmentationTabs(bool isDark, Color borderColor, Color surfaceColor, Color textColor, Color mutedColor) {
    final segments = [
      {'label': 'الكل', 'count': _filteredAndSorted.length, 'color': AppTheme.infoBlue, 'key': 'all'},
      {'label': 'نشط', 'count': _activeCustomersCount, 'color': AppTheme.emeraldGreen, 'key': 'active'},
      {'label': 'محتمل', 'count': _possibleCustomersCount, 'color': AppTheme.primaryGold, 'key': 'possible'},
      {'label': 'مشاكل', 'count': _problemCustomersCount, 'color': AppTheme.errorRed, 'key': 'problem'},
      {'label': 'غير نشط', 'count': _inactiveCustomersCount, 'color': mutedColor, 'key': 'inactive'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: segments.map((seg) {
          final isSelected = _selectedTier == 'الكل' && _selectedBranch == 'الكل' && _selectedRep == 'الكل';
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              label: Text('${seg['label']} (${seg['count']})',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.white)),
              backgroundColor: (seg['color'] as Color).withValues(alpha: 0.15),
              selected: false,
              onSelected: (_) {
                switch (seg['key']) {
                  case 'active':
                    setState(() {
                      _selectedTier = 'الكل';
                      _selectedBranch = 'الكل';
                      _selectedRep = 'الكل';
                      _searchQuery = '';
                    });
                    _applyFilters();
                    _filterByActive(true);
                    break;
                  case 'possible':
                    _filterByPossible();
                    break;
                  case 'problem':
                    _filterByProblems();
                    break;
                  case 'inactive':
                    _filterByInactive();
                    break;
                  default:
                    setState(() {
                      _selectedTier = 'الكل';
                      _selectedBranch = 'الكل';
                      _selectedRep = 'الكل';
                      _searchQuery = '';
                    });
                    _applyFilters();
                }
              },
              shape: StadiumBorder(side: BorderSide(color: (seg['color'] as Color).withValues(alpha: 0.3))),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _filterByActive(bool dealt) {
    setState(() {
      _allCustomers = _allCustomers.where((c) => c.hasDealtIn2026 == dealt && c.totalSales > 0).toList();
    });
    _currentPage = 0;
    _applyFilters();
  }

  void _filterByPossible() {
    setState(() {
      _allCustomers = _allCustomers.where((c) => !c.hasDealtIn2026 && c.totalSales > 0).toList();
    });
    _currentPage = 0;
    _applyFilters();
  }

  void _filterByProblems() {
    setState(() {
      _searchQuery = '';
      _selectedBranch = 'الكل';
      _selectedRep = 'الكل';
      _selectedTier = 'الكل';
    });
    final filtered = _allCustomers.where((c) => c.overdueBalance > 0 || c.balance > 0).toList();
    _currentPage = 0;
    _paginate(filtered);
  }

  void _filterByInactive() {
    setState(() {
      _allCustomers = _allCustomers.where((c) => !c.hasDealtIn2026 && c.totalSales == 0).toList();
    });
    _currentPage = 0;
    _applyFilters();
  }

  Widget _buildFilterDropdown<T>({
    required T? value,
    required List<T> items,
    required String label,
    required void Function(T?) onChanged,
    required bool isDark,
    required Color borderColor,
  }) {
    return SizedBox(
      width: 120,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(fontSize: 10, color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          isDense: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString(), style: GoogleFonts.cairo(fontSize: 11, color: Colors.white)),
              );
            }).toList(),
            onChanged: onChanged,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
            dropdownColor: AppTheme.darkSlate,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(
    CustomerAnalytics customer,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    final tierColor = _tierColor(customer.tier);
    final balanceColor = customer.balance > 0 ? AppTheme.errorRed : AppTheme.emeraldGreen;

    return Card(
      color: surfaceColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: borderColor, width: 0.3),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: tierColor.withValues(alpha: 0.15),
          child: Icon(Icons.storefront_outlined, color: tierColor, size: 18),
        ),
        title: Text(
          customer.customerName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.customerCode, style: GoogleFonts.cairo(fontSize: 10, color: mutedColor)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStat('${customer.ordersCount}', 'طل', AppTheme.infoBlue),
                const SizedBox(width: 8),
                _buildStat('${customer.visitsCount}', 'زيارة', AppTheme.emeraldGreen),
                const SizedBox(width: 8),
                _buildStat('${customer.returnsCount}', 'مرتجع', AppTheme.warningAmber),
                if (customer.hasDealtIn2026) ...[
                  const SizedBox(width: 8),
                  _buildStat('✓', '2026', AppTheme.emeraldGreen),
                ],
                if (customer.overdueBalance > 0) ...[
                  const SizedBox(width: 8),
                  _buildStat('عاجل', '', AppTheme.errorRed),
                ],
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
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: balanceColor),
            ),
            const SizedBox(height: 2),
            if (customer.overdueBalance > 0)
              Text(
                'عوئد ${_currencyFmt.format(customer.overdueBalance)}',
                style: GoogleFonts.cairo(fontSize: 8, color: AppTheme.errorRed),
              ),
            if (customer.tier != null)
              Text(
                customer.tier!,
                style: GoogleFonts.cairo(fontSize: 8, fontWeight: FontWeight.bold, color: tierColor),
              ),
          ],
        ),
        onTap: () => _showCustomerDetail(context, customer, isDark),
      ),
    );
  }

  void _showCustomerDetail(BuildContext context, CustomerAnalytics customer, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => CustomerDetailDialog(
        customer: customer,
        currencyFmt: _currencyFmt,
        isDark: isDark,
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


