import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class PdfInvoiceService {
  static Future<void> printInvoice(
    OrderInvoice invoice, {
    bool isThermal = true,
  }) async {
    final bytes = await _buildInvoicePdf(invoice, isThermal: isThermal);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'فاتورة_${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<void> shareInvoicePdf(OrderInvoice invoice) async {
    final bytes = await _buildInvoicePdf(invoice, isThermal: false);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'فاتورة_${invoice.invoiceNumber}.pdf',
    );
  }

  static Future<Uint8List> _buildInvoicePdf(
    OrderInvoice invoice, {
    required bool isThermal,
  }) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf').catchError((_) {
      return rootBundle.load('fonts/Cairo-Regular.ttf');
    });
    final arabicFont = pw.Font.ttf(fontData);

    final pageFormat = isThermal
        ? PdfPageFormat(
            72 * PdfPageFormat.mm,
            300.0 + invoice.items.length * 48.0,
            marginAll: 4 * PdfPageFormat.mm,
          )
        : PdfPageFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicFont),
        build: (pw.Context context) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
              // رأس الفاتورة
              pw.Center(
                child: pw.Text(
                  'مجموعة الطنطاوي للتجارة والتوزيع',
                  style: pw.TextStyle(fontSize: isThermal ? 13 : 18, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'فاتورة مبيعات  •  ${invoice.invoiceNumber}',
                  style: pw.TextStyle(fontSize: isThermal ? 10 : 13),
                ),
              ),
              pw.Divider(thickness: 1),

              // بيانات العميل والمندوب
              pw.Text('العميل: ${invoice.customerName} (${invoice.customerCode})', style: const pw.TextStyle(fontSize: 10)),
              if (invoice.customerPhone?.isNotEmpty == true)
                pw.Text('الهاتف: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 9)),
               pw.Text('المندوب: ${invoice.repName} | الفرع: ${invoice.branchName}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(invoice.date)}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('طريقة الدفع: ${invoice.paymentType}', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('حالة الفاتورة: ${invoice.status}', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(thickness: 0.5),

              // جدول الأصناف
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(1.4),
                  3: pw.FlexColumnWidth(1.5),
                },
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                children: [
                  // الهيدر
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('الصنف', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('الكمية', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('سعر الكرتونة', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('إجمالي', style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                  // السطور
                  ...invoice.items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.productName, style: const pw.TextStyle(fontSize: 8)),
                              pw.Text(
                                '${item.productCode}${item.color == null ? '' : ' • ${item.color}'}',
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text(
                            '${item.cartons} كرتون\n${item.pieces} قطعة',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(item.cartonPrice.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(item.totalPrice.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8))),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 8),

              // الإجماليات
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('المجموع قبل الخصم:'),
                  pw.Text('${invoice.subtotal.toStringAsFixed(2)} ج.م'),
                ],
              ),
              if (invoice.discount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('قيمة الخصم:'),
                    pw.Text('- ${invoice.discount.toStringAsFixed(2)} ج.م'),
                  ],
                ),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الصافي النهائي:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('${invoice.totalAmount.toStringAsFixed(2)} ج.م', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.BarcodeWidget(
                  data: invoice.invoiceNumber,
                  barcode: pw.Barcode.qrCode(),
                  width: 50,
                  height: 50,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'شكراً لتعاملكم مع مجموعة الطنطاوي',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
