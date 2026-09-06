import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/auth_service.dart';
import 'package:minesafe/core/theme/app_theme.dart';
import 'package:minesafe/features/report/incident/incident_report_screen.dart';
import 'package:minesafe/features/shell/main_navigation_shell.dart';
import 'package:minesafe/models/evidence_model.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/user_model.dart';
import 'package:minesafe/repositories/incident_repository.dart';
import 'package:minesafe/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockAuthNotifier extends AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthService()) {
    state = user;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late UserModel mockInspector;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockInspector = UserModel(
      id: 'usr_priya_02',
      employeeId: 'DGMS-INSP-404',
      fullName: 'Priya Mukhopadhyay',
      role: UserRole.inspector,
      designation: 'Statutory Mine Inspector',
      assignedMineId: 'JH-DHA-BCCL-007',
      assignedMineName: 'BCCL Pit-7 (Dhanbad)',
      phone: '+91 98111 22334',
      email: 'p.mukhopadhyay@dgms.gov.in',
    );
  });

  group('Incident Camera Navigation & Contract Tests', () {
    testWidgets('1. Camera opens as child modal sheet and does NOT navigate to Home', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(mockInspector)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const IncidentReportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure on Incident Screen
      expect(find.text('Emergency Incident Log'), findsOneWidget);

      // Tap capture photo
      final captureBtn = find.text('CAPTURE INCIDENT PHOTO');
      expect(captureBtn, findsOneWidget);
      await tester.ensureVisible(captureBtn);
      await tester.pumpAndSettle();
      await tester.tap(captureBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Modal bottom sheet is open
      expect(find.textContaining('ATTACH INCIDENT EVIDENCE'), findsOneWidget);
      expect(find.text('Live Camera Photo'), findsOneWidget);

      // Dismiss dialog
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pumpAndSettle();

      // Screen is still Incident Log, NEVER Home
      expect(find.text('Emergency Incident Log'), findsOneWidget);
      expect(find.text('STATUTORY EMERGENCY NOTICE (CMR REG 116 / MINES ACT SEC 23)'), findsOneWidget);
    });

    testWidgets('2. Camera cancel preserves all entered form data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(mockInspector)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const IncidentReportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter Description & Action
      final descField = find.byType(TextField).at(2);
      await tester.enterText(descField, 'Methane gas spike near Face 3.');
      await tester.pumpAndSettle();

      final actionField = find.byType(TextField).at(3);
      await tester.enterText(actionField, 'Auxiliary fan speed boosted.');
      await tester.pumpAndSettle();

      // Open camera modal and cancel
      final captureBtn = find.text('CAPTURE INCIDENT PHOTO');
      await tester.ensureVisible(captureBtn);
      await tester.pumpAndSettle();
      await tester.tap(captureBtn);
      await tester.pumpAndSettle();

      // Dismiss / cancel
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify form data remains intact
      expect(find.text('Methane gas spike near Face 3.'), findsOneWidget);
      expect(find.text('Auxiliary fan speed boosted.'), findsOneWidget);
    });

    testWidgets('3. Multiple photo captures retain same submission ID & preview list', (tester) async {
      final repo = IncidentRepository();
      const testUuid = 'INC-EMG-TEST-MULTI-01';

      await tester.runAsync(() async {
        final draft = await repo.createDraft(
          clientUuid: testUuid,
          user: mockInspector,
          type: IncidentType.injury,
          severity: ViolationSeverity.critical,
          description: 'Multi-photo audit test.',
          immediateActionTaken: 'Secured area.',
        );

        // Attach 2 evidence items to the same report
        final photo1 = EvidenceItem(
          id: 'EV-TEST-01',
          reportClientUuid: testUuid,
          localFilePath: 'mock_path_1.jpg',
          fileType: 'photo',
          fileSize: 1024,
          sha256Hash: 'a' * 64,
          capturedAt: DateTime.now(),
          caption: 'Photo 1',
        );
        final photo2 = EvidenceItem(
          id: 'EV-TEST-02',
          reportClientUuid: testUuid,
          localFilePath: 'mock_path_2.jpg',
          fileType: 'photo',
          fileSize: 2048,
          sha256Hash: 'b' * 64,
          capturedAt: DateTime.now(),
          caption: 'Photo 2',
        );

        expect(photo1.reportClientUuid, equals(testUuid));
        expect(photo2.reportClientUuid, equals(testUuid));

        draft.evidence.addAll([photo1, photo2]);
        await repo.autoSaveDraft(draft);
      });

      // Load screen with this draft
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(mockInspector)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: IncidentReportScreen(initialClientUuid: testUuid),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();

      expect(find.text('PHOTO EVIDENCE / साक्ष्य फोटो (2 ATTACHED)'), findsOneWidget);
      expect(find.text('ADD ANOTHER PHOTO (2 ATTACHED)'), findsOneWidget);
      expect(find.text('Multi-photo audit test.'), findsOneWidget);
    });

    testWidgets('4. Interrupted draft auto-restores in MainNavigationShell', (tester) async {
      final repo = IncidentRepository();
      const testUuid = 'INC-EMG-INTERRUPT-99';

      await tester.runAsync(() async {
        await repo.createDraft(
          clientUuid: testUuid,
          user: mockInspector,
          type: IncidentType.fire,
          severity: ViolationSeverity.critical,
          description: 'Conveyor belt friction heating.',
          immediateActionTaken: 'Deluge system activated.',
        );
      });

      // Set active draft key as if app was interrupted by Camera OS kill
      SharedPreferences.setMockInitialValues({
        'active_incident_draft_uuid': testUuid,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_incident_draft_uuid', testUuid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(mockInspector)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const MainNavigationShell(),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump(); // executes postFrameCallback -> Navigator.push
      await tester.pump(const Duration(milliseconds: 400)); // completes MaterialPageRoute transition
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump(); // renders restored IncidentReportScreen state

      // Verify that MainNavigationShell detected the interrupted draft and restored IncidentReportScreen
      expect(find.text('Emergency Incident Log'), findsOneWidget);
      expect(find.text('Conveyor belt friction heating.'), findsOneWidget);
      expect(find.text('Deluge system activated.'), findsOneWidget);

      // Clean up widget tree
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });
  });
}
