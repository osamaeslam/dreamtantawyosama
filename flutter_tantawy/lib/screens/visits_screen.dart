import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  bool _isLoading = true;
  bool _isLoadingCustomers = true;
  bool _isOffline = false;
  DateTime? _selectedDate;
  static const String _cacheKey = 'visits_cache_${"USER"}';

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _fetchVisits();
    _fetchCustomers();
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
    return visits.where((visit) =>
        visit.date.year == _selectedDate!.year &&
        visit.date.month == _selectedDate!.month &&
        visit.date.day == _selectedDate!.day);
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

  Future<void> _showNewVisitDialog() async {
    final notesController = TextEditingController();
    final amountController = TextEditingController();
    String visitType = 'زيارة بيع وطلبية';
    String outcome = 'تم عمل طلبية';
    Customer? selectedCustomer;
    bool isSaving = false;

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
                          labelText: 'العميل المرتبط بالمندوب',
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
                        onChanged: (customer) => setModalState(
                          () => selectedCustomer = customer,
                        ),
                      ),
                      if (_isLoadingCustomers)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(),
                        )
                      else if (_customers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'لا يوجد عملاء مرتبطون بهذا الحساب.',
                            style: GoogleFonts.cairo(color: Colors.orangeAccent),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: visitType,
                        dropdownColor: AppTheme.cardSlate,
                        style: GoogleFonts.cairo(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'غرض الزيارة',
                          labelStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'زيارة بيع وطلبية',
                            child: Text('زيارة بيع وطلبية', style: GoogleFonts.cairo(color: Colors.white70)),
                          ),
                          DropdownMenuItem(
                            value: 'زيارة تحصيل رصيد',
                            child: Text('زيارة تحصيل رصيد', style: GoogleFonts.cairo(color: Colors.white70)),
                          ),
                          DropdownMenuItem(
                            value: 'زيارة دورية ومتابعة',
                            child: Text('زيارة دورية ومتابعة', style: GoogleFonts.cairo(color: Colors.white70)),
                          ),
                        ],
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
                        ].map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            )).toList(),
                        onChanged: (value) => setModalState(
                          () => outcome = value ?? outcome,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(amountController, 'المبلغ المحصل (ج.م)', Icons.payments, isNumber: true),
                      const SizedBox(height: 12),
                      _buildTextField(notesController, 'ملاحظات الزيارة أو المرتجع', Icons.note, isMultiLine: true),
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
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.darkSlate,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(isSaving ? 'جارٍ الحفظ...' : 'حفظ الزيارة',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: isSaving || selectedCustomer == null
                              ? null
                              : () async {
                                  final amountInput = amountController.text.trim();
                                  final collectedAmount = amountInput.isEmpty
                                      ? 0.0
                                      : double.tryParse(amountInput);
                                  if (collectedAmount == null ||
                                      collectedAmount < 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('أدخل مبلغ تحصيل صحيحًا وغير سالب.'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (outcome == 'تم التحصيل' &&
                                      collectedAmount == 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('أدخل مبلغ التحصيل قبل تسجيل نتيجة التحصيل.'),
                                      ),
                                    );
                                    return;
                                  }
                                  setModalState(() => isSaving = true);
                                  final visitNotes = notesController.text.trim();
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
                                      collectedAmount: collectedAmount,
                                      notes: visitNotes,
                                      createdBy: widget.currentUser.id,
                                    );
                                    final success =
                                        await SupabaseService.instance
                                            .logVisit(newVisit);
                                    if (!success) {
                                      throw StateError('تعذر حفظ الزيارة في قاعدة البيانات.');
                                    }
                                    if (!mounted) return;
                                    final matchesDate = _selectedDate == null ||
                                        (_selectedDate!.year == now.year &&
                                            _selectedDate!.month == now.month &&
                                            _selectedDate!.day == now.day);
                                    if (matchesDate) {
                                      setState(() => _visits.insert(0, newVisit));
                                    }
                                    if (_selectedDate == null) {
                                      try {
                                        await _saveCache(_visits);
                                      } catch (e) {
                                        debugPrint('تعذر تحديث ذاكرة الزيارات المؤقتة: $e');
                                      }
                                    }
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    ScaffoldMessenger.of(this.context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم حفظ الزيارة بنجاح.'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      if (ctx.mounted) {
                                        setModalState(() => isSaving = false);
                                      }
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(content: Text('لم يتم حفظ الزيارة: $e')),
                                      );
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
    );
    await dialog.whenComplete(() {
      notesController.dispose();
      amountController.dispose();
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
        content: Text(
          'هل تريد إخفاء زيارة ${visit.customerName} من السجل؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('أرشفة', style: GoogleFonts.cairo()),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر أرشفة الزيارة. لم يتم تغيير السجل.')),
      );
      return;
    }
    setState(() => _visits.removeWhere((item) => item.id == visit.id));
    if (_selectedDate == null) {
      try {
        await _saveCache(_visits);
      } catch (e) {
        debugPrint('تعذر تحديث ذاكرة الزيارات المؤقتة بعد الأرشفة: $e');
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت أرشفة الزيارة.')),
    );
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
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.darkBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGold)),
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
        title: Text('سجل الزيارات والتحصيلات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
        actions: [
          if (_isOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.wifi_off_rounded, color: Colors.orange),
            ),
          IconButton(
            tooltip: _selectedDate == null
                ? 'فلترة حسب التاريخ'
                : 'التاريخ: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchVisits,
          ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: Colors.orange.withValues(alpha: 0.16),
                    child: Text(
                      _visits.isEmpty
                          ? 'تعذر الاتصال، ولا توجد زيارات محفوظة لعرضها.'
                          : 'أنت غير متصل؛ المعروض بيانات محفوظة وقد لا تكون محدثة.',
                      style: GoogleFonts.cairo(color: Colors.orangeAccent),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: _buildVisitsOverview(),
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'زيارات ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                        style: GoogleFonts.cairo(color: Colors.white70),
                      ),
                    ),
                  ),
                Expanded(
                  child: _visits.isEmpty
                      ? _buildEmptyState()
                      : ResponsiveLayout(
                          mobile: _buildVisitsList(),
                          desktop: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: _buildVisitsList(),
                            ),
                          ),
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
                        child: Text(v.customerName,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ),
                      Text(DateFormat('yyyy-MM-dd\nHH:mm').format(v.date),
                          style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade400)),
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
                        decoration: BoxDecoration(
                            color: AppTheme.darkBorder, borderRadius: BorderRadius.circular(6)),
                        child: Text(v.type,
                            style: GoogleFonts.cairo(fontSize: 11, color: Colors.blue.shade300)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBorder,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          v.outcome,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      if (v.collectedAmount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppTheme.emeraldGreen, borderRadius: BorderRadius.circular(6)),
                          child: Text('محصل: ${v.collectedAmount.toStringAsFixed(0)} ج.م',
                              style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: Colors.green.shade300,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  if (v.latitude != null && v.longitude != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'موقع محفوظ من زيارة سابقة • ${v.latitude!.toStringAsFixed(5)}, ${v.longitude!.toStringAsFixed(5)}',
                      style: GoogleFonts.cairo(fontSize: 10, color: Colors.white54),
                    ),
                  ],
                  if (v.notes != null && v.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('ملاحظة: ${v.notes!}',
                        style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ],
              ),
            ),
        );
      },
    );
  }

  Widget _buildVisitsOverview() {
    final collected = _visits.fold<double>(
      0,
      (total, visit) => total + visit.collectedAmount,
    );
    final customersCount = _visits.map((visit) => visit.customerId).toSet().length;
    final dateLabel = DateFormat('yyyy/MM/dd')
        .format(_selectedDate ?? DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppTheme.secondaryGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'متابعة الزيارات',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_selectedDate == null ? 'كل السجل حتى' : 'الفترة المحددة'} • $dateLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppTheme.secondaryGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedDate == null ? 'كل السجل' : 'تاريخ محدد',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              return Row(
                children: [
                  Expanded(
                    child: _overviewMetric(
                      icon: Icons.fact_check_outlined,
                      label: 'الزيارات',
                      value: _visits.length.toString(),
                      compact: compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _overviewMetric(
                      icon: Icons.storefront_outlined,
                      label: 'عملاء تمت زيارتهم',
                      value: customersCount.toString(),
                      compact: compact,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _overviewMetric(
                      icon: Icons.payments_outlined,
                      label: 'إجمالي التحصيل',
                      value: '${NumberFormat('#,##0', 'ar_EG').format(collected)} ج.م',
                      compact: compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric({
    required IconData icon,
    required String label,
    required String value,
    required bool compact,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: EdgeInsets.all(compact ? 8 : 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppTheme.secondaryGold),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 12 : 14,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(color: Colors.white60, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pin_drop_rounded, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text('لا توجد زيارات مسجلة بعد',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade400)),
          const SizedBox(height: 8),
          Text('اضغط على زر "تسجيل زيارة" للبدء',
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}