import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';

class VisitsScreen extends StatefulWidget {
  final AppUser currentUser;
  const VisitsScreen({super.key, required this.currentUser});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  List<CustomerVisit> _visits = [];
  List<Customer> _customers = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;
  bool _isLoadingCustomers = true;
  bool _isLoadingProducts = false;
  bool _isOffline = false;
  DateTime? _selectedDate;
  static const String _cacheKey = 'visits_cache_${'USER'}';

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _fetchVisits();
    _fetchCustomers();
    _fetchAllProducts();
  }

  Future<void> _fetchAllProducts() async {
    if (_allProducts.isNotEmpty) return;
    setState(() => _isLoadingProducts = true);
    try {
      final data = await SupabaseService.instance.fetchProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = data;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _fetchVisits() async {
    if (mounted) setState(() => _isLoading = true);
    List<CustomerVisit> data;
    try {
      data = await SupabaseService.instance.fetchVisits(
        repName: rbac.isSalesRep ? widget.currentUser.name : null,
        branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
        date: _selectedDate,
      );
    } catch (e) {
      final cached = await _loadCache();
      if (!mounted) return;
      setState(() {
        _isOffline = true;
        _visits = rbac
            .filterVisits(_filterCachedVisits(cached))
            .toList();
        _isLoading = false;
      });
      if (_visits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحميل الزيارات: $e')),
        );
      }
      return;
    }

    _visits = rbac.filterVisits(data);
    if (mounted) {
      setState(() {
        _isOffline = false;
        _isLoading = false;
      });
    }
    if (_selectedDate == null) {
      try {
        await _saveCache(data);
      } catch (e) {
        debugPrint('تعذر تحديث ذاكرة الزيارات المؤقتة: $e');
      }
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      final data = await SupabaseService.instance.fetchCustomers(
        repName: rbac.isSalesRep ? widget.currentUser.name : null,
        repId: rbac.isSalesRep ? widget.currentUser.id : null,
        branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
      );
      if (!mounted) return;
      setState(() {
        _customers = rbac.filterCustomerAccounts(data);
        _isLoadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل قائمة العملاء: $e')),
      );
    }
  }

  List<CustomerVisit> _filterCachedVisits(List<CustomerVisit> visits) {
    if (_selectedDate == null) return visits;
    return visits
        .where((visit) =>
            visit.date.year == _selectedDate!.year &&
            visit.date.month == _selectedDate!.month &&
            visit.date.day == _selectedDate!.day)
        .toList();
  }

  Future<void> _saveCache(List<CustomerVisit> visits) async {
    final prefs = await SharedPreferences.getInstance();
    final json = visits.map((visit) => jsonEncode(visit.toJson())).toList();
    await prefs.setStringList(_cacheKey.replaceFirst('USER', widget.currentUser.id), json);
  }

  Future<List<CustomerVisit>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_cacheKey.replaceFirst('USER', widget.currentUser.id));
      if (cached == null || cached.isEmpty) return [];
      return cached
          .map((json) => CustomerVisit.fromJson(
                jsonDecode(json) as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      debugPrint('تعذر قراءة ذاكرة الزيارات المؤقتة: $e');
      return [];
    }
  }

  List<Product> _searchProducts(String query) {
    if (query.trim().isEmpty) return _allProducts.take(30).toList();
    final q = query.toLowerCase().trim();
    return _allProducts.where((p) {
      final name = p.name.toLowerCase();
      final code = (p.code ?? '').toLowerCase();
      final barcode = (p.barcode ?? '').toLowerCase();
      return name.contains(q) || code.contains(q) || barcode.contains(q);
    }).take(40).toList();
  }

  Future<void> _showAddReturnItem(BuildContext context, StateSetter setModalState, List<Map<String, dynamic>> returnItemsList) async {
    final qtyController = TextEditingController(text: '1');
    Product? selectedProduct;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkSlate,
          title: Text('إضافة صنف للمرتجع', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ابحث عن الصنف', style: GoogleFonts.cairo(color: Colors.white70)),
                const SizedBox(height: 8),
                Autocomplete<Product>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _searchProducts('');
                    }
                    return _searchProducts(textEditingValue.text);
                  },
                  displayStringForOption: (Product p) => p.name,
                  onSelected: (Product p) {
                    setDialogState(() => selectedProduct = p);
                  },
                  fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: textController,
                      focusNode: focusNode,
                      style: GoogleFonts.cairo(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو الكود أو الباركود',
                        hintStyle: GoogleFonts.cairo(color: Colors.grey),
                        filled: true,
                        fillColor: AppTheme.cardSlate,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topRight,
                      child: Material(
                        color: AppTheme.darkSlate,
                        elevation: 4,
                        child: Container(
                          width: 300,
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final product = options.elementAt(index);
                              return ListTile(
                                title: Text(product.name, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
                                subtitle: Text(product.code ?? '', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 10)),
                                onTap: () => onSelected(product),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (selectedProduct != null) ...[
                  const SizedBox(height: 12),
                  Text('الصنف المختار: ${selectedProduct!.name}', style: GoogleFonts.cairo(color: AppTheme.primaryGold, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الكمية المرتجعة',
                    labelStyle: GoogleFonts.cairo(color: Colors.grey),
                    filled: true,
                    fillColor: AppTheme.cardSlate,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null) return;
                final qty = int.tryParse(qtyController.text.trim()) ?? 1;
                returnItemsList.add({
                  'productId': selectedProduct!.id,
                  'productName': selectedProduct!.name,
                  'productCode': selectedProduct!.code,
                  'quantity': qty,
                });
                setModalState(() {});
                Navigator.pop(dialogCtx);
              },
              child: Text('إضافة', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnItemTile(Map<String, dynamic> item, StateSetter setModalState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.undo, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['productName'] ?? '', style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('كود: ${item['productCode'] ?? '-'} • كمية: ${item['quantity']}', style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewVisitDialog() async {
    final notesController = TextEditingController();
    final amountController = TextEditingController();
    final visitReasonController = TextEditingController();
    String visitType = 'زيارة بيع وطلبية';
    String outcome = 'تم عمل طلبية';
    Customer? selectedCustomer;
    bool isSaving = false;
    final List<Map<String, dynamic>> returnItemsList = [];

    await _fetchAllProducts();

    final dialog = showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkSlate,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_available_rounded, color: AppTheme.primaryGold, size: 24),
                            const SizedBox(width: 8),
                            Text('تسجيل زيارة ميدانية جديدة',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<Customer>(
                          value: selectedCustomer,
                          isExpanded: true,
                          dropdownColor: AppTheme.cardSlate,
                          style: GoogleFonts.cairo(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'العميل',
                            labelStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                            border: const OutlineInputBorder(),
                          ),
                          items: _customers.map((customer) {
                            return DropdownMenuItem(
                              value: customer,
                              child: Text(
                                '${customer.name} • ${customer.code}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (customer) => setModalState(() => selectedCustomer = customer),
                        ),
                        if (_isLoadingCustomers)
                          const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator())
                        else if (_customers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('لا يوجد عملاء مرتبطون', style: GoogleFonts.cairo(color: Colors.orangeAccent)),
                          ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: visitType,
                          dropdownColor: AppTheme.cardSlate,
                          style: GoogleFonts.cairo(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'غرض الزيارة',
                            labelStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            'زيارة بيع وطلبية',
                            'زيارة تحصيل رصيد',
                            'زيارة دورية ومتابعة',
                          ].map((value) => DropdownMenuItem(value: value, child: Text(value, style: GoogleFonts.cairo(color: Colors.white70)))).toList(),
                          onChanged: (val) => setModalState(() => visitType = val!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: outcome,
                          dropdownColor: AppTheme.cardSlate,
                          style: GoogleFonts.cairo(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'نتيجة الزيارة',
                            labelStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            'تم عمل طلبية',
                            'تم التحصيل',
                            'متابعة لاحقة',
                            'لم يتم مقابلة العميل',
                            'تم تسجيل مرتجع',
                          ].map((value) => DropdownMenuItem(value: value, child: Text(value, style: GoogleFonts.cairo(color: Colors.white70)))).toList(),
                          onChanged: (value) => setModalState(() {
                            outcome = value ?? outcome;
                            if (outcome != 'تم تسجيل مرتجع') {
                              returnItemsList.clear();
                            }
                          }),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(visitReasonController, 'سبب الزيارة', Icons.description, isMultiLine: false),
                        if (outcome != 'تم تسجيل مرتجع') ...[
                          const SizedBox(height: 12),
                          _buildTextField(amountController, 'المبلغ المحصل (ج.م)', Icons.payments, isNumber: true),
                        ],
                        const SizedBox(height: 12),
                        _buildTextField(notesController, 'ملاحظات إضافية', Icons.note, isMultiLine: true),
                        if (outcome == 'تم تسجيل مرتجع') ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('أصناف المرتجع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                              TextButton.icon(
                                onPressed: () => _showAddReturnItem(context, setModalState, returnItemsList),
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGold),
                                label: Text('إضافة صنف', style: GoogleFonts.cairo(color: AppTheme.primaryGold)),
                              )
                            ],
                          ),
                          if (returnItemsList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('لم يتم إضافة أصناف بعد', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 11)),
                            )
                          else
                            ...returnItemsList.asMap().entries.map((entry) {
                              return Stack(
                                children: [
                                  _buildReturnItemTile(entry.value, setModalState),
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                      onPressed: () => setModalState(() => returnItemsList.removeAt(entry.key)),
                                    ),
                                  )
                                ],
                              );
                            }),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              foregroundColor: AppTheme.darkSlate,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.darkSlate))
                                : const Icon(Icons.check_circle_outline),
                            label: Text(isSaving ? 'جارٍ الحفظ...' : 'حفظ الزيارة',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                            onPressed: isSaving || selectedCustomer == null
                                ? null
                                : () async {
                                    final amountInput = amountController.text.trim();
                                    double collectedAmount = 0.0;
                                    final isReturn = outcome == 'تم تسجيل مرتجع';
                                    if (!isReturn) {
                                      collectedAmount = amountInput.isEmpty ? 0.0 : (double.tryParse(amountInput) ?? -1);
                                      if (collectedAmount < 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل مبلغ تحصيل صحيحًا')));
                                        return;
                                      }
                                      if (outcome == 'تم التحصيل' && collectedAmount == 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل مبلغ التحصيل')));
                                        return;
                                      }
                                    }

                                    setModalState(() => isSaving = true);
                                    final visitNotes = notesController.text.trim();
                                    final visitReason = visitReasonController.text.trim();

                                    try {
                                      final now = DateTime.now();
                                      final newVisit = CustomerVisit(
                                        id: 'vis_${now.millisecondsSinceEpoch}',
                                        customerId: selectedCustomer!.id,
                                        customerCode: selectedCustomer!.code,
                                        customerName: selectedCustomer!.name,
                                        repName: widget.currentUser.name,
                                        repId: widget.currentUser.id,
                                        branchName: widget.currentUser.branchName,
                                        date: now,
                                        checkInTime: now.toIso8601String(),
                                        type: visitType,
                                        outcome: outcome,
                                        status: 'executed',
                                        collectedAmount: isReturn ? 0.0 : collectedAmount,
                                        notes: visitReason.isNotEmpty
                                            ? 'سبب الزيارة: $visitReason${visitNotes.isNotEmpty ? '\n$visitNotes' : ''}'
                                            : visitNotes,
                                        isReturn: isReturn,
                                        returnReason: visitReason.isNotEmpty ? visitReason : null,
                                        returnItems: isReturn && returnItemsList.isNotEmpty ? jsonEncode(returnItemsList) : null,
                                        createdBy: widget.currentUser.id,
                                      );
                                      final success = await SupabaseService.instance.logVisit(newVisit);
                                      if (!success) throw StateError('تعذر حفظ الزيارة');
                                      if (!mounted) return;
                                      final matchesDate = _selectedDate == null ||
                                          (_selectedDate!.year == now.year && _selectedDate!.month == now.month && _selectedDate!.day == now.day);
                                      if (matchesDate) {
                                        setState(() => _visits.insert(0, newVisit));
                                      }
                                      if (_selectedDate == null) {
                                        try {
                                          await _saveCache(_visits);
                                        } catch (_) {}
                                      }
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('تم حفظ الزيارة بنجاح')));
                                    } catch (e) {
                                      if (mounted) {
                                        if (ctx.mounted) setModalState(() => isSaving = false);
                                        ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('لم يتم حفظ الزيارة: $e')));
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await dialog.whenComplete(() {
      notesController.dispose();
      amountController.dispose();
      visitReasonController.dispose();
    });
  }

  Future<void> _selectVisitDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'اختر يوم الزيارات',
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
    await _fetchVisits();
  }

  Future<void> _archiveVisit(CustomerVisit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('أرشفة الزيارة', style: GoogleFonts.cairo()),
        content: Text('هل تريد إخفاء زيارة ${visit.customerName} من السجل؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('إلغاء', style: GoogleFonts.cairo())),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('أرشفة', style: GoogleFonts.cairo())),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final archived = await SupabaseService.instance.archiveVisit(
      visitId: visit.id,
      archivedBy: widget.currentUser.id,
    );
    if (!mounted) return;
    if (!archived) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر أرشفة الزيارة')));
      return;
    }
    setState(() => _visits.removeWhere((item) => item.id == visit.id));
    if (_selectedDate == null) {
      try {
        await _saveCache(_visits);
      } catch (_) {}
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت أرشفة الزيارة')));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, bool isMultiLine = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : (isMultiLine ? TextInputType.multiline : TextInputType.text),
      maxLines: isMultiLine ? 3 : 1,
      style: GoogleFonts.cairo(color: Colors.white70),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppTheme.primaryGold, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGold)),
        filled: true,
        fillColor: AppTheme.cardSlate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('سجل الزيارات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        actions: [
          if (_isOffline)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.wifi_off_rounded, color: Colors.orange)),
          IconButton(
            tooltip: _selectedDate == null ? 'فلترة حسب التاريخ' : 'التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
            onPressed: _selectVisitDate,
          ),
          if (_selectedDate != null)
            IconButton(
              tooltip: 'إلغاء فلتر التاريخ',
              icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.white70),
              onPressed: () async {
                setState(() => _selectedDate = null);
                await _fetchVisits();
              },
            ),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white70), onPressed: _fetchVisits),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.darkSlate,
        icon: const Icon(Icons.add_rounded),
        label: Text('تسجيل زيارة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        onPressed: _showNewVisitDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : Column(
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.orange.withOpacity(0.16),
                    child: Text(
                      _visits.isEmpty ? 'تعذر الاتصال، ولا توجد زيارات محفوظة لعرضها.' : 'أنت غير متصل؛ المعروض بيانات محفوظة',
                      style: GoogleFonts.cairo(color: Colors.orangeAccent),
                    ),
                  ),
                Expanded(
                  child: _visits.isEmpty
                      ? _buildEmptyState()
                      : ResponsiveLayout(
                          mobile: _buildVisitsList(),
                          desktop: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: _buildVisitsList())),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildVisitsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _visits.length,
      itemBuilder: (context, index) {
        final v = _visits[index];
        List<dynamic> returnItems = [];
        if (v.isReturn == true && v.returnItems != null && v.returnItems!.isNotEmpty) {
          try {
            returnItems = jsonDecode(v.returnItems!);
          } catch (_) {}
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.cardSlate,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: Text(v.customerName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white))),
                          if (v.isReturn == true)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                              child: Text('مرتجع', style: GoogleFonts.cairo(fontSize: 10, color: Colors.redAccent)),
                            ),
                        ],
                      ),
                    ),
                    Text(DateFormat('yyyy-MM-dd\nHH:mm').format(v.date), style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade400)),
                    IconButton(
                      tooltip: 'أرشفة الزيارة',
                      onPressed: _isOffline ? null : () => _archiveVisit(v),
                      icon: const Icon(Icons.archive_outlined),
                      color: Colors.white54,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.darkBorder, borderRadius: BorderRadius.circular(6)),
                      child: Text(v.type, style: GoogleFonts.cairo(fontSize: 11, color: Colors.blue.shade300)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.darkBorder, borderRadius: BorderRadius.circular(6)),
                      child: Text(v.outcome, style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70)),
                    ),
                    if (v.isReturn != true && v.collectedAmount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.emeraldGreen, borderRadius: BorderRadius.circular(6)),
                        child: Text('محصل: ${v.collectedAmount.toStringAsFixed(0)} ج.م', style: GoogleFonts.cairo(fontSize: 11, color: Colors.green.shade300, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                if (v.returnReason != null && v.returnReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('سبب المرتجع: ${v.returnReason!}', style: GoogleFonts.cairo(fontSize: 11, color: Colors.orangeAccent)),
                ],
                if (returnItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('أصناف المرتجع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 6),
                  ...returnItems.map((item) {
                    final name = item['productName'] ?? '';
                    final code = item['productCode'] ?? '';
                    final qty = item['quantity'] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 14),
                          const SizedBox(width: 6),
                          Expanded(child: Text('$name ${code.isNotEmpty ? "($code)" : ""}', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white70))),
                          Text('الكمية: $qty', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white54)),
                        ],
                      ),
                    );
                  }),
                ],
                if (v.notes != null && v.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(v.notes!, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pin_drop_rounded, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text('لا توجد زيارات مسجلة بعد', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('اضغط على زر "تسجيل زيارة" للبدء', style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
