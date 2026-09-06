import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/auth_service.dart';
import 'package:minesafe/core/evidence/evidence_service.dart';
import 'package:minesafe/core/theme/app_theme.dart';
import 'package:minesafe/features/report/incident/incident_report_screen.dart';
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

  setUp(() {
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

  group('Incident Camera Flow & Active Session Verification', () {
    testWidgets(
      '1. Camera source dialog opens as modal child flow without navigating away',
      (tester) async {
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

        // Screen is loaded
        expect(find.text('Emergency Incident Log'), findsOneWidget);

        // Find and tap capture photo button
        final captureButton = find.text('CAPTURE INCIDENT PHOTO');
        expect(captureButton, findsOneWidget);
        await tester.ensureVisible(captureButton);
        await tester.pumpAndSettle();
        await tester.tap(captureButton);
        await tester.pump();
        await tester.pumpAndSettle();

        // Bottom sheet modal opens
        expect(find.textContaining('ATTACH INCIDENT EVIDENCE'), findsOneWidget);
        expect(find.text('Live Camera Photo'), findsOneWidget);
        expect(find.text('Gallery / Storage'), findsOneWidget);

        // Tap outside / dismiss modal sheet
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify still on Incident Report Screen with form state preserved
        expect(find.text('Emergency Incident Log'), findsOneWidget);
        expect(find.text('CAPTURE INCIDENT PHOTO'), findsOneWidget);
      },
    );

    test('2. EvidenceService capturePhoto returns null on cancel (no fake simulated items in production)', () async {
      final evidenceService = EvidenceService.instance;
      // In headless test where no platform camera is attached, default fallbackToSimulated is false
      final result = await evidenceService.capturePhoto(
        reportClientUuid: 'TEST-INC-SESSION-01',
        fallbackToSimulated: false,
      );

      expect(result, isNull);
    });

    test('3. EvidenceService capturePhoto with simulated flag creates valid EvidenceItem with exact reportClientUuid', () async {
      final evidenceService = EvidenceService.instance;
      final sessionUuid = 'INC-2026-TEST-UUID';
      final result = await evidenceService.capturePhoto(
        reportClientUuid: sessionUuid,
        caption: 'Roof Fall Evidence',
        fallbackToSimulated: true,
      );

      expect(result, isNotNull);
      expect(result!.reportClientUuid, equals(sessionUuid));
      expect(result.sha256Hash.length, equals(64));
      expect(result.fileType, equals('photo'));
      expect(result.localFilePath, isNotEmpty);
    });

    test('4. IncidentRepository preserves explicit clientUuid from active session', () async {
      final repo = IncidentRepository();
      const sessionUuid = 'INC-2026-PERSIST-99';

      final draft = await repo.createDraft(
        clientUuid: sessionUuid,
        user: mockInspector,
        type: IncidentType.injury,
        severity: ViolationSeverity.critical,
        description: 'Strata displacement at seam 4.',
        immediateActionTaken: 'Hydraulic supports deployed.',
        peopleAffected: 1,
        affectedPersonDetails: ['R. K. Singh'],
      );

      expect(draft.clientUuid, equals(sessionUuid));
      expect(draft.mineId, equals('JH-DHA-BCCL-007'));
      expect(draft.status, equals(RecordStatus.draft));
    });

    testWidgets(
      '5. Evidence Preview UI renders photo count and entered text persists',
      (tester) async {
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

        // Initial state: 0 attached
        expect(find.text('PHOTO EVIDENCE / साक्ष्य फोटो (0 ATTACHED)'), findsOneWidget);
        expect(find.text('CAPTURE INCIDENT PHOTO'), findsOneWidget);

        // Enter Description & Action
        final descField = find.byType(TextField).at(2); // Description
        await tester.enterText(descField, 'Roof spalling at Gallery 5.');
        await tester.pumpAndSettle();

        expect(find.text('Roof spalling at Gallery 5.'), findsOneWidget);
      },
    );

    test('6. Signature enforcement remains mandatory before submission', () {
      final repo = IncidentRepository();
      final report = IncidentReport(
        clientUuid: 'INC-2026-NO-SIG',
        mineId: 'JH-DHA-BCCL-007',
        mineName: 'BCCL Pit-7',
        userId: 'usr_priya_02',
        userName: 'Priya Mukhopadhyay',
        userDesignation: 'Statutory Mine Inspector',
        type: IncidentType.equipmentFailure,
        severity: ViolationSeverity.major,
        peopleAffected: 0,
        description: 'Haul truck brake warning light.',
        immediateActionTaken: 'Vehicle grounded for maintenance.',
        signatureBase64: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () => repo.submitAndLockIncident(report),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
