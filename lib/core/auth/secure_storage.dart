import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  static final SecureTokenStorage instance = SecureTokenStorage._init();
  final FlutterSecureStorage _storage;

  SecureTokenStorage._init()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(),
        );

  static const String _tokenKey = 'minesafe_auth_token';
  static const String _userIdKey = 'minesafe_user_id';
  static const String _userRoleKey = 'minesafe_user_role';

  static const String _unlockedTimestampKey = 'minesafe_session_unlocked_at';

  Future<void> saveSession({
    required String token,
    required String userId,
    required String userRole,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userRoleKey, value: userRole);
  }

  Future<void> markSessionUnlocked() async {
    await _storage.write(
      key: _unlockedTimestampKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<bool> isSessionUnlocked() async {
    try {
      final timestampStr = await _storage.read(key: _unlockedTimestampKey);
      if (timestampStr == null) return false;
      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return false;
      // Session remains validly unlocked for 12 hours (active mine shift duration)
      final diff = DateTime.now().millisecondsSinceEpoch - timestamp;
      return diff < const Duration(hours: 12).inMilliseconds;
    } catch (_) {
      return false;
    }
  }

  Future<void> lockSession() async {
    await _storage.delete(key: _unlockedTimestampKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userRoleKey);
    await _storage.delete(key: _unlockedTimestampKey);
  }

  Future<bool> hasValidSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
