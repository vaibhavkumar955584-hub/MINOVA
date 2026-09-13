import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/app_security_state.dart';
import 'package:minesafe/core/auth/auth_service.dart';
import 'package:minesafe/core/shortcuts/launcher_shortcut_service.dart';
import 'package:minesafe/features/report/attendance/attendance_screen.dart';
import 'package:minesafe/features/report/incident/incident_report_screen.dart';
import 'package:minesafe/models/user_model.dart';
import 'package:minesafe/shared/providers/app_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LauncherShortcut Enum & Mapping Tests', () {
    test('LauncherShortcut parses correctly from string inputs', () {
      expect(
        LauncherShortcut.fromString('emergency_incident'),
        LauncherShortcut.emergencyIncident,
      );
      expect(
        LauncherShortcut.fromString('emergencyincident'),
        LauncherShortcut.emergencyIncident,
      );
      expect(
        LauncherShortcut.fromString('incident'),
        LauncherShortcut.emergencyIncident,
      );
      expect(
        LauncherShortcut.fromString('attendance'),
        LauncherShortcut.attendance,
      );
      expect(
        LauncherShortcut.fromString('ATTENDANCE'),
        LauncherShortcut.attendance,
      );
      expect(LauncherShortcut.fromString('invalid_shortcut'), isNull);
      expect(LauncherShortcut.fromString(null), isNull);
    });

    test('LauncherShortcut exposes correct action and destination names', () {
      expect(
        LauncherShortcut.emergencyIncident.actionName,
        'emergency_incident',
      );
      expect(LauncherShortcut.emergencyIncident.destinationName, 'incident');

      expect(LauncherShortcut.attendance.actionName, 'attendance');
      expect(LauncherShortcut.attendance.destinationName, 'attendance');
    });

    test('LauncherShortcutService returns existing screens', () {
      final service = LauncherShortcutService.instance;

      final incidentScreen =
          service.getScreenForShortcut(LauncherShortcut.emergencyIncident);
      expect(incidentScreen, isA<IncidentReportScreen>());

      final attendanceScreen =
          service.getScreenForShortcut(LauncherShortcut.attendance);
      expect(attendanceScreen, isA<AttendanceScreen>());
    });
  });

  group('LauncherShortcut Security & Gating Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => AuthNotifier(AuthService())),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      LauncherShortcutService.instance.setPendingShortcut(null);
    });

    test('Unauthenticated user saves pending shortcut and does not leak screen',
        () {
      final service = LauncherShortcutService.instance;
      service.setPendingShortcut(null);

      // Verify user is null
      expect(container.read(authStateProvider), isNull);

      service.handleShortcut(
        LauncherShortcut.emergencyIncident,
        container.read,
      );

      // Pending shortcut is stored
      expect(service.pendingShortcut, LauncherShortcut.emergencyIncident);
    });

    test('Locked security state saves pending shortcut without unlocking',
        () {
      final service = LauncherShortcutService.instance;
      service.setPendingShortcut(null);

      // Set logged in user but state is locked
      final testUser = UserModel(
        id: 'u-1',
        employeeId: 'EMP001',
        fullName: 'Test Inspector',
        designation: 'Safety Officer',
        assignedMineId: 'mine-01',
        assignedMineName: 'Apex Coal Mine',
        email: 'inspector@mines.gov.in',
        role: UserRole.inspector,
        assignedMineIds: ['mine-01'],
        accountStatus: 'active',
      );

      container.read(authStateProvider.notifier).switchUser(testUser);
      expect(container.read(authStateProvider), isNotNull);

      // Security state starts as locked
      expect(
        container.read(appSessionCoordinatorProvider).state,
        SecurityState.locked,
      );

      service.handleShortcut(LauncherShortcut.attendance, container.read);

      // Pending shortcut is preserved for unlock flow
      expect(service.pendingShortcut, LauncherShortcut.attendance);
    });
  });
}
