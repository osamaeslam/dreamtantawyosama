import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'branch_stock_planning_screen.dart';

class InventoryScreen extends StatefulWidget {
  final AppUser currentUser;
  const InventoryScreen({super.key, required this.currentUser});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryTransaction> _transactions = [];
  bool _isLoading = true;
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  final List<String> _transactionTypes = [
    'الكل',
    'حجز طلبية مندوب',
    'صرف واعتماد مشرف',
    'إلغاء حجز وإرجاع',
    'مرتجع مبيعات وإرجاع للمخزن',
    'توريد مخزني',
    'تحويل بين الفروع',
    'تعديل جردي',
  ];
  String _selectedType = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.fetchInventoryTransactions(
      branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
      date: _selectedDate,
    );
    final visible = rbac.filterInventory(data);

    if (data.isEmpty) {
      _transactions = _generateMockTransactions();
    } else {
      _transactions = visible;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<InventoryTransaction> _generateMockTransactions() {
    final now = DateTime.now();
    return [
      InventoryTransaction(
        id: 'tx1',
        timestamp: '${_selectedDate}T10:30:00',
        date: _selectedDate,
        productId: 'p1',
        productCode: 'TNT-101',
        productName: 'طقم حلل جرانيت 10 قطع',
        type: 'حجز طلبية مندوب',
        quantityPieces: 3,
        branchStockBefore: 30,
        branchStockAfter: 27,
        branchName: widget.currentUser.branchName,
        userName: widget.currentUser.name,
        userRole: 'sales_rep',
        invoiceId: 'inv_101',
        invoiceNumber: 'INV-2026-0042',
        notes: 'مرتجع مبيعات (3 كرتونة) - إذن #RET-2026-1042',
      ),
      InventoryTransaction(
        id: 'tx2',
        timestamp: '${_selectedDate}T09:15:00',
        date: _selectedDate,
        productId: 'p3',
        productCode: 'TNT-103',
        productName: 'خلاط يدوي تورنيدو 1000 وات',
        type: 'حجز طلبية مندوب',
        quantityPieces: 2,
        branchStockBefore: 20,
        branchStockAfter: 18,
        branchName: widget.currentUser.branchName,
        userName: widget.currentUser.name,
        userRole: 'sales_rep',
        invoiceId: 'inv_101',
        invoiceNumber: 'INV-2026-0042',
        notes: 'طلبية جديدة للعميل',
      ),
      InventoryTransaction(
        id: 'tx3',
        timestamp: '${_selectedDate}T11:45:00',
        date: _selectedDate,
        productId: 'p1',
        productCode: 'TNT-101',
        productName: 'طقم حلل جرانيت 10 قطع',
        type: 'مرتجع مبيعات وإرجاع للمخزن',
        quantityPieces: 1,
        branchStockBefore: 27,
        branchStockAfter: 28,
        branchName: widget.currentUser.branchName,
        userName: 'مدير المخزن',
        userRole: 'warehouse_keeper',
        invoiceId: 'inv_101',
        invoiceNumber: 'INV-2026-0042',
        notes: 'مرتجع جزئي - صنف سليم',
      ),
    ];
  }

  List<InventoryTransaction> get _filteredTransactions {
    if (_selectedType == 'الكل') return _transactions;
    return _transactions.where((t) => t.type == _selectedType).toList();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateFormat('yyyy-MM-dd').format(picked));
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('حركة المخزون', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          if (rbac.isAdmin || rbac.isSupervisor || rbac.isBranchManager)
            IconButton(
              tooltip: 'تجهيز مخزون الفروع',
              icon: const Icon(Icons.local_shipping_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BranchStockPlanningScreen(
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.white70),
              label: Text(_selectedDate, style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70)),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      children: _transactionTypes.map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(type, style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.darkSlate : AppTheme.textMuted,
                          )),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedType = type),
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.primaryGold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? AppTheme.primaryGold : const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Summary bar
                if (filtered.isNotEmpty)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filtered.length} معاملة',
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                        ),
                        Text(
                          'الإجمالي: ${_sumQuantity(filtered)} ${filtered.length > 0 ? "كرتونة" : ""}',
                          style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 1),

                // Transactions list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text('لا توجد معاملات مخزنية لهذا اليوم',
                                  style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textMuted)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final tx = filtered[index];
                            final isInbound = tx.type == 'مرتجع مبيعات وإرجاع للمخزن' || tx.type == 'توريد مخزنى';
                            final color = isInbound ? AppTheme.emeraldGreen : AppTheme.infoBlue;

                            return Card(
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tx.productName,
                                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${isInbound ? "+" : "-"}${tx.quantityPieces}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      tx.type,
                                      style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${tx.branchStockBefore}',
                                          style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted).copyWith(fontFamily: 'monospace'),
                                        ),
                                        Text(' → ', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted)),
                                        Text(
                                          '${tx.branchStockAfter}',
                                          style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkSlate).copyWith(fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${tx.userName} • ${tx.userRole} • ${DateFormat('HH:mm').format(DateTime.tryParse(tx.timestamp) ?? DateTime.now())}',
                                      style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
                                    ),
                                    if (tx.invoiceNumber != null)
                                      Text(
                                        'فاتورة: ${tx.invoiceNumber}',
                                        style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.infoBlue),
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
    );
  }

  int _sumQuantity(List<InventoryTransaction> txs) {
    return txs.fold(0, (sum, tx) {
      final isInbound = tx.type == 'مرتجع مبيعات وإرجاع للمخزن' || tx.type == 'توريد مخزنى';
      return sum + (isInbound ? tx.quantityPieces : -tx.quantityPieces);
    });
  }
}
