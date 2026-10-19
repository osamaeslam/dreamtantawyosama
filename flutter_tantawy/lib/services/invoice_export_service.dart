import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';

class InvoiceExportService {
  static Future<void> shareExcel(OrderInvoice invoice) async {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Invoice');
    final sheet = workbook['Invoice'];
    sheet.appendRow([
      TextCellValue('فاتورة العميل'),
      TextCellValue(invoice.invoiceNumber),
    ]);
    sheet.appendRow([
      TextCellValue('تاريخ الفاتورة'),
      TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(invoice.date)),
    ]);
    sheet.appendRow([
      TextCellValue('العميل'),
      TextCellValue(invoice.customerName),
    ]);
    sheet.appendRow([
      TextCellValue('كود العميل'),
      TextCellValue(invoice.customerCode),
    ]);
    sheet.appendRow([
      TextCellValue('المندوب'),
      TextCellValue(invoice.repName ?? ''),
    ]);
    sheet.appendRow([
      TextCellValue('الفرع'),
      TextCellValue(invoice.branchName ?? ''),
    ]);
    sheet.appendRow([
      TextCellValue('طريقة الدفع'),
      TextCellValue(invoice.paymentType),
    ]);
    sheet.appendRow([
      TextCellValue('الحالة'),
      TextCellValue(invoice.status),
    ]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('كود الصنف'),
      TextCellValue('اسم الصنف'),
      TextCellValue('اللون'),
      TextCellValue('الكرتون'),
      TextCellValue('القطع'),
      TextCellValue('سعر الكرتونة'),
      TextCellValue('سعر القطعة'),
      TextCellValue('الإجمالي'),
    ]);

    for (final item in invoice.items) {
      sheet.appendRow([
        TextCellValue(item.productCode),
        TextCellValue(item.productName),
        TextCellValue(item.color ?? ''),
        IntCellValue(item.cartons),
        IntCellValue(item.pieces),
        DoubleCellValue(item.cartonPrice),
        DoubleCellValue(item.piecePrice),
        DoubleCellValue(item.totalPrice),
      ]);
    }

    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('المجموع قبل الخصم'),
      DoubleCellValue(invoice.subtotal),
    ]);
    sheet.appendRow([
      TextCellValue('الخصم'),
      DoubleCellValue(invoice.discount),
    ]);
    sheet.appendRow([
      TextCellValue('صافي الفاتورة'),
      DoubleCellValue(invoice.totalAmount),
    ]);
    _styleRow(sheet, 0, 2, CellStyle(bold: true, fontSize: 16));
    for (var row = 1; row <= 7; row++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .cellStyle = CellStyle(bold: true);
    }
    _styleRow(sheet, 9, 8, CellStyle(bold: true, fontSize: 11));
    for (var row = invoice.items.length + 11;
        row <= invoice.items.length + 13;
        row++) {
      _styleRow(sheet, row, 2, CellStyle(bold: true));
    }
    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 36);
    sheet.setColumnWidth(2, 18);
    for (var column = 3; column < 8; column++) {
      sheet.setColumnWidth(column, 18);
    }

    final filename = 'فاتورة_${invoice.invoiceNumber}.xlsx';
    if (kIsWeb) {
      final downloaded = workbook.save(fileName: filename);
      if (downloaded == null || downloaded.isEmpty) {
        throw StateError(
          'تعذر إنشاء ملف Excel للفاتورة ${invoice.invoiceNumber}',
        );
      }
      return;
    }

    final bytes = workbook.save();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('تعذر إنشاء ملف Excel للفاتورة ${invoice.invoiceNumber}');
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          name: filename,
        ),
      ],
      subject: filename,
      text: 'فاتورة ${invoice.invoiceNumber} - ${invoice.customerName}',
    );
  }

  static void _styleRow(Sheet sheet, int row, int columns, CellStyle style) {
    for (var column = 0; column < columns; column++) {
      sheet
          .cell(CellIndex.indexByColumnRow(
            columnIndex: column,
            rowIndex: row,
          ))
          .cellStyle = style;
    }
  }
}
