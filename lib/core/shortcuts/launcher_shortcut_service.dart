import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/setup_security_screen.dart';
import '../../features/auth/unlock_screen.dart';
import '../../features/report/attendance/attendance_screen.dart';
import '../../features/report/incident/incident_report_screen.dart';
import '../../shared/providers/app_providers.dart';
import '../auth/app_security_state.dart';

/// Supported Android Launcher Long-Press Quick Action Shortcuts
enum LauncherShortcut {
  emergencyIncident,
  attendance;

  static LauncherShortcut? fromString(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toLowerCase()) {
      case 'emergency_incident':
      case 'emergencyincident':
      case 'incident':
        return LauncherShortcut.emergencyIncident;
      case 'attendance':
        return LauncherShortcut.attendance;
      default:
        return null;
    }
  }

  String get actionName {
    switch (this) {
      case LauncherShortcut.emergencyIncident:
        return 'emergency_incident';
      case LauncherShortcut.attendance:
        return 'attendance';
    }
  }

  String get destinationName {
    switch (this) {
      case LauncherShortcut.emergencyIncident:
        return 'incident';
      case LauncherShortcut.attendance:
        return 'attendance';
    }
  }
}

/// Service managing Android launcher shortcuts, security gating, and deep navigation.
class LauncherShortcutService {
  static final LauncherShortcutService instance = LauncherShortcutService._internal();

  LauncherShortcutService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const MethodChannel _channel =
      MethodChannel('com.sih26024.minesafe/launcher_shortcuts');

  LauncherShortcut? _pendingShortcut;

  LauncherShortcut? get pendingShortcut => _pendingShortcut;

  void setPendingShortcut(LauncherShortcut? shortcut) {
    _pendingShortcut = shortcut;
  }

  /// Initialize channel listeners and check for cold-start initial shortcuts
  Future<void> initialize(WidgetRef ref) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcutTriggered') {
        final rawAction = call.arguments as String?;
        final shortcut = LauncherShortcut.fromString(rawAction);
        if (shortcut != null) {
          handleShortcut(shortcut, ref.read);
        }
      }
    });

    try {
      final initialAction =
          await _channel.invokeMethod<String>('getInitialShortcut');
      if (initialAction != null) {
        final shortcut = LauncherShortcut.fromString(initialAction);
        if (shortcut != null) {
          handleShortcut(shortcut, ref.read);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SHORTCUT] Failed to query initial shortcut: $e');
      }
    }
  }

  /// Initialize with a direct Reader (useful before widget tree or in tests)
  Future<void> initializeWithReader(T Function<T>(ProviderListenable<T>) read) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcutTriggered') {
        final rawAction = call.arguments as String?;
        final shortcut = LauncherShortcut.fromString(rawAction);
        if (shortcut != null) {
          handleShortcut(shortcut, read);
        }
      }
    });

    try {
      final initialAction =
          await _channel.invokeMethod<String>('getInitialShortcut');
      if (initialAction != null) {
        final shortcut = LauncherShortcut.fromString(initialAction);
        if (shortcut != null) {
          handleShortcut(shortcut, read);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SHORTCUT] Failed to query initial shortcut: $e');
      }
    }
  }

  /// Evaluates security policy and routes or enqueues destination accordingly.
  void handleShortcut(
    LauncherShortcut shortcut,
    T Function<T>(ProviderListenable<T>) read,
  ) {
    if (kDebugMode) {
      debugPrint('[SHORTCUT] action=${shortcut.actionName}');
    }

    final user = read(authStateProvider);
    final securitySnapshot = read(appSessionCoordinatorProvider);

    if (user == null) {
      if (kDebugMode) {
        debugPrint('[SHORTCUT] security=unauthenticated');
      }
      _pendingShortcut = shortcut;
      // Do not navigate immediately if on Splash; Splash will direct to Login.
      // If already running, navigate to Login.
      final navState = navigatorKey.currentState;
      if (navState != null && navState.canPop()) {
        navState.push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    if (securitySnapshot.state == SecurityState.unconfigured) {
      if (kDebugMode) {
        debugPrint('[SHORTCUT] security=unconfigured');
      }
      _pendingShortcut = shortcut;
      final navState = navigatorKey.currentState;
      if (navState != null) {
        navState.push(
          MaterialPageRoute(builder: (_) => const SetupSecurityScreen()),
        );
      }
      return;
    }

    if (securitySnapshot.state == SecurityState.locked) {
      if (kDebugMode) {
        debugPrint('[SHORTCUT] security=locked');
      }
      _pendingShortcut = shortcut;
      final navState = navigatorKey.currentState;
      if (navState != null) {
        navState.push(
          MaterialPageRoute(builder: (_) => const UnlockScreen()),
        );
      }
      return;
    }

    // Authenticated and unlocked
    if (kDebugMode) {
      debugPrint('[SHORTCUT] destination=${shortcut.destinationName}');
      debugPrint('[SHORTCUT] security=unlocked');
    }

    _pendingShortcut = null;
    _navigateToDestination(shortcut);
  }

  /// Maps shortcut to the exact existing destination widget
  Widget getScreenForShortcut(LauncherShortcut shortcut) {
    switch (shortcut) {
      case LauncherShortcut.emergencyIncident:
        return const IncidentReportScreen();
      case LauncherShortcut.attendance:
        return const AttendanceScreen();
    }
  }

  void _navigateToDestination(LauncherShortcut shortcut) {
    final navState = navigatorKey.currentState;
    if (navState != null) {
      final screen = getScreenForShortcut(shortcut);
      navState.push(
        MaterialPageRoute(builder: (_) => screen),
      );
    }
  }

  /// Consumes and returns the pending destination widget if session is authenticated and unlocked
  Widget? consumePendingTargetScreen(WidgetRef ref) {
    if (_pendingShortcut == null) return null;

    final user = ref.read(authStateProvider);
    final securitySnapshot = ref.read(appSessionCoordinatorProvider);

    if (user != null && securitySnapshot.state == SecurityState.unlocked) {
      final shortcut = _pendingShortcut!;
      _pendingShortcut = null;

      if (kDebugMode) {
        debugPrint('[SHORTCUT] destination=${shortcut.destinationName}');
        debugPrint('[SHORTCUT] security=unlocked');
      }

      return getScreenForShortcut(shortcut);
    }

    return null;
  }
}
