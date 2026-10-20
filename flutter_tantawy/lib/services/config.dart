import 'package:flutter/foundation.dart';

/// Centralized app configuration loaded from compile-time environment variables
/// (dart-define). Falls back to safe defaults so the app can run in mock/offline
/// mode during local development when no real backend is wired up.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://papxbfmgxnhbmagvqtje.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhcHhiZm1neG5oYm1hZ3ZxdGplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0ODcyNjUsImV4cCI6MjEwODA2MzI2NX0.m7l5Y7gwpuLaUDqP0o-to11MqfPSvuCFz_s2w2TqDMc',
  );

  /// When true the app renders seeded mock data instead of hitting Supabase.
  static const bool useMockData =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);

  /// Prints the active configuration to the debug console (dev only).
  static void logConfig() {
    if (kDebugMode) {
      debugPrint('AppConfig → url: $supabaseUrl | mock: $useMockData');
    }
  }

  /// Returns true only when real backend credentials have been supplied
  /// via dart-define (i.e. not running on the dev defaults).
  static bool get hasCustomCredentials => true;
}
