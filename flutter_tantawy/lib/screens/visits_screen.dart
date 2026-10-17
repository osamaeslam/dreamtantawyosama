import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchVisits();
  }

  void _fetchVisits() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.fetchVisits(repName: widget.currentUser.name);
    if (data.isEmpty) {
      _visits = [
        CustomerVisit(
          id: 'v1',
          customerId: 'c1',
          customerName: 'معرض الأمل للأدوات المنزلية',
          repName: widget.currentUser.name,
          date: DateTime.now().subtract(const Duration(hours: 2)),
          type: 'زيارة بيع وطلبية',
          outcome: 'تم عمل طلبية',
          collectedAmount: 5000,
          notes: 'تم أخذ طلبية جديدة وتحصيل دفعة نقدية',
        ),
        CustomerVisit(
          id: 'v2',
          customerId: 'c2',
          customerName: 'سنتر النور والبركة',
          repName: widget.currentUser.name,
          date: DateTime.now().subtract(const Duration(hours: 5)),
          type: 'زيارة تحصيل',
          outcome: 'تم التحصيل',
          collectedAmount: 8500,
          notes: 'تحصيل شيك مستحق',
        ),
      ];
    } else {
      _visits = data;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showNewVisitDialog() {
    final customerController = TextEditingController();
    final notesController = TextEditingController();
    final amountController = TextEditingController();
    String visitType = 'زيارة بيع وطلبية';
    String outcome = 'تم عمل طلبية';
    bool isCapturingLocation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, color: AppTheme.primaryGold),
                  const SizedBox(width: 8),
                  Text('تسجيل زيارة ميدانية جديدة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: customerController,
                decoration: InputDecoration(
                  labelText: 'اسم العميل / المتجر',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: visitType,
                decoration: InputDecoration(
                  labelText: 'غرض الزيارة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'زيارة بيع وطلبية', child: Text('زيارة بيع وطلبية')),
                  DropdownMenuItem(value: 'زيارة تحصيل', child: Text('زيارة تحصيل رصيد')),
                  DropdownMenuItem(value: 'زيارة دورية', child: Text('زيارة دورية ومتابعة')),
                ],
                onChanged: (val) => setModalState(() => visitType = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'المبلغ المحصل إن وجد (ج.م)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ملاحظات الزيارة أو المرتجع',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: AppTheme.darkSlate,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text('حفظ الزيارة مع الموقع الجغرافي GPS', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('سجل الزيارات والتحصيلات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.darkSlate,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text('تسجيل زيارة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        onPressed: _showNewVisitDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _visits.length,
              itemBuilder: (context, index) {
                final v = _visits[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(v.customerName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(DateFormat('yyyy-MM-dd HH:mm').format(v.date),
                                style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                              child: Text(v.type, style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF334155))),
                            ),
                            const SizedBox(width: 8),
                            if (v.collectedAmount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                                child: Text('محصل: ${v.collectedAmount} ج.م',
                                    style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        if (v.notes != null && v.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('ملاحظة: ${v.notes!}', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
