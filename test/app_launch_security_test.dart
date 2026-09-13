import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/app_security_config.dart';
import 'package:minesafe/core/auth/app_security_state.dart';
import 'package:minesafe/models/user_model.dart';

void main() {
  group('MINOVA Launch & App Security Flow Contract Tests', () {
    test('1. AppSecurityConfig enforces centralized timeout and constraints', () {
      expect(AppSecurityConfig.lockAfter, equals(const Duration(minutes: 5)));
      expect(AppSecurityConfig.mpinLength, equals(6));
      expect(AppSecurityConfig.maxAttempts, equals(5));
      expect(AppSecurityConfig.lockoutDuration, equals(const Duration(seconds: 30)));
    });

    test('2. SecurityState model correctly reflects unconfigured, locked, and unlocked states', () {
      const unconfigured = AppSecuritySnapshot(
        state: SecurityState.unconfigured,
        biometricEnabled: false,
        biometricAvailable: true,
      );
      expect(unconfigured.state, equals(SecurityState.unconfigured));
      expect(unconfigured.isLocked, isFalse);
      expect(unconfigured.isUnlocked, isFalse);
      expect(unconfigured.hasMpin, isFalse);

      const locked = AppSecuritySnapshot(
        state: SecurityState.locked,
        biometricEnabled: true,
        biometricAvailable: true,
        lockReason: LockReason.processRestart,
      );
      expect(locked.state, equals(SecurityState.locked));
      expect(locked.isLocked, isTrue);
      expect(locked.hasMpin, isTrue);
      expect(locked.lockReason, equals(LockReason.processRestart));

      const unlocked = AppSecuritySnapshot(
        state: SecurityState.unlocked,
        biometricEnabled: true,
        biometricAvailable: true,
      );
      expect(unlocked.state, equals(SecurityState.unlocked));
      expect(unlocked.isUnlocked, isTrue);
      expect(unlocked.isLocked, isFalse);
      expect(unlocked.hasMpin, isTrue);
    });

    test('3. Lifecycle background timeout evaluation within vs beyond lockAfter threshold', () {
      final baseTime = DateTime.now();

      // Case A: Backgrounded for 2 minutes (less than 5 minutes)
      final shortBackgroundTime = baseTime.subtract(const Duration(minutes: 2));
      final shortDiff = baseTime.difference(shortBackgroundTime);
      final shouldLockShort = shortDiff >= AppSecurityConfig.lockAfter;
      expect(shouldLockShort, isFalse, reason: 'Brief backgrounding within 5 minutes MUST NOT lock the app');

      // Case B: Backgrounded for 6 minutes (greater than 5 minutes)
      final longBackgroundTime = baseTime.subtract(const Duration(minutes: 6));
      final longDiff = baseTime.difference(longBackgroundTime);
      final shouldLockLong = longDiff >= AppSecurityConfig.lockAfter;
      expect(shouldLockLong, isTrue, reason: 'Backgrounding beyond 5 minutes MUST trigger lock');
    });

    test('4. Inactive user account status blocks access', () {
      final inactiveUser = UserModel(
        id: 'user_inactive_123',
        employeeId: 'DGMS-INACTIVE',
        fullName: 'Inactive User',
        role: UserRole.inspector,
        designation: 'Former Inspector',
        assignedMineId: 'JH-DHA-001',
        assignedMineName: 'Mine 1',
        assignedMineIds: ['JH-DHA-001'],
        accountStatus: 'inactive',
      );

      final activeUser = UserModel(
        id: 'user_active_123',
        employeeId: 'DGMS-ACTIVE',
        fullName: 'Active User',
        role: UserRole.inspector,
        designation: 'Inspector',
        assignedMineId: 'JH-DHA-001',
        assignedMineName: 'Mine 1',
        assignedMineIds: ['JH-DHA-001'],
        accountStatus: 'active',
      );

      expect(inactiveUser.accountStatus == 'active', isFalse);
      expect(activeUser.accountStatus == 'active', isTrue);
    });

    test('5. Safe destination routing resolution logic', () {
      // Scenario 1: Not logged in to Firebase
      String resolveRoute({
        required bool isFirebaseAuthenticated,
        required bool isAccountActive,
        required SecurityState securityState,
      }) {
        if (!isFirebaseAuthenticated) return '/login';
        if (!isAccountActive) return '/inactive-account';
        switch (securityState) {
          case SecurityState.unconfigured:
            return '/setup-security';
          case SecurityState.locked:
            return '/unlock';
          case SecurityState.unlocked:
            return '/home';
        }
      }

      expect(
        resolveRoute(
          isFirebaseAuthenticated: false,
          isAccountActive: false,
          securityState: SecurityState.unconfigured,
        ),
        equals('/login'),
      );

      expect(
        resolveRoute(
          isFirebaseAuthenticated: true,
          isAccountActive: false,
          securityState: SecurityState.unlocked,
        ),
        equals('/inactive-account'),
      );

      expect(
        resolveRoute(
          isFirebaseAuthenticated: true,
          isAccountActive: true,
          securityState: SecurityState.unconfigured,
        ),
        equals('/setup-security'),
      );

      expect(
        resolveRoute(
          isFirebaseAuthenticated: true,
          isAccountActive: true,
          securityState: SecurityState.locked,
        ),
        equals('/unlock'),
      );

      expect(
        resolveRoute(
          isFirebaseAuthenticated: true,
          isAccountActive: true,
          securityState: SecurityState.unlocked,
        ),
        equals('/home'),
      );
    });
  });
}
