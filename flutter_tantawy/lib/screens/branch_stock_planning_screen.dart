import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class BranchStockPlanningScreen extends StatefulWidget {
  final AppUser currentUser;

  const BranchStockPlanningScreen({super.key, required this.currentUser});

  @override
  State<BranchStockPlanningScreen> createState() =>
      _BranchStockPlanningScreenState();
}

class _BranchStockPlanningScreenState extends State<BranchStockPlanningScreen> {
  List<Branch> _branches = [];
  List<ParentProduct> _products = [];
  Branch? _selectedBranch;
  bool _isLoadingBranches = true;
  bool _isLoadingProducts = false;

  RoleAccessController get _rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    if (mounted) setState(() => _isLoadingBranches = true);
    final branches = await SupabaseService.instance.fetchBranches();
    final visibleBranches = branches
        .where((branch) => branch.isMainWarehouse != true)
        .where((branch) =>
            _rbac.isAdmin || branch.name == widget.currentUser.branchName)
        .toList();
    if (!mounted) return;
    setState(() {
      _branches = visibleBranches;
      _selectedBranch = visibleBranches.cast<Branch?>().firstWhere(
            (branch) => branch?.name == widget.currentUser.branchName,
            orElse: () => visibleBranches.isEmpty ? null : visibleBranches.first,
          );
      _isLoadingBranches = false;
    });
    if (_selectedBranch != null) {
      await _loadProducts(_selectedBranch!.name);
    }
  }

  Future<void> _loadProducts(String branchName) async {
    setState(() => _isLoadingProducts = true);
    final products = await SupabaseService.instance.fetchParentProducts(
      branchName: branchName,
    );
    if (!mounted) return;
    setState(() {
      _products = products;
      _isLoadingProducts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final variants = _products
        .expand((product) => product.variants.map((variant) => (product, variant)))
        .toList();
    final transferCandidates = variants
        .where((entry) =>
            entry.$2.availableStock == 0 && entry.$2.octoberAvailableStock > 0)
        .length;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text(
          'تجهيز مخزون الفروع',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث الأرصدة',
            onPressed: _isLoadingBranches || _isLoadingProducts
                ? null
                : () => _loadBranches(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoadingBranches
          ? const Center(child: CircularProgressIndicator())
          : _branches.isEmpty
              ? _emptyState('لا توجد فروع متاحة لهذا الحساب.')
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<Branch>(
                        value: _selectedBranch,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'الفرع المطلوب تجهيزه',
                          border: OutlineInputBorder(),
                        ),
                        items: _branches
                            .map((branch) => DropdownMenuItem(
                                  value: branch,
                                  child: Text(
                                    branch.name,
                                    style: GoogleFonts.cairo(),
                                  ),
                                ))
                            .toList(),
                        onChanged: (branch) {
                          if (branch == null) return;
                          setState(() {
                            _selectedBranch = branch;
                            _products = [];
                          });
                          _loadProducts(branch.name);
                        },
                      ),
                    ),
                    if (_selectedBranch != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGold.withOpacity( 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined,
                                  color: AppTheme.darkSlate),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$transferCandidates صنفًا رصيد الفرع فيها صفر ومتاح منها في مخزن أكتوبر',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkSlate,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _isLoadingProducts
                          ? const Center(child: CircularProgressIndicator())
                          : variants.isEmpty
                              ? _emptyState('لا توجد أصناف مسجلة لهذا الفرع.')
                              : RefreshIndicator(
                                  onRefresh: () => _selectedBranch == null
                                      ? _loadBranches()
                                      : _loadProducts(
                                          _selectedBranch!.name,
                                        ),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: variants.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final (product, variant) =
                                          variants[index];
                                      final needsTransfer =
                                          variant.availableStock == 0 &&
                                              variant.octoberAvailableStock > 0;
                                      final noStock =
                                          variant.availableStock == 0 &&
                                              variant.octoberAvailableStock == 0;
                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      product.name,
                                                      style: GoogleFonts.cairo(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (needsTransfer)
                                                    _statusChip(
                                                      'مرشح للتحويل',
                                                      AppTheme.primaryGold,
                                                    )
                                                  else if (noStock)
                                                    _statusChip(
                                                      'غير متوفر',
                                                      AppTheme.roseRed,
                                                    )
                                                  else
                                                    _statusChip(
                                                      'متاح بالفرع',
                                                      AppTheme.emeraldGreen,
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${variant.code} • ${variant.color}',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 11,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: _stockValue(
                                                      'رصيد الفرع المتاح',
                                                      variant.availableStock,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: _stockValue(
                                                      'متاح في أكتوبر',
                                                      variant
                                                          .octoberAvailableStock,
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
                    ),
                  ],
                ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: AppTheme.textMuted),
        ),
      ),
    );
  }

  Widget _stockValue(String label, int quantity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(fontSize: 10)),
        Text(
          '$quantity كرتونة',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity( 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color == AppTheme.primaryGold ? AppTheme.darkSlate : color,
        ),
      ),
    );
  }
}
