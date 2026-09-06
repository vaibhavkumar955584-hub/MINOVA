import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Stores and verifies a device-local six-digit MPIN without retaining the
/// raw value.
class MpinService {
  MpinService({FlutterSecureStorage? storage})
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: AndroidOptions());

  static final MpinService instance = MpinService();

  static const _hashKey = 'minesafe_mpin_hash';
  static const _saltKey = 'minesafe_device_salt';
  static const _biometricKey = 'minesafe_biometric_enabled';

  final FlutterSecureStorage _storage;

  Future<bool> isMpinConfigured() async {
    final hash = await _storage.read(key: _hashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setupMpin(String pin) async {
    _validatePin(pin);
    final salt = await _getOrCreateSalt();
    await _storage.write(key: _hashKey, value: _hashPin(pin, salt));
  }

  Future<bool> verifyMpin(String pin) async {
    if (!_isValidPin(pin)) return false;
    final storedHash = await _storage.read(key: _hashKey);
    if (storedHash == null) return false;

    final salt = await _getOrCreateSalt();
    return _hashPin(pin, salt) == storedHash;
  }

  Future<void> clearMpin() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _biometricKey);
  }

  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _biometricKey)) == 'true';

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  Future<void> resetMpin(String newPin) async {
    await setupMpin(newPin);
  }

  Future<String> _getOrCreateSalt() async {
    var salt = await _storage.read(key: _saltKey);
    if (salt == null || salt.isEmpty) {
      salt = const Uuid().v4();
      await _storage.write(key: _saltKey, value: salt);
    }
    return salt;
  }

  String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static bool _isValidPin(String pin) => RegExp(r'^\d{6}$').hasMatch(pin);

  static void _validatePin(String pin) {
    if (!_isValidPin(pin)) {
      throw const FormatException('MPIN must be exactly 6 digits.');
    }
  }
}
