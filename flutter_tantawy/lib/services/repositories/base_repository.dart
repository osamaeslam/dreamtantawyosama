import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for every repository. A repository owns a single concern
/// (e.g. products, invoices) and talks to Supabase through the shared
/// [SupabaseClient] singleton.
abstract class BaseRepository {
  const BaseRepository();

  SupabaseClient get client => Supabase.instance.client;

  /// Shared error logger so every repository reports failures the same way.
  void logError(String where, Object error) {
    debugPrint('[$runtimeType] Error in $where: $error');
  }
}
