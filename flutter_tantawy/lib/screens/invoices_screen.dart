import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/invoice_export_service.dart';
import '../services/pdf_invoice_service.dart';
import '../services/role_access_controller.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
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
    _invoices = visible;
    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildStatusStepper(OrderInvoice inv, bool isDark) {
    final statuses = NotificationService.getOrderStatuses();
    final currentStep = NotificationService.getStatusStep(inv.status);

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: statuses.length,
        separatorBuilder: (_, i) => Container(
          width: 16,
          alignment: Alignment.center,
          child: Container(
            width: 8,
            height: 2,
            color: (currentStep > 0 && currentStep > i + 1) || (currentStep < 0 && i == 0)
                ? NotificationService.getStatusColor(inv.status, isDark)
                : Colors.grey.shade300,
          ),
        ),
        itemBuilder: (context, i) {
          final status = statuses[i];
          final isCompleted = currentStep > 0 && (i + 1) < currentStep;
          final isActive = currentStep > 0 && (i + 1) == currentStep;
          final color = isActive
              ? NotificationService.getStatusColor(inv.status, isDark)
              : isCompleted
                  ? NotificationService.getStatusColor(status, isDark)
                  : isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    NotificationService.getStatusIcon(status),
                    style: GoogleFonts.cairo(fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: GoogleFonts.cairo(fontSize: 8, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _shareExcel(OrderInvoice invoice) async {
    try {
      await InvoiceExportService.shareExcel(invoice);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تصدير Excel: $error')),
      );
    }
  }

  Future<void> _sharePdf(OrderInvoice invoice) async {
    try {
      await PdfInvoiceService.shareInvoicePdf(invoice);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تصدير PDF: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppTheme.darkSlate,
        title: Text('سجل الفواتير والطلبيات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد فواتير مسجلة.',
                    style: GoogleFonts.cairo(color: AppTheme.textMuted),
                  ),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final inv = _invoices[index];
                final itemsForStockReview = inv.items
                    .where((item) =>
                        item.needsOctoberSupply == true ||
                        (item.shortageCartons ?? 0) > 0)
                    .toList();
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
                                 color: NotificationService.getStatusColor(inv.status, isDark).withValues(alpha: 0.15),
                                 borderRadius: BorderRadius.circular(20),
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Text(
                                     NotificationService.getStatusIcon(inv.status),
                                     style: GoogleFonts.cairo(fontSize: 12),
                                   ),
                                   const SizedBox(width: 4),
                                   Text(
                                     NotificationService.getStatusLabel(inv.status),
                                     style: GoogleFonts.cairo(
                                       fontSize: 11,
                                       fontWeight: FontWeight.bold,
                                       color: NotificationService.getStatusColor(inv.status, isDark),
                                     ),
                                   ),
                                 ],
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
                         const SizedBox(height: 8),
                         _buildStatusStepper(inv, isDark),
                         if (itemsForStockReview.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'مراجعة المخزون: ${itemsForStockReview.map((item) {
                                final requiredFromOctober = (item.cartons -
                                        (item.branchStockAtOrder ?? 0))
                                    .clamp(0, item.cartons)
                                    .toInt();
                                final octoberAvailable =
                                    item.octoberStockAtOrder ?? 0;
                                final transferQuantity =
                                    requiredFromOctober < octoberAvailable
                                        ? requiredFromOctober
                                        : octoberAvailable;
                                final shortage = (requiredFromOctober -
                                        transferQuantity)
                                    .clamp(0, item.cartons)
                                    .toInt();
                                return item.needsOctoberSupply == true
                                    ? '${item.productName}: تحويل $transferQuantity من أكتوبر${shortage > 0 ? '، عجز $shortage' : ''}'
                                    : '${item.productName}: عجز $shortage';
                              }).join('، ')}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkSlate,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'الإجمالي: ${inv.totalAmount.toStringAsFixed(2)} ج.م',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              alignment: WrapAlignment.start,
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
                                 OutlinedButton.icon(
                                   icon: const Icon(Icons.table_view_outlined, size: 16),
                                   label: Text('Excel', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold)),
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: const Color(0xFF15803D),
                                     side: const BorderSide(color: Color(0xFF15803D)),
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                   ),
                                   onPressed: () => _shareExcel(inv),
                                 ),
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
                                 OutlinedButton.icon(
                                   icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.red),
                                   label: Text('PDF', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                   style: OutlinedButton.styleFrom(
                                     foregroundColor: Colors.red,
                                     side: const BorderSide(color: Colors.red),
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                   ),
                                   onPressed: () => _sharePdf(inv),
                                 ),
                              ],
                            )
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



