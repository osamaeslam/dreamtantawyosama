import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline read-cache for **reference data** (customers, pending invoices,
/// products, etc.).
///
/// Unlike the write-queue ([OfflineQueueService], this service caches the
/// *last known good server responses* so the UI can render while offline.
/// Each cache entry stores:
///   - the JSON payload
///   - a timestamp of when it was last refreshed from the server
///
/// A visible "Last updated: ..." indicator should be shown whenever data
/// is served from cache rather than freshly fetched.
class OfflineCacheService {
  static const String _prefix = 'cache_';

  /// Generic setter: stores `data` (already JSON-encodable) keyed by `key`.
  Future<void> put(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final wrapper = {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('$_prefix$key', jsonEncode(wrapper));
  }

  /// Generic getter: returns [CacheEntry] or null if not cached.
  Future<CacheEntry?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry(
        data: decoded['data'],
        cachedAt: DateTime.parse(decoded['timestamp']),
      );
    } catch (e) {
      debugPrint('[OfflineCache] Failed to parse cache for $key: $e');
      return null;
    }
  }

  /// Delete a single cache entry.
  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }

  /// Clear all cached entries.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Fetch from server if online; otherwise fall back to the local cache.
  /// [fetcher] must return JSON-encodable data.
  Future<CacheResult<T>> fetchWithCache<T>(
    String key,
    Future<T> Function() fetcher,
    bool isOnline,
  ) async {
    if (isOnline) {
      try {
        final result = await fetcher();
        await put(key, result);
        return CacheResult(data: result, source: CacheSource.server);
      } catch (e) {
        debugPrint('[OfflineCache] Server fetch failed for $key, falling back to cache: $e');
      }
    }

    // Offline path — return cached data if available.
    final entry = await get(key);
    if (entry != null) {
      return CacheResult<T>(
        data: entry.data as T,
        source: CacheSource.cache,
        cachedAt: entry.cachedAt,
      );
    }

    return CacheResult<T>(data: null, source: CacheSource.none);
  }
}

/// Result of a [OfflineCacheService.fetchWithCache] call.
class CacheResult<T> {
  final T? data;
  final CacheSource source;
  final DateTime? cachedAt;

  CacheResult({this.data, required this.source, this.cachedAt});

  bool get isFromCache => source == CacheSource.cache;
  bool get isServer => source == CacheSource.server;
  bool get isMissing => source == CacheSource.none;
}

enum CacheSource { server, cache, none }

class CacheEntry {
  final dynamic data;
  final DateTime cachedAt;

  CacheEntry({required this.data, required this.cachedAt});
}
