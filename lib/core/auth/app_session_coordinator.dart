import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_security_config.dart';
import 'app_security_state.dart';
import 'biometric_service.dart';
import 'mpin_service.dart';
import 'secure_storage.dart';

/// Central coordinator for application startup resolution, MPIN verification,
/// biometric unlock, and lifecycle-driven security lockouts.
class AppSessionCoordinator extends StateNotifier<AppSecuritySnapshot>
    with WidgetsBindingObserver {
  final MpinService _mpinService;
  final BiometricService _biometricService;
  final SecureTokenStorage _secureStorage;

  AppSessionCoordinator({
    MpinService? mpinService,
    BiometricService? biometricService,
    SecureTokenStorage? secureStorage,
  })  : _mpinService = mpinService ?? MpinService.instance,
        _biometricService = biometricService ?? BiometricService.instance,
        _secureStorage = secureStorage ?? SecureTokenStorage.instance,
        super(const AppSecuritySnapshot(state: SecurityState.locked));

  bool _isInitialized = false;

  /// Performs fast resolution of device security posture on app start.
  Future<void> initialize({bool isProcessRestart = true}) async {
    if (kDebugMode) {
      debugPrint('[SECURITY] initialize start (processRestart=$isProcessRestart)');
    }

    final isConfigured = await _mpinService.isMpinConfigured();
    final biometricAvail = await _biometricService.isAvailable();
    final biometricEn = await _mpinService.isBiometricEnabled();
    final sessionUnlocked = await _secureStorage.isSessionUnlocked();

    SecurityState resolvedState;
    LockReason resolvedReason = LockReason.none;

    if (!isConfigured) {
      resolvedState = SecurityState.unconfigured;
    } else if (sessionUnlocked && !isProcessRestart) {
      resolvedState = SecurityState.unlocked;
    } else {
      resolvedState = SecurityState.locked;
      resolvedReason = isProcessRestart
          ? LockReason.processRestart
          : LockReason.manualLock;
    }

    state = state.copyWith(
      state: resolvedState,
      lockReason: resolvedReason,
      biometricAvailable: biometricAvail,
      biometricEnabled: biometricEn,
    );

    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('[SECURITY] configured=$isConfigured state=${resolvedState.name} reason=${resolvedReason.name}');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handleAppPaused() {
    final now = DateTime.now();
    state = state.copyWith(lastBackgroundAt: now);
    if (kDebugMode) {
      debugPrint('[LIFECYCLE] paused stored lastBackgroundAt: $now');
    }
  }

  void _handleAppResumed() {
    final backgroundTime = state.lastBackgroundAt;
    if (backgroundTime == null) return;

    final elapsed = DateTime.now().difference(backgroundTime);
    if (kDebugMode) {
      debugPrint('[LIFECYCLE] resumed after ${elapsed.inSeconds}s (threshold: ${AppSecurityConfig.lockAfter.inSeconds}s)');
    }

    if (state.state == SecurityState.unlocked &&
        elapsed > AppSecurityConfig.lockAfter) {
      if (kDebugMode) {
        debugPrint('[SECURITY] Timeout exceeded. Locking session.');
      }
      state = state.copyWith(
        state: SecurityState.locked,
        lockReason: LockReason.backgroundTimeout,
      );
      _secureStorage.lockSession();
    }
  }

  /// Verifies the 6-digit MPIN against local salted secure storage.
  Future<bool> verifyMpin(String pin) async {
    if (state.isLockedOut) {
      throw FormatException(
        'Too many failed attempts. Try again in ${state.remainingLockoutSeconds}s.',
      );
    }

    final isValid = await _mpinService.verifyMpin(pin);
    if (isValid) {
      await _secureStorage.markSessionUnlocked();
      state = state.copyWith(
        state: SecurityState.unlocked,
        lockReason: LockReason.none,
        failedAttempts: 0,
        clearLockout: true,
      );
      return true;
    } else {
      final newFailures = state.failedAttempts + 1;
      DateTime? lockoutUntil;
      if (newFailures >= AppSecurityConfig.maxAttempts) {
        lockoutUntil = DateTime.now().add(AppSecurityConfig.lockoutDuration);
      }

      state = state.copyWith(
        failedAttempts: newFailures,
        lockoutUntil: lockoutUntil,
      );
      return false;
    }
  }

  /// Performs local biometric authentication if available and enabled.
  Future<BiometricAuthResult> authenticateBiometric() async {
    if (!state.biometricAvailable || !state.biometricEnabled) {
      return BiometricAuthResult.notAvailable;
    }

    final result = await _biometricService.authenticate();
    if (result == BiometricAuthResult.success) {
      await _secureStorage.markSessionUnlocked();
      state = state.copyWith(
        state: SecurityState.unlocked,
        lockReason: LockReason.none,
        failedAttempts: 0,
        clearLockout: true,
      );
    }
    return result;
  }

  /// Configures a new 6-digit MPIN and sets biometric preference.
  Future<void> setupMpin(String pin, {bool enableBiometric = false}) async {
    await _mpinService.setupMpin(pin);
    await _mpinService.setBiometricEnabled(enableBiometric);
    await _secureStorage.markSessionUnlocked();

    state = state.copyWith(
      state: SecurityState.unlocked,
      lockReason: LockReason.none,
      biometricEnabled: enableBiometric,
      failedAttempts: 0,
      clearLockout: true,
    );
  }

  /// Resets MPIN after verified Firebase re-authentication.
  Future<void> resetMpin(String newPin) async {
    await _mpinService.resetMpin(newPin);
    await _secureStorage.markSessionUnlocked();
    state = state.copyWith(
      state: SecurityState.unlocked,
      lockReason: LockReason.none,
      failedAttempts: 0,
      clearLockout: true,
    );
  }

  /// Explicit manual lock (e.g. from app settings or session timeout).
  Future<void> lock({LockReason reason = LockReason.manualLock}) async {
    await _secureStorage.lockSession();
    state = state.copyWith(
      state: SecurityState.locked,
      lockReason: reason,
    );
  }

  /// Clears local security configuration on user logout.
  Future<void> clear() async {
    await _mpinService.clearMpin();
    await _secureStorage.clearSession();
    state = const AppSecuritySnapshot(
      state: SecurityState.unconfigured,
      lockReason: LockReason.none,
    );
  }
}
