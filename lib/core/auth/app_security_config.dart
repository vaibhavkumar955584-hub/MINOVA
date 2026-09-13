/// Centralized security and lock timeout configuration for MINOVA.
class AppSecurityConfig {
  const AppSecurityConfig._();

  /// Grace period before backgrounded app locks automatically.
  /// Standard compliance shift setting is 5 minutes.
  static const Duration lockAfter = Duration(minutes: 5);

  /// Number of digits required for the local MPIN.
  static const int mpinLength = 6;

  /// Maximum incorrect MPIN attempts before temporary delay / cooldown.
  static const int maxAttempts = 5;

  /// Cooldown duration if maximum attempts are exceeded.
  static const Duration lockoutDuration = Duration(seconds: 30);
}
