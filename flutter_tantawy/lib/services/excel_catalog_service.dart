import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:printing/printing.dart';
import '../models/models.dart';

class ExcelCatalogService {
  static Future<Uint8List> buildCatalogExcel(List<ParentProduct> products) async {
    final excel = Excel.createExcel();
    final sheet = excel['كتالوج المنتجات'];

    _writeHeader(sheet, 0);
    int row = 1;

    for (final product in products) {
      final variantCount = product.variants.length;
      for (int i = 0; i < variantCount; i++) {
        final variant = product.variants[i];
        _writeRow(sheet, row, product, variant, i == 0 ? variantCount : 0);
        row++;
      }
      if (variantCount == 0) {
        _writeRow(sheet, row, product, null, 0);
        row++;
      }
    }

    _autoFitColumns(sheet, row);
    _applyAlternatingRowColors(sheet, row);

    return Uint8List.fromList(excel.encode()!);
  }

  static Future<void> shareCatalog(List<ParentProduct> products) async {
    final bytes = await buildCatalogExcel(products);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'كتالوج_المنتجات.xlsx',
      subject: 'كتالوج منتجات',
    );
  }

  static void _writeHeader(Sheet sheet, int row) {
    final headers = [
      'المنتج', 'كود المنتج', 'القسم', 'الفئة', 'كود المتغير', 'اللون',
      'اسم المتغير', 'سعر الكرتونة', 'سعر العرض', 'عدد القطع/كرتونة',
      'الخصم %', 'مخزون فرع', 'مخزون مخزن', 'حالة النفاذ', 'الأولوية',
    ];

    final headerCellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('FF1A73B3'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerCellStyle;
    }

    sheet.setColumnWidth(0, 40);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 25);
    sheet.setColumnWidth(3, 25);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 30);
    sheet.setColumnWidth(7, 16);
    sheet.setColumnWidth(8, 16);
    sheet.setColumnWidth(9, 18);
    sheet.setColumnWidth(10, 12);
    sheet.setColumnWidth(11, 16);
    sheet.setColumnWidth(12, 16);
    sheet.setColumnWidth(13, 14);
    sheet.setColumnWidth(14, 16);
  }

  static void _writeRow(Sheet sheet, int row, ParentProduct product, ProductVariant? variant, int rowspan) {
    final productStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('FF1A73B3'),
      verticalAlign: VerticalAlign.Center,
    );

    final variantStyle = CellStyle(fontSize: 9, verticalAlign: VerticalAlign.Center);

    int col = 0;

    _setCell(sheet, row, col++, product.name, productStyle, rowspan: rowspan);
    _setCell(sheet, row, col++, product.primaryCode, variantStyle);
    _setCell(sheet, row, col++, product.department, variantStyle);
    _setCell(sheet, row, col++, product.category, variantStyle);

    if (variant != null) {
      _setCell(sheet, row, col++, variant.code, variantStyle);
      _setCell(sheet, row, col++, variant.color, variantStyle);
      _setCell(sheet, row, col++, variant.name, variantStyle);
      _setCell(sheet, row, col++, variant.cartonPrice.toStringAsFixed(2), variantStyle);
      _setCell(sheet, row, col++, variant.promoPrice?.toStringAsFixed(2) ?? '', variantStyle);
      _setCell(sheet, row, col++, variant.cartonQuantity.toString(), variantStyle);

      if (variant.hasPromo && variant.promoPrice != null) {
        final discount = ((variant.cartonPrice - variant.promoPrice!) / variant.cartonPrice * 100).round();
        _setCell(sheet, row, col++, '$discount', variantStyle);
      } else {
        _setCell(sheet, row, col++, '', variantStyle);
      }

      _setCell(sheet, row, col++, variant.availableStock.toString(), variantStyle);
      _setCell(sheet, row, col++, variant.octoberAvailableStock.toString(), variantStyle);

      final stockStatus = variant.availableForOrder > 0 ? 'متوفر' : 'نفاد';
      final statusStyle = CellStyle(
        fontSize: 9,
        fontColorHex: variant.availableForOrder > 0
            ? ExcelColor.fromHexString('FF228B47')
            : ExcelColor.fromHexString('FFDC2626'),
        verticalAlign: VerticalAlign.Center,
      );
      _setCell(sheet, row, col++, stockStatus, statusStyle);
      _setCell(sheet, row, col++, product.salesPriority, variantStyle);
    } else {
      for (int i = 0; i < 8; i++) {
        _setCell(sheet, row, col++, '', variantStyle);
      }
      _setCell(sheet, row, col++, 'لا أختيار', variantStyle);
      _setCell(sheet, row, col++, product.salesPriority, variantStyle);
    }
  }

  static void _setCell(Sheet sheet, int row, int col, String value, CellStyle style, {int rowspan = 1}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = style;

    if (rowspan > 1 && value.isNotEmpty) {
      sheet.setRowHeight(row, 20);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + rowspan - 1),
      );
    }
  }

  static void _autoFitColumns(Sheet sheet, int maxRow) {
    for (int col = 0; col < 15; col++) {
      double maxWidth = 10;
      for (int row = 0; row <= maxRow; row++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        final text = cell.value?.toString() ?? '';
        if (text.length > maxWidth) maxWidth = text.length.toDouble();
      }
      sheet.setColumnWidth(col, (maxWidth + 2).clamp(10, 50));
    }
  }

  static void _applyAlternatingRowColors(Sheet sheet, int maxRow) {
    final dataCellStyle = CellStyle(
      fontSize: 9,
      backgroundColorHex: ExcelColor.fromHexString('FFF8FAFC'),
      verticalAlign: VerticalAlign.Center,
    );

    final whiteCellStyle = CellStyle(
      fontSize: 9,
      backgroundColorHex: ExcelColor.white,
      verticalAlign: VerticalAlign.Center,
    );

    for (int row = 1; row <= maxRow; row++) {
      final style = row % 2 == 0 ? dataCellStyle : whiteCellStyle;
      for (int col = 0; col < 15; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        if (cell.value?.toString().isNotEmpty ?? false) {
          cell.cellStyle = style;
        }
      }
    }
  }
}
