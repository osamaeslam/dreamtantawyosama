import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

class PdfCatalogService {
  static Future<Uint8List> buildCatalogPdf(List<ParentProduct> products) async {
    final pdf = pw.Document();

    final regularFont = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldFont = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final ttfRegular = pw.Font.ttf(regularFont);
    final ttfBold = pw.Font.ttf(boldFont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        header: (context) => pw.Container(
          alignment: pw.Alignment.center,
          child: pw.Text(
            'كتالوج المنتجات',
            style: pw.TextStyle(font: ttfBold, fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        ),
        body: (context) => products.asMap().entries.map((entry) {
          final product = entry.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 24),
            child: _buildProductBlock(product, ttfRegular, ttfBold),
          );
        }).toList(growable: false),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildProductBlock(ParentProduct product, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                product.name,
                style: pw.TextStyle(font: boldFont, fontSize: 14, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
                textDirection: pw.TextDirection.rtl,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              product.primaryCode,
              style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'القسم: ${product.department}  •  الفئة: ${product.category}',
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
          textAlign: pw.TextAlign.right,
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: product.variants.map((variant) {
            return pw.Container(
              width: 160,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 100,
                    width: 160,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: _buildVariantImage(variant),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(variant.code, style: pw.TextStyle(font: boldFont, fontSize: 9)),
                  pw.Text(variant.color, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
                  pw.Text(variant.name, style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${variant.effectiveCartonPrice.toStringAsFixed(0)} ج.م / كرتونة (${variant.cartonQuantity} قطعة)',
                    style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.teal800),
                  ),
                  if (variant.hasPromo && variant.promoPrice != null)
                    pw.Text(
                      '${variant.promoPrice!.toStringAsFixed(0)} ج.م (خصم)',
                      style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.red),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'متوفر: فرع ${variant.availableStock} • مخزن ${variant.octoberAvailableStock}',
                    style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.green700),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildVariantImage(ProductVariant variant) {
    if (variant.imageUrl == null || variant.imageUrl!.isEmpty) {
      return pw.Icon(
        pw.IconData(0xe033),
        size: 48,
        color: PdfColors.grey400,
      );
    }
    return pw.Image(
      pw.NetworkImage(variant.imageUrl!),
      fit: pw.BoxFit.contain,
      width: 120,
      height: 100,
      loadingBuilder: (context, event) => pw.Center(
        child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
      ),
      errorBuilder: (context, error, stackTrace) => pw.Icon(
        pw.IconData(0xe033),
        size: 48,
        color: PdfColors.grey400,
      ),
    );
  }

  static Future<void> printCatalog(List<ParentProduct> products) async {
    final bytes = await buildCatalogPdf(products);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'كتالوج_المنتجات.pdf',
    );
  }

  static Future<void> shareCatalog(List<ParentProduct> products) async {
    final bytes = await buildCatalogPdf(products);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'كتالوج_المنتجات.pdf',
      subject: 'كتالوج منتجات',
    );
  }
}
