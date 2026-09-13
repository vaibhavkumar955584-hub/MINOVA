/// Explicit security state of the device-local application session.
enum SecurityState {
  /// User is authenticated with Firebase, but has not set up a local MPIN.
  unconfigured,

  /// MPIN is configured, but the app is currently locked.
  locked,

  /// MPIN or Biometric has unlocked the session for protected navigation.
  unlocked,
}

/// Reason why the application is currently in a locked state.
enum LockReason {
  none,
  processRestart,
  backgroundTimeout,
  manualLock,
}

/// Comprehensive immutable model describing the device-local security posture.
class AppSecuritySnapshot {
  final SecurityState state;
  final LockReason lockReason;
  final bool biometricAvailable;
  final bool biometricEnabled;
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final DateTime? lastBackgroundAt;

  const AppSecuritySnapshot({
    required this.state,
    this.lockReason = LockReason.none,
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.lastBackgroundAt,
  });

  bool get isLocked => state == SecurityState.locked;
  bool get isUnlocked => state == SecurityState.unlocked;
  bool get isUnconfigured => state == SecurityState.unconfigured;
  bool get hasMpin => state != SecurityState.unconfigured;

  bool get isLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  int get remainingLockoutSeconds {
    if (lockoutUntil == null) return 0;
    final diff = lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  AppSecuritySnapshot copyWith({
    SecurityState? state,
    LockReason? lockReason,
    bool? biometricAvailable,
    bool? biometricEnabled,
    int? failedAttempts,
    DateTime? lockoutUntil,
    DateTime? lastBackgroundAt,
    bool clearLockout = false,
  }) {
    return AppSecuritySnapshot(
      state: state ?? this.state,
      lockReason: lockReason ?? this.lockReason,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
      lastBackgroundAt: lastBackgroundAt ?? this.lastBackgroundAt,
    );
  }
}
