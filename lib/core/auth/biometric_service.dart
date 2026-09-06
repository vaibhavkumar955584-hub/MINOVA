import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  static final BiometricService instance = BiometricService();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getSupportedBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  Future<BiometricAuthResult> authenticate() async {
    if (!await isAvailable()) return BiometricAuthResult.notAvailable;

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock MINOVA to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return authenticated
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } catch (_) {
      return BiometricAuthResult.failed;
    }
  }
}

enum BiometricAuthResult { success, failed, notAvailable }
