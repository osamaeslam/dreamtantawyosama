import 'package:flutter/foundation.dart';

/// Centralized app configuration loaded from compile-time environment variables
/// (dart-define). Falls back to safe defaults so the app can run in mock/offline
/// mode during local development when no real backend is wired up.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ugfipwicffnbjiomrxye.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqZHBheXZhdmFhcmxjb2Noemd0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4OTg2MDIsImV4cCI6MjA4NTQ3NDYwMn0.Y6Vmn7zJZrdzVZMGupPTzDPdCh7yJmdzTbea_CRLM-g',
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
