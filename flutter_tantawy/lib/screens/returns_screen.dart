import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ReturnsScreen extends StatefulWidget {
  final AppUser currentUser;
  final OrderInvoice? invoice;

  const ReturnsScreen({super.key, required this.currentUser, this.invoice});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  bool _isSubmitting = false;
  bool _restockToInventory = true;
  String _returnReason = 'مرتجع بطلب العميل واسترجاع البضاعة للمخزن';
  bool _showHistory = false;

  final Map<String, _ReturnItemData> _itemReturns = {};

  final List<String> _reasonOptions = [
    'مرتجع بطلب العميل واسترجاع البضاعة للمخزن',
    'رفض الاستلام عند التوصيل',
    'تلف أو عيب في بعض الكراتين',
    'خطأ في تسجيل الطلبية أو الكميات',
    'استبدال أصناف بطلب الإدارة أو العميل',
    'تأخر في موعد التسليم المطلوب',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeReturns(widget.invoice!);
      });
    }
  }

  void _initializeReturns(OrderInvoice invoice) {
    _itemReturns.clear();
    for (final item in invoice.items) {
      _itemReturns[item.productId] = _ReturnItemData(
        returnCartons: 0,
        returnPieces: 0,
        condition: 'good_condition',
        reason: '',
      );
    }
  }

  Map<String, ({int cartons, int pieces, double amount})> _calculatePreviouslyReturned(OrderInvoice invoice) {
    final map = <String, ({int cartons, int pieces, double amount})>{};
    final records = invoice.returnRecords;
    if (records == null) return map;

    for (final rec in records) {
      final record = ReturnRecord.fromJson(rec as Map<String, dynamic>);

      for (final it in record.returnedItems) {
        final existing = map[it.productId];
        map[it.productId] = (
          cartons: (existing?.cartons ?? 0) + it.cartonCount,
          pieces: (existing?.pieces ?? 0) + it.totalPieces,
          amount: (existing?.amount ?? 0) + it.refundAmount,
        );
      }
    }
    return map;
  }

  List<ReturnedItem> _calculateReturnedItems(OrderInvoice invoice) {
    final previouslyReturned = _calculatePreviouslyReturned(invoice);
    final items = <ReturnedItem>[];

    for (final item in invoice.items) {
      final prev = previouslyReturned[item.productId] ?? (cartons: 0, pieces: 0, amount: 0);
      final remainingCartons = (item.cartons - prev.cartons).clamp(0, item.cartons);
      final remainingPieces = (item.pieces - prev.pieces).clamp(0, item.pieces);

      final state = _itemReturns[item.productId] ?? _ReturnItemData(
        returnCartons: 0,
        returnPieces: 0,
        condition: 'good_condition',
        reason: '',
      );

      final retCartons = state.returnCartons.clamp(0, remainingCartons);
      final retPieces = state.returnPieces.clamp(0, remainingPieces);

      if (retCartons == 0 && retPieces == 0) continue;

      final cartonQty = item.cartonQuantity ?? 0;
      final pricePerCarton = item.appliedPrice ?? item.cartonPrice;
      final pricePerPiece = item.unitPrice ?? (cartonQty > 0 ? pricePerCarton / cartonQty : 0);
      final totalPieces = retCartons * cartonQty + retPieces;
      final refundAmount = retCartons * pricePerCarton + retPieces * pricePerPiece;

      items.add(ReturnedItem(
        productId: item.productId,
        productCode: item.productCode,
        productName: item.productName,
        cartonCount: retCartons,
        pieceCount: retPieces,
        cartonQuantity: cartonQty,
        totalPieces: totalPieces,
        pricePerCarton: pricePerCarton,
        pricePerPiece: pricePerPiece,
        refundAmount: refundAmount,
        returnReason: state.reason.isNotEmpty ? state.reason : _returnReason,
        condition: state.condition,
      ));
    }

    return items;
  }

  double get _totalRefundAmount {
    final invoice = widget.invoice;
    if (invoice == null) return 0;
    final items = _calculateReturnedItems(invoice);
    return items.fold(0.0, (sum, it) => sum + it.refundAmount);
  }

  int get _totalReturnedCartons {
    final invoice = widget.invoice;
    if (invoice == null) return 0;
    final items = _calculateReturnedItems(invoice);
    return items.fold(0, (sum, it) => sum + it.cartonCount);
  }

  int get _totalReturnedPieces {
    final invoice = widget.invoice;
    if (invoice == null) return 0;
    final items = _calculateReturnedItems(invoice);
    return items.fold(0, (sum, it) => sum + it.totalPieces);
  }

  double get _estimatedGrandTotal {
    return widget.invoice?.estimatedGrandTotal ?? 0;
  }

  double get _prevTotalRefunded {
    return widget.invoice?.totalRefundedAmount ?? 0;
  }

  double get _netAfterReturn {
    final total = _estimatedGrandTotal;
    final refunded = _prevTotalRefunded + _totalRefundAmount;
    return (total - refunded).clamp(0, double.infinity);
  }

  void _setAllToMax() {
    final invoice = widget.invoice;
    if (invoice == null) return;
    final previouslyReturned = _calculatePreviouslyReturned(invoice);

    for (final item in invoice.items) {
      final prev = previouslyReturned[item.productId] ?? (cartons: 0, pieces: 0, amount: 0);
      final remainingCartons = (item.cartons - prev.cartons).clamp(0, item.cartons);
      final remainingPieces = (item.pieces - prev.pieces).clamp(0, item.pieces);
      _itemReturns[item.productId] = _ReturnItemData(
        returnCartons: remainingCartons,
        returnPieces: remainingPieces,
        condition: 'good_condition',
        reason: '',
      );
    }
    setState(() {});
  }

  void _resetToZero() {
    for (final key in _itemReturns.keys) {
      final item = _itemReturns[key]!;
      _itemReturns[key] = _ReturnItemData(
        returnCartons: 0,
        returnPieces: 0,
        condition: item.condition,
        reason: item.reason,
      );
    }
    setState(() {});
  }

  Future<void> _submitReturn() async {
    final invoice = widget.invoice;
    if (invoice == null) return;

    final items = _calculateReturnedItems(invoice);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى تحديد صنف واحد على الأقل مع تحديد الكمية المرتجعة', style: GoogleFonts.cairo())),
      );
      return;
    }

    if (_returnReason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى كتابة أو اختيار سبب المرتجع', style: GoogleFonts.cairo())),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final voucherNumber = 'RET-${now.year}-${1000 + now.millisecondsSinceEpoch % 9000}';

    final newReturnRecord = ReturnRecord(
      id: 'ret_${now.millisecondsSinceEpoch}',
      returnVoucherNumber: voucherNumber,
      invoiceId: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      customerName: invoice.customerName,
      customerCode: invoice.customerCode,
      branchName: invoice.branchName,
      repName: invoice.repName,
      date: dateStr,
      time: timeStr,
      returnedItems: items,
      totalRefundAmount: _totalRefundAmount,
      totalReturnedCartons: _totalReturnedCartons,
      totalReturnedPieces: _totalReturnedPieces,
      reason: _returnReason,
      handledBy: widget.currentUser.name,
      restockedToInventory: _restockToInventory,
      notes: 'إذن مرتجع مبيعات #$voucherNumber للفاتورة #${invoice.invoiceNumber}',
    );

    try {
      // 1. Save the return record
      final success = await SupabaseService.instance.createReturnRecord(newReturnRecord);

      if (success) {
        // 2. Update invoice with return info
         final allRefunded = _prevTotalRefunded + _totalRefundAmount;
        final isFullReturn = _totalReturnedCartons >= (invoice.totalCartons ?? 0) || allRefunded >= _estimatedGrandTotal;
        final newStatus = isFullReturn ? 'مرتجع' : 'مرتجع جزئي';

        await SupabaseService.instance.updateInvoiceStatus(invoice.id, newStatus);

        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final nav = Navigator.of(context);

        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'تم تسجيل إذن المرتجع #$voucherNumber بنجاح (${isFullReturn ? "مرتجع كلي" : "مرتجع جزئي"}) بقيمة ${_totalRefundAmount.toStringAsFixed(2)} ج.م',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppTheme.emeraldGreen,
          ),
        );
        nav.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تسجيل المرتجع', style: GoogleFonts.cairo())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e', style: GoogleFonts.cairo())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: Text('المرتجعات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
        body: Center(child: Text('لم يتم تحديد فاتورة', style: GoogleFonts.cairo())),
      );
    }

    final previouslyReturned = _calculatePreviouslyReturned(invoice);
    final items = _calculateReturnedItems(invoice);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إذن مرتجع مبيعات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${invoice.invoiceNumber}', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.secondaryGold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Invoice info card
            _buildInvoiceInfoCard(invoice),
            const SizedBox(height: 12),

            // Mode selector
            _buildModeSelector(),
            const SizedBox(height: 12),

            // Return reason
            _buildReturnReason(),
            const SizedBox(height: 12),

            // Return history
            if (invoice.returnRecords != null && invoice.returnRecords!.isNotEmpty)
              _buildReturnHistory(invoice, previouslyReturned),
            const SizedBox(height: 8),

            // Items table
            _buildItemsTable(invoice, items, previouslyReturned),
            const SizedBox(height: 12),

            // Financial summary
            _buildFinancialSummary(invoice),

            // Restock checkbox
            _buildRestockCheckbox(),
          ],
        ),
      ),
      bottomNavigationBar: _calculateReturnedItems(invoice).isNotEmpty
          ? _buildBottomBar(invoice)
          : null,
    );
  }

  Widget _buildInvoiceInfoCard(OrderInvoice invoice) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryGold, size: 20),
                const SizedBox(width: 8),
                Text('بيانات الفاتورة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person_outline, 'العميل', invoice.customerName),
            _buildInfoRow(Icons.code, 'كود العميل', invoice.customerCode),
            _buildInfoRow(Icons.store_outlined, 'الفرع', invoice.branchName),
            _buildInfoRow(Icons.person_outline, 'المندوب', invoice.repName),
            _buildInfoRow(Icons.calendar_today_outlined, 'التاريخ', invoice.date.toIso8601String().split('T')[0]),
            _buildInfoRow(Icons.numbers, 'عدد الأصناف', '${invoice.items.length} صنف'),
            _buildInfoRow(Icons.calculate, 'الإجمالي الأصلي', '${_estimatedGrandTotal.toStringAsFixed(2)} ج.م'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text('$label:', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkSlate)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نوع المرتجع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _modeButton('مرتجع جزئي', _returnReason, isSelected: true, onTap: () {
                  _resetToZero();
                }),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _modeButton('مرتجع كلي', _returnReason, isSelected: false, onTap: _setAllToMax),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String label, String subLabel, {required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold.withValues(alpha: 0.15) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.primaryGold : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.darkSlate)),
      ),
    );
  }

  Widget _buildReturnReason() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('سبب المرتجع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _reasonOptions.map((reason) {
              final isSelected = _returnReason == reason;
              return ChoiceChip(
                label: Text(reason, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold)),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _returnReason = reason);
                },
                backgroundColor: const Color(0xFFF1F5F9),
                selectedColor: AppTheme.primaryGold,
                labelStyle: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.darkSlate : AppTheme.textMuted,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (val) => setState(() => _returnReason = val),
            decoration: InputDecoration(
              hintText: 'أو اكتب سبب المرتجع بالتفصيل...',
              hintStyle: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade500),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.cairo(fontSize: 13),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildReturnHistory(OrderInvoice invoice, Map<String, ({int cartons, int pieces, double amount})> previouslyReturned) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سجل المرتجعات السابقة (${invoice.returnRecords!.length})',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF5B21B6)),
              ),
              TextButton(
                onPressed: () => setState(() => _showHistory = !_showHistory),
                child: Text(
                  _showHistory ? 'إخفاء' : 'عرض',
                  style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
          if (_showHistory)
            ...invoice.returnRecords!.map((rec) {
              final record = ReturnRecord.fromJson(rec as Map<String, dynamic>);
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إذن #${record.returnVoucherNumber} • ${record.date} ${record.time}',
                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'بقيمة ${record.totalRefundAmount.toStringAsFixed(2)} ج.م (${record.totalReturnedCartons} كرتونة)',
                      style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              );
            }),
          if (_showHistory) const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE10050).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'مرتجع سابق: ${_prevTotalRefunded.toStringAsFixed(2)} ج.م',
              style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFFBE185D), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(OrderInvoice invoice, List<ReturnedItem> items, Map<String, ({int cartons, int pieces, double amount})> previouslyReturned) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أصناف الفاتورة وتحديد الكمية المرتجعة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 12,
                headingRowHeight: 32,
                dataRowMinHeight: 80,
                dataRowMaxHeight: 80,
                columns: const [
                  DataColumn(label: Text('الصنف', style: TextStyle(fontSize: 9))),
                  DataColumn(label: Text('الأصلية', style: TextStyle(fontSize: 9)), numeric: true),
                  DataColumn(label: Text('مرتجع سابق', style: TextStyle(fontSize: 9)), numeric: true),
                  DataColumn(label: Text('المتبقي', style: TextStyle(fontSize: 9)), numeric: true),
                  DataColumn(label: Text('مرتجع كرتونة', style: TextStyle(fontSize: 9)), numeric: true),
                  DataColumn(label: Text('مرتجع قطعة', style: TextStyle(fontSize: 9)), numeric: true),
                  DataColumn(label: Text('الحالة', style: TextStyle(fontSize: 9))),
                  DataColumn(label: Text('قيمة الإرجاع', style: TextStyle(fontSize: 9))),
                ],
                rows: invoice.items.map((item) {
                  final prev = previouslyReturned[item.productId] ?? (cartons: 0, pieces: 0, amount: 0);
                  final remainingCartons = (item.cartons - prev.cartons).clamp(0, item.cartons);
                  final remainingPieces = (item.pieces - prev.pieces).clamp(0, item.pieces);
                  final currentReturn = _itemReturns[item.productId]!;
                  final isFullyReturned = remainingCartons == 0 && remainingPieces == 0;
                  final cartonQty = item.cartonQuantity ?? 0;
                  final pricePerCarton = item.appliedPrice ?? item.cartonPrice;
                  final pricePerPiece = item.unitPrice ?? (cartonQty > 0 ? pricePerCarton / cartonQty : 0);

                  final itemRefund = currentReturn.returnCartons * pricePerCarton + currentReturn.returnPieces * pricePerPiece;

                  return DataRow(
                    cells: [
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.productName, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('${item.productCode} • شدة: ${cartonQty} ق/ك', style: GoogleFonts.cairo(fontSize: 9, color: AppTheme.textMuted)),
                        ],
                      )),
                      DataCell(Text('${item.cartons} ك${item.pieces > 0 ? " + ${item.pieces} ق" : ""}',
                          style: GoogleFonts.cairo(fontSize: 11))),
                      DataCell(prev.cartons > 0 || prev.pieces > 0
                          ? Text('${prev.cartons} ك${prev.pieces > 0 ? " + ${prev.pieces} ق" : ""}',
                              style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF7C3AED)))
                          : Text('-', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted))),
                      DataCell(Text('$remainingCartons ك$remainingPieces ق',
                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkSlate))),
                      DataCell(isFullyReturned
                          ? Text('-', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted))
                          : SizedBox(
                              width: 56,
                              child: TextFormField(
                                initialValue: currentReturn.returnCartons.toString(),
                                onChanged: (val) {
                                  final v = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                  _itemReturns[item.productId] = currentReturn.copyWith(
                                    returnCartons: v.clamp(0, remainingCartons),
                                  );
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                ),
                                style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                                keyboardType: TextInputType.number,
                                enabled: !isFullyReturned,
                              ),
                            )),
                      DataCell(isFullyReturned
                          ? Text('-', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted))
                          : SizedBox(
                              width: 56,
                              child: TextFormField(
                                initialValue: currentReturn.returnPieces.toString(),
                                onChanged: (val) {
                                  final v = int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                  _itemReturns[item.productId] = currentReturn.copyWith(
                                    returnPieces: v.clamp(0, remainingPieces),
                                  );
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                ),
                                style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold),
                                keyboardType: TextInputType.number,
                                enabled: !isFullyReturned,
                              ),
                            )),
                      DataCell(
                        SizedBox(
                          width: 90,
                          child: DropdownButton<String>(
                            value: currentReturn.condition,
                            items: const [
                              DropdownMenuItem(value: 'good_condition', child: Text('🔄 سليم')),
                              DropdownMenuItem(value: 'damaged', child: Text('⚠️ تالف')),
                              DropdownMenuItem(value: 'expired', child: Text('⛔ منتهي')),
                            ],
                            onChanged: (val) {
                              _itemReturns[item.productId] = currentReturn.copyWith(condition: val!);
                              setState(() {});
                            },
                            underline: Container(height: 1, color: const Color(0xFFE2E8F0)),
                            style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.darkSlate),
                          ),
                        ),
                      ),
                      DataCell(Text('${itemRefund.toStringAsFixed(2)} ج.م',
                          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F766E)))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(OrderInvoice invoice) {
    final isFullReturn = _totalRefundAmount + _prevTotalRefunded >= _estimatedGrandTotal;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ملخص المالية والأثر على المخزون', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            _buildSummaryRow('إجمالي الفاتورة الأصلية', _estimatedGrandTotal.toStringAsFixed(2), isEmphasis: true),
            const SizedBox(height: 6),
            _buildSummaryRow('مرتجع سابق', _prevTotalRefunded.toStringAsFixed(2), color: const Color(0xFF7C3AED)),
            const SizedBox(height: 6),
            _buildSummaryRow('المبلغ المرتجع الآن', _totalRefundAmount.toStringAsFixed(2), color: AppTheme.roseRed, isEmphasis: true),
            const Divider(),
            const SizedBox(height: 6),
            _buildSummaryRow('أصناف مرتجعة للمخزن', '+$_totalReturnedCartons كرتونة', color: AppTheme.emeraldGreen),
            _buildSummaryRow('', '+$_totalReturnedPieces قطعة', color: AppTheme.emeraldGreen),
            const SizedBox(height: 6),
            _buildSummaryRow(
              isFullReturn ? '🔄 مرتجع كلي' : '🔄 مرتجع جزئي',
              '${_netAfterReturn.toStringAsFixed(2)} ج.م',
              isEmphasis: true,
              color: AppTheme.darkSlate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isEmphasis = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(
          fontSize: isEmphasis ? 13 : 11,
          fontWeight: isEmphasis ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppTheme.textMuted,
        )),
        Text(value, style: GoogleFonts.cairo(
          fontSize: isEmphasis ? 13 : 11,
          fontWeight: FontWeight.bold,
          color: color ?? AppTheme.darkSlate,
        )),
      ],
    );
  }

  Widget _buildRestockCheckbox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _restockToInventory,
            onChanged: (val) => setState(() => _restockToInventory = val ?? true),
            activeColor: AppTheme.primaryGold,
            checkColor: AppTheme.darkSlate,
          ),
          Expanded(
            child: Text(
              'إعادة البضاعة السليمة فوراً إلى رصيد المخزن الفعلي للفرع وتحديث بطاقة الصنف 🔄',
              style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(OrderInvoice invoice) {
    final items = _calculateReturnedItems(invoice);
    final canSubmit = items.isNotEmpty && _returnReason.trim().isNotEmpty;
    final isFullReturn = _totalReturnedCartons >= (invoice.totalCartons ?? 0) || (_totalRefundAmount + _prevTotalRefunded) >= _estimatedGrandTotal;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${items.length} أصناف مرتجعة • ${isFullReturn ? "مرتجع كلي" : "مرتجع جزئي"}',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  Text(
                    'المبلغ: ${_totalRefundAmount.toStringAsFixed(2)} ج.م | باقي الفاتورة: ${_netAfterReturn.toStringAsFixed(2)} ج.م',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit ? AppTheme.roseRed : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: canSubmit && !_isSubmitting ? _submitReturn : null,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _isSubmitting ? '...' : 'تأكيد إذن المرتجع',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnItemData {
  final int returnCartons;
  final int returnPieces;
  final String condition;
  final String reason;

  _ReturnItemData({
    required this.returnCartons,
    required this.returnPieces,
    required this.condition,
    required this.reason,
  });

  _ReturnItemData copyWith({
    int? returnCartons,
    int? returnPieces,
    String? condition,
    String? reason,
  }) {
    return _ReturnItemData(
      returnCartons: returnCartons ?? this.returnCartons,
      returnPieces: returnPieces ?? this.returnPieces,
      condition: condition ?? this.condition,
      reason: reason ?? this.reason,
    );
  }
}


