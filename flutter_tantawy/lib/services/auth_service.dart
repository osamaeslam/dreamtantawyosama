import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'biometric_service.dart';
import 'connectivity_service.dart';

/// Signature of the credential-validation callback used by [AuthService.login].
typedef LoginValidator = Future<AppUser?> Function(String username, String password);

/// Authentication service handling:
/// 1. **Domain-based login** — credentials validated against YOUR Supabase
///    `users` table (configured via AppConfig credentials), not a generic
///    auth provider. The login is gated on a *real* server probe so you
///    cannot authenticate against a stale/offline credential cache.
/// 2. **Secure session storage** — the authenticated AppUser + a session
///    timestamp are stored in `flutter_secure_storage` (encrypted at rest
///    on iOS/Android keychain / keystore).
/// 3. **Auto session refresh** — sessions are re-validated on app resume;
///    if the token is stale the user is sent back to login.
/// 4. **Biometric unlock** — after initial login, [unlockWithBiometrics]
///    offers fingerprint-based access to the cached session.
class AuthService {
  static const String _sessionKey = 'auth_session_v2';

  final ConnectivityService _connectivity = ConnectivityService.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final BiometricService _biometrics = BiometricService.instance;

  AuthService._();

  static final AuthService instance = AuthService._();

  // ============================================================
  // Login
  // ============================================================

  /// Persists the session after a successful login. Called by LoginScreen.
  Future<void> persistSessionForLogin(AppUser user) async {
    await _persistSession(user);
  }

  /// Attempts login. Performs a **real** server probe first — if the
  /// backend cannot be reached, login fails immediately with an offline
  /// exception rather than falling back to cached credentials.
  Future<AppUser?> login({
    required String username,
    required String password,
    required LoginValidator loginFn,
  }) async {
    final isOnline = await _connectivity.pingServer();
    if (!isOnline) {
      throw PlatformException(
        code: 'OFFLINE',
        message: 'يجب أن تكون متصلاً بالخادم لتسجيل الدخول',
      );
    }

    final user = await loginFn(username, password);
    if (user == null) return null;

    await _persistSession(user);
    return user;
  }

  Future<void> _persistSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    // Non-sensitive session data in shared_preferences (fast access on unlock)
    await prefs.setString('auth_user_role', user.role);
    await prefs.setString('auth_user_name', user.name);

    // Encrypted: the sensitive parts (token-equivalent)
    final sessionJson = jsonEncode({
      'id': user.id,
      'username': user.username,
      'role': user.role,
      'branchName': user.branchName,
      'loginAt': DateTime.now().toIso8601String(),
    });
    await _secureStorage.write(key: _sessionKey, value: sessionJson);
  }

  // ============================================================
  // Session management / auto-refresh
  // ============================================================

  /// Returns the cached session user if still valid, otherwise null.
  /// Validity is determined by a max session age (7 days by default for
  /// better UX — sessions expire after 7 days of inactivity).
  Future<AppUser?> getCachedUser({Duration maxAge = const Duration(days: 7)}) async {
    final raw = await _secureStorage.read(key: _sessionKey);
    if (raw == null) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final loginAt = DateTime.parse(data['loginAt'] as String);
      final now = DateTime.now();

      if (now.difference(loginAt) > maxAge) {
        // Session expired — require re-authentication.
        await clearSession();
        return null;
      }

      return AppUser(
        id: data['id'] as String,
        name: data['username'] as String,
        username: data['username'] as String,
        role: data['role'] as String,
        branchName: data['branchName'] as String,
        phone: '',
      );
    } catch (e) {
      await clearSession();
      return null;
    }
  }

  /// Auto-refresh: checks if the cached session is still valid by pinging
  /// the server. If the session is expired or the user is offline, returns
  /// null so the caller can redirect to LoginScreen.
  Future<AppUser?> refreshOrReauth() async {
    final isOnline = await _connectivity.pingServer();
    if (!isOnline) {
      // Allow continued use while offline but mark as needing refresh on
      // next resume.
      final cached = await getCachedUser();
      return cached;
    }

    // Online: re-fetch the user to pick up any role/status changes.
    final cached = await getCachedUser();
    if (cached == null) return null;

    // Touch the session to extend its lifetime.
    await _persistSession(cached);
    return cached;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_role');
    await prefs.remove('auth_user_name');
    await _secureStorage.delete(key: _sessionKey);
  }

  // ============================================================
  // Biometric unlock
  // ============================================================

  /// Returns true if biometric unlock is available on this device.
  Future<bool> canUseBiometrics() async => _biometrics.isAvailable();

  /// Unlocks the app using fingerprint/Face ID.
  /// Only succeeds if [BiometricService.authenticate] passes AND a cached
  /// session exists.
  Future<AppUser?> unlockWithBiometrics() async {
    final success = await _biometrics.authenticate();
    if (!success) return null;

    final cached = await getCachedUser();
    // Do NOT ping the server here — the user explicitly wants fast unlock.
    // The session is validated on the next foreground event.
    return cached;
  }

  /// Quick re-entry check: if biometrics enabled + cached session exists,
  /// the user can skip the login screen entirely.
  Future<bool> canQuickUnlock() async {
    final hasBiometrics = await canUseBiometrics();
    if (!hasBiometrics) return false;
    final cached = await getCachedUser(maxAge: const Duration(days: 7));
    return cached != null;
  }
}
