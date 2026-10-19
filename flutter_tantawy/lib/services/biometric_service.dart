import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric unlock (fingerprint / face ID) for secure re-entry.
///
/// Used as a fast, secure alternative to re-entering credentials after the
/// session has expired. The actual credentials are stored encrypted via
/// [flutter_secure_storage] by the AuthService — this service only gates
/// access to those stored tokens.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return await _auth.deviceSupportsBiometricAuth();
    } catch (e) {
      return false;
    }
  }

  /// Prompts the user for biometric authentication.
  /// Returns `true` only if the OS-level biometric check passes.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'استخدم البصمة للوصول إلى حسابك',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable' || e.code == 'biometricNotAvailable') {
        return false;
      }
      rethrow;
    }
  }
}
