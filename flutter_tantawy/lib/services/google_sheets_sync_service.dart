import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'supabase_service.dart';

/// خدمة مزامنة ذكية من Google Sheets (٤ شيتات)
/// ١) قاعدة العملاء
/// ٢) الأصناف + المخزون
/// ٣) التارجت
/// ٤) العروض
class GoogleSheetsSyncService {
  GoogleSheetsSyncService._();
  static final GoogleSheetsSyncService instance = GoogleSheetsSyncService._();

  final SupabaseService _supabase = SupabaseService.instance;

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
}