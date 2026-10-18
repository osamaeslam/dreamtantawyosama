import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/pdf_invoice_service.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'returns_screen.dart';

class InvoicesScreen extends StatefulWidget {
  final AppUser currentUser;
  const InvoicesScreen({super.key, required this.currentUser});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<OrderInvoice> _invoices = [];
  bool _isLoading = true;
  String _selectedStatus = 'الكل';

  RoleAccessController get rbac => RoleAccessController(widget.currentUser);

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  void _fetchInvoices() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.instance.fetchInvoices(
      repName: rbac.isSalesRep ? widget.currentUser.name : null,
      branchName: rbac.isAdmin ? null : widget.currentUser.branchName,
    );
    final visible = rbac.filterInvoices(data);
    if (data.isEmpty) {
      _invoices = [
        OrderInvoice(
          id: 'inv_101',
          invoiceNumber: 'INV-2026-0042',
          customerId: 'c1',
          customerName: 'معرض الأمل للأدوات المنزلية',
          customerCode: 'CUST-001',
          repId: widget.currentUser.id,
          repName: widget.currentUser.name,
          branchName: widget.currentUser.branchName,
          date: DateTime.now().subtract(const Duration(hours: 3)),
          items: [
            OrderItem(productId: 'p1', productCode: 'TNT-101', productName: 'طقم حلل جرانيت 10 قطع', cartons: 3, pieces: 0, cartonPrice: 1800, piecePrice: 450),
            OrderItem(productId: 'p3', productCode: 'TNT-103', productName: 'خلاط يدوي تورنيدو 1000 وات', cartons: 2, pieces: 0, cartonPrice: 1950, piecePrice: 350),
          ],
          subtotal: 9300,
          discount: 300,
          totalAmount: 9000,
          status: 'معتمد من المشرف',
          paymentType: 'آجل',
        ),
        OrderInvoice(
          id: 'inv_102',
          invoiceNumber: 'INV-2026-0041',
          customerId: 'c2',
          customerName: 'سنتر النور والبركة',
          customerCode: 'CUST-002',
          repId: widget.currentUser.id,
          repName: widget.currentUser.name,
          branchName: widget.currentUser.branchName,
          date: DateTime.now().subtract(const Duration(days: 1)),
          items: [
            OrderItem(productId: 'p4', productCode: 'TNT-104', productName: 'طقم علب ثلاجة 5 قطع', cartons: 5, pieces: 0, cartonPrice: 1080, piecePrice: 45),
          ],
          subtotal: 5400,
          totalAmount: 5400,
          status: 'تم الصرف',
          paymentType: 'نقدي',
        ),
      ];
    } else {
      _invoices = visible;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('سجل الفواتير والطلبيات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final inv = _invoices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkSlate,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    inv.invoiceNumber,
                                    style: GoogleFonts.cairo(color: AppTheme.secondaryGold, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(inv.date),
                                  style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: inv.status == 'تم الصرف'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                inv.status,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: inv.status == 'تم الصرف' ? const Color(0xFF059669) : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          inv.customerName,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${inv.items.length} أصناف | الدفع: ${inv.paymentType}',
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الإجمالي: ${inv.totalAmount.toStringAsFixed(2)} ج.م',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F766E)),
                            ),
                             Row(
                               children: [
                                 OutlinedButton.icon(
                                   icon: const Icon(Icons.print_outlined, size: 16),
                                   label: Text('طباعة حرارية', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: AppTheme.darkSlate,
                                     side: const BorderSide(color: AppTheme.darkSlate),
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                   ),
                                   onPressed: () => PdfInvoiceService.printInvoice(inv, isThermal: true),
                                 ),
                                 const SizedBox(width: 8),
                                 OutlinedButton.icon(
                                   icon: const Icon(Icons.assignment_return_outlined, size: 16, color: AppTheme.roseRed),
                                   label: Text('مرتجع', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.roseRed)),
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: AppTheme.roseRed,
                                     side: const BorderSide(color: AppTheme.roseRed),
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                   ),
                                   onPressed: () async {
                                     final result = await Navigator.push<bool>(
                                       context,
                                       MaterialPageRoute(
                                         builder: (context) => ReturnsScreen(currentUser: widget.currentUser, invoice: inv),
                                       ),
                                     );
                                     if (result == true && mounted) {
                                       _fetchInvoices();
                                     }
                                   },
                                 ),
                                 const SizedBox(width: 8),
                                 IconButton(
                                   icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                                   tooltip: 'تصدير A4 PDF',
                                   onPressed: () => PdfInvoiceService.printInvoice(inv, isThermal: false),
                                 ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
