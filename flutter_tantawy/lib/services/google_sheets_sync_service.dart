import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة مزامنة ذكية من Google Sheets (٤ شيتات)
/// ١) قاعدة العملاء
/// ٢) الأصناف + المخزون
/// ٣) التارجت
/// ٤) العروض
class GoogleSheetsSyncService {
  GoogleSheetsSyncService._();
  static final GoogleSheetsSyncService instance = GoogleSheetsSyncService._();

  SupabaseClient get _client => Supabase.instance.client;

  // Helper to convert CSV to JSON-like rows
  List<Map<String, String>> _parseCsv(String csv) {
    final List<Map<String, String>> rows = [];
    final lines = LineSplitter.split(csv).toList();

    if (lines.isEmpty) return rows;

    // Parse header
    final headerLine = lines.first;
    final headers = _splitCsvLine(headerLine);

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = _splitCsvLine(line);
      final Map<String, String> row = {};

      for (int j = 0; j < headers.length && j < values.length; j++) {
        final key = headers[j].trim();
        final value = values[j].trim();
        if (key.isNotEmpty) {
          row[key] = value;
        }
      }

      if (row.isNotEmpty) {
        rows.add(row);
      }
    }
    return rows;
  }

  List<String> _splitCsvLine(String line) {
    final List<String> result = [];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  /// Fetch CSV from published Google Sheet
  Future<List<Map<String, String>>> _fetchSheetCsv(String publishedUrl) async {
    try {
      final uri = Uri.parse(publishedUrl);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return _parseCsv(utf8.decode(response.bodyBytes));
      }
      throw Exception('Failed to fetch sheet: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error fetching sheet: $e');
      rethrow;
    }
  }

  /// Fetch and parse CSV, returning rows
  Future<List<Map<String, String>>> _fetchAndParseSheet(String publishedUrl, String context) async {
    try {
      debugPrint('[$context] Fetching sheet: $publishedUrl');
      final rows = await _fetchSheetCsv(publishedUrl);
      debugPrint('[$context] Parsed ${rows.length} rows');
      return rows;
    } catch (e) {
      debugPrint('[$context] Error fetching sheet: $e');
      rethrow;
    }
  }

  /// Sync products from Google Sheets to Supabase
  /// Expected CSV columns: code, name, department, category, piecePrice, cartonPrice,
  ///   promoPrice, cartonQuantity, branchStockActual, branchStockReserved,
  ///   mainWarehouseStock, imageUrl, status, salesPriority, barcode, variantName, color
  Future<SyncResult> syncProducts(
    String publishedUrl, {
    void Function(String sheetName, int current, int total)? onProgress,
  }) async {
    final rows = await _fetchAndParseSheet(publishedUrl, 'Products');
    if (rows.isEmpty) {
      return SyncResult(message: 'لا توجد بيانات منتجات للمزامنة');
    }

    int added = 0;
    int updated = 0;
    int skipped = 0;
    int errors = 0;

    int total = rows.length;
    int processed = 0;
    for (final row in rows) {
      try {
        final code = row['code']?.trim() ?? '';
        if (code.isEmpty) {
          skipped++;
          processed++;
          onProgress?.call('المنتجات', processed, total);
          continue;
        }

        final productData = {
          'code': code,
          'name': row['name']?.trim() ?? '',
          'department': row['department']?.trim() ?? 'عام',
          'category': row['category']?.trim() ?? '',
          'piecePrice': _parseDouble(row['piecePrice']),
          'cartonPrice': _parseDouble(row['cartonPrice']),
          'promoPrice': _parseNullableDouble(row['promoPrice']),
          'cartonQuantity': _parseInt(row['cartonQuantity']),
          'branch_stock_actual': _parseInt(row['branchStockActual'] ?? row['branch_stock_actual']),
          'branch_stock_reserved': _parseInt(row['branchStockReserved'] ?? row['branch_stock_reserved']),
          'main_warehouse_stock': _parseInt(row['mainWarehouseStock'] ?? row['main_warehouse_stock']),
          'image_url': row['imageUrl']?.trim().isNotEmpty == true
              ? row['imageUrl']?.trim()
              : (row['image_url']?.trim().isNotEmpty == true ? row['image_url']?.trim() : null),
          'status': row['status']?.trim().isNotEmpty == true
              ? row['status']?.trim()
              : 'متاح',
          'sales_priority': row['salesPriority']?.trim().isNotEmpty == true
              ? row['salesPriority']?.trim()
              : 'عادي',
          'barcode': row['barcode']?.trim().isNotEmpty == true
              ? row['barcode']?.trim()
              : null,
          'variant_name': row['variantName']?.trim().isNotEmpty == true
              ? row['variantName']?.trim()
              : null,
          'color': row['color']?.trim().isNotEmpty == true
              ? row['color']?.trim()
              : null,
        };

        final existing = await _client
            .from('products')
            .select('id')
            .eq('code', code)
            .maybeSingle();

        if (existing == null) {
          await _client.from('products').insert(productData);
          added++;
        } else {
          productData['id'] = existing['id'];
          await _client.from('products').upsert(productData, onConflict: 'id');
          updated++;
        }
      } catch (e) {
        errors++;
        debugPrint('Error syncing product: $e');
      }
      processed++;
      onProgress?.call('المنتجات', processed, total);
    }

    return SyncResult(
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
      message: 'تم مزامنة المنتجات: $added أضيف، $updated حدث، $skipped تم تخطيه${errors > 0 ? '، $errors خطأ' : ''}',
    );
  }

  /// Sync customers from Google Sheets to Supabase
  /// Expected CSV columns: code, name, storeName, phone, address, branchName,
  ///   repName, currentBalance, creditLimit, tier
  Future<SyncResult> syncCustomers(
    String publishedUrl, {
    void Function(String sheetName, int current, int total)? onProgress,
  }) async {
    final rows = await _fetchAndParseSheet(publishedUrl, 'Customers');
    if (rows.isEmpty) {
      return SyncResult(message: 'لا توجد بيانات عملاء للمزامنة');
    }

    int added = 0;
    int updated = 0;
    int skipped = 0;
    int errors = 0;

     int total = rows.length;
     int processed = 0;
     for (final row in rows) {
       try {
         final code = row['code']?.trim() ?? '';
         if (code.isEmpty) {
           skipped++;
           processed++;
           onProgress?.call('العملاء', processed, total);
           continue;
         }

         final customerData = {
           'code': code,
           'name': row['name']?.trim() ?? '',
           'store_name': row['storeName']?.trim() ?? '',
           'phone': row['phone']?.trim() ?? '',
           'address': row['address']?.trim(),
           'branch_name': row['branchName']?.trim() ?? '',
           'rep_name': row['repName']?.trim(),
           'current_balance': _parseDouble(row['currentBalance']),
           'credit_limit': _parseDouble(row['creditLimit']),
           'tier': row['tier']?.trim().isNotEmpty == true
               ? row['tier']?.trim()
               : 'عادي',
           'updated_at': DateTime.now().toIso8601String(),
         };

         final existing = await _client
             .from('customers')
             .select('id')
             .eq('code', code)
             .maybeSingle();

         if (existing == null) {
           await _client.from('customers').insert(customerData);
           added++;
         } else {
           customerData['id'] = existing['id'];
           await _client.from('customers').upsert(customerData, onConflict: 'id');
           updated++;
         }
       } catch (e) {
         errors++;
         debugPrint('Error syncing customer: $e');
       }
       processed++;
       onProgress?.call('العملاء', processed, total);
     }

    return SyncResult(
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
      message: 'تم مزامنة العملاء: $added أضيف، $updated حدث، $skipped تم تخطيه، $errors خطأ',
    );
  }

  /// Sync targets/sales targets from Google Sheets to Supabase
  /// Expected CSV columns: repName, branchName, month, year, target
  Future<SyncResult> syncTargets(
    String publishedUrl, {
    void Function(String sheetName, int current, int total)? onProgress,
  }) async {
    final rows = await _fetchAndParseSheet(publishedUrl, 'Targets');
    if (rows.isEmpty) {
      return SyncResult(message: 'لا توجد بيانات تارجت للمزامنة');
    }

    int added = 0;
    int updated = 0;
    int skipped = 0;
    int errors = 0;

     int total = rows.length;
     int processed = 0;
     for (final row in rows) {
       try {
         final repName = row['repName']?.trim() ?? '';
         final branchName = row['branchName']?.trim() ?? '';
         final month = _parseInt(row['month']);
         final year = _parseInt(row['year']);

         if (repName.isEmpty || branchName.isEmpty || month == 0 || year == 0) {
           skipped++;
           processed++;
           onProgress?.call('التارجت', processed, total);
           continue;
         }

         final targetData = {
           'rep_name': repName,
           'branch_name': branchName,
           'month': month,
           'year': year,
           'target': _parseDouble(row['target']),
           'date': '$year-${month.toString().padLeft(2, '0')}-01',
         };

         final existing = await _client
             .from('targets')
             .select('id')
             .eq('rep_name', repName)
             .eq('month', month)
             .eq('year', year)
             .maybeSingle();

         if (existing == null) {
           await _client.from('targets').insert(targetData);
           added++;
         } else {
           targetData['id'] = existing['id'];
           await _client.from('targets').upsert(targetData, onConflict: 'id');
           updated++;
         }
       } catch (e) {
         errors++;
         debugPrint('Error syncing target: $e');
       }
       processed++;
       onProgress?.call('التارجت', processed, total);
     }

    return SyncResult(
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
      message: 'تم مزامنة التارجت: $added أضيف، $updated حدث، $skipped تم تخطيه، $errors خطأ',
    );
  }

  /// Sync offers/promotions from Google Sheets to Supabase
  /// Expected CSV columns: productCode, discountType, discountValue, startDate, endDate, status
  Future<SyncResult> syncOffers(
    String publishedUrl, {
    void Function(String sheetName, int current, int total)? onProgress,
  }) async {
    final rows = await _fetchAndParseSheet(publishedUrl, 'Offers');
    if (rows.isEmpty) {
      return SyncResult(message: 'لا توجد بيانات عروض للمزامنة');
    }

    int added = 0;
    int updated = 0;
    int skipped = 0;
    int errors = 0;

       int total = rows.length;
       int processed = 0;
       for (final row in rows) {
         try {
           final productCode = row['productCode']?.trim() ?? '';
           if (productCode.isEmpty) {
             skipped++;
             processed++;
             onProgress?.call('العروض', processed, total);
             continue;
           }

           final offerData = {
             'product_code': productCode,
             'discount_type': row['discountType']?.trim() ?? 'percentage',
             'discount_value': _parseDouble(row['discountValue']),
             'start_date': row['startDate']?.trim() ?? '',
             'end_date': row['endDate']?.trim() ?? '',
             'status': row['status']?.trim().isNotEmpty == true
                 ? row['status']?.trim()
                 : 'نشط',
           };

           final existing = await _client
               .from('promotions')
               .select('id')
               .eq('product_code', productCode)
               .maybeSingle();

           if (existing == null) {
             await _client.from('promotions').insert(offerData);
             added++;
           } else {
             offerData['id'] = existing['id'];
             await _client.from('promotions').upsert(offerData, onConflict: 'id');
             updated++;
           }
         } catch (e) {
           errors++;
           debugPrint('Error syncing offer: $e');
         }
         processed++;
         onProgress?.call('العروض', processed, total);
       }

    return SyncResult(
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
      message: 'تم مزامنة العروض: $added أضيف، $updated حدث، $skipped تم تخطيه، $errors خطأ',
    );
  }

  /// Sync all sheets in parallel
  /// [onProgress] is called with (sheetName, current, total) during sync
  Future<SyncResult> syncAll({
    required String? productsUrl,
    required String? customersUrl,
    required String? targetsUrl,
    required String? offersUrl,
    void Function(String sheetName, int current, int total)? onProgress,
  }) async {
    final tasks = <Future<SyncResult>>[];

    if (productsUrl != null && productsUrl.isNotEmpty) {
      tasks.add(syncProducts(productsUrl, onProgress: onProgress));
    }
    if (customersUrl != null && customersUrl.isNotEmpty) {
      tasks.add(syncCustomers(customersUrl, onProgress: onProgress));
    }
    if (targetsUrl != null && targetsUrl.isNotEmpty) {
      tasks.add(syncTargets(targetsUrl, onProgress: onProgress));
    }
    if (offersUrl != null && offersUrl.isNotEmpty) {
      tasks.add(syncOffers(offersUrl, onProgress: onProgress));
    }

    final results = await Future.wait(tasks);

    int totalAdded = 0;
    int totalUpdated = 0;
    int totalSkipped = 0;
    int totalErrors = 0;
    final messages = <String>[];

    for (final result in results) {
      totalAdded += result.added;
      totalUpdated += result.updated;
      totalSkipped += result.skipped;
      totalErrors += result.errors;
      if (result.message.isNotEmpty) {
        messages.add(result.message);
      }
    }

    return SyncResult(
      added: totalAdded,
      updated: totalUpdated,
      skipped: totalSkipped,
      errors: totalErrors,
      message: messages.join('\n'),
    );
  }

  /// Sync expenses from Google Sheets to Supabase
  /// Expected CSV columns: category, amount, date, description, branchName, repName
  Future<SyncResult> syncExpenses(
    String publishedUrl, {
    void Function(String sheetName, int current, int total)? onProgress,
  }) async {
    final rows = await _fetchAndParseSheet(publishedUrl, 'Expenses');
    if (rows.isEmpty) {
      return SyncResult(message: 'لا توجد بيانات مصاريف للمزامنة');
    }

    int added = 0;
    int updated = 0;
    int skipped = 0;
    int errors = 0;

    int total = rows.length;
    int processed = 0;
    for (final row in rows) {
      try {
        final category = row['category']?.trim() ?? 'متنوع';
        if (category.isEmpty) {
          skipped++;
          processed++;
          onProgress?.call('المصاريف', processed, total);
          continue;
        }

        final expenseData = {
          'category': category,
          'amount': _parseDouble(row['amount']),
          'date': row['date']?.trim().isNotEmpty == true
              ? row['date']?.trim()
              : DateTime.now().toIso8601String(),
          'description': row['description']?.trim(),
          'branch_name': row['branchName']?.trim() ?? '',
          'rep_name': row['repName']?.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _client.from('expenses').insert(expenseData);
        added++;
      } catch (e) {
        errors++;
        debugPrint('Error syncing expense: $e');
      }
      processed++;
      onProgress?.call('المصاريف', processed, total);
    }

    return SyncResult(
      added: added,
      updated: updated,
      skipped: skipped,
      errors: errors,
      message: 'تم مزامنة المصاريف: $added أضيف، $updated حدث، $skipped تم تخطيه${errors > 0 ? '، $errors خطأ' : ''}',
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }

  double? _parseNullableDouble(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    final parsed = _parseDouble(value);
    return parsed == 0.0 ? null : parsed;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString().replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
  }
}

/// Sync result summary
class SyncResult {
  final int added;
  final int updated;
  final int skipped;
  final int errors;
  final String message;

  SyncResult({
    this.added = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = 0,
    this.message = '',
  });
}
