import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class VisitsScreen extends StatefulWidget {
  final AppUser currentUser;
  const VisitsScreen({super.key, required this.currentUser});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  List<CustomerVisit> _visits = [];
  bool _isLoading = true;
  bool _isOffline = false;
  static const String _cacheKey = 'visits_cache_${"USER"}';

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  Future<void> _fetchVisits() async {
    setState(() => _isLoading = true);

    try {
      final data = await SupabaseService.instance.fetchVisits(repName: widget.currentUser.name);
      if (data.isNotEmpty) {
        _visits = data;
        await _saveCache(data);
      } else {
        _visits = await _loadCache();
      }
      setState(() => _isOffline = false);
    } catch (e) {
      setState(() {
        _isOffline = true;
        _visits = [];
      });
      final cached = await _loadCache();
      if (cached.isNotEmpty) {
        setState(() => _visits = cached);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveCache(List<CustomerVisit> visits) async {
    final prefs = await SharedPreferences.getInstance();
    final json = visits.map((v) => jsonEncode({
          'id': v.id,
          'customerId': v.customerId,
          'customerName': v.customerName,
          'repName': v.repName,
          'date': v.date.toIso8601String(),
          'type': v.type,
          'outcome': v.outcome,
          'collectedAmount': v.collectedAmount,
          'notes': v.notes,
        })).toList();
    await prefs.setStringList(_cacheKey.replaceFirst('USER', widget.currentUser.id), json);
  }

  Future<List<CustomerVisit>> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList(_cacheKey.replaceFirst('USER', widget.currentUser.id));
      if (cached == null || cached.isEmpty) return [];
      return cached.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return CustomerVisit(
          id: map['id'] as String,
          customerId: map['customerId'] as String,
          customerName: map['customerName'] as String,
          repName: map['repName'] as String,
          date: DateTime.parse(map['date'] as String),
          type: map['type'] as String,
          outcome: map['outcome'] as String? ?? 'N/A',
          collectedAmount: (map['collectedAmount'] as num?)?.toDouble() ?? 0.0,
          notes: map['notes'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _showNewVisitDialog() {
    final customerController = TextEditingController();
    final notesController = TextEditingController();
    final amountController = TextEditingController();
    String visitType = 'زيارة بيع وطلبية';
    String outcome = 'تم عمل طلبية';

    showModalBottomSheet(
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
              color: const Color(0xFF0F172A),
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
                          const Icon(Icons.pin_drop_rounded, color: AppTheme.primaryGold, size: 24),
                          const SizedBox(width: 8),
                          Text('تسجيل زيارة ميدانية جديدة',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(customerController, 'اسم العميل / المتجر', Icons.person_outline),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: visitType,
                        dropdownColor: const Color(0xFF1E293B),
                        style: GoogleFonts.cairo(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'غرض الزيارة',
                          labelStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
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
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('حفظ الزيارة',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () async {
                            final newVisit = CustomerVisit(
                              id: 'vis_${DateTime.now().millisecondsSinceEpoch}',
                              customerId: 'c_temp',
                              customerName: customerController.text.isNotEmpty ? customerController.text : 'عميل عام',
                              repName: widget.currentUser.name,
                              date: DateTime.now(),
                              type: visitType,
                              outcome: outcome,
                              collectedAmount: double.tryParse(amountController.text) ?? 0.0,
                              notes: notesController.text,
                            );

                            await SupabaseService.instance.logVisit(newVisit);
                            setState(() => _visits.insert(0, newVisit));
                            Navigator.pop(ctx);
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
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryGold)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _fetchVisits,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.darkSlate,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text('تسجيل زيارة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        onPressed: _showNewVisitDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _visits.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _visits.length,
                  itemBuilder: (context, index) {
                    final v = _visits[index];
                    return Dismissible(
                      key: Key(v.id),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerEnd,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        setState(() => _visits.removeAt(index));
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF1E293B),
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
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF334155), borderRadius: BorderRadius.circular(6)),
                                    child: Text(v.type,
                                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.blue.shade300)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (v.collectedAmount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF064E35), borderRadius: BorderRadius.circular(6)),
                                      child: Text('محصل: ${v.collectedAmount.toStringAsFixed(0)} ج.م',
                                          style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              color: Colors.green.shade300,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              if (v.notes != null && v.notes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('ملاحظة: ${v.notes!}',
                                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade400)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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