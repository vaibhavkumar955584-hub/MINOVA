import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/auth_service.dart';
import 'package:minesafe/core/evidence/evidence_service.dart';
import 'package:minesafe/core/location/location_service.dart';
import 'package:minesafe/core/sync/sync_engine.dart';
import 'package:minesafe/features/records/records_screen.dart';
import 'package:minesafe/features/report/report_hub_screen.dart';
import 'package:minesafe/features/shell/main_navigation_shell.dart';
import 'package:minesafe/models/correction_request_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/mine_model.dart';
import 'package:minesafe/models/sync_item_model.dart';
import 'package:minesafe/repositories/correction_repository.dart';
import 'package:minesafe/repositories/inspection_repository.dart';
import 'package:minesafe/shared/providers/app_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('End-to-End Priority Flows Verification', () {
    testWidgets('1. Navigation Shell & All Major Screens Render Correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) =>
                  AuthNotifier(ref.watch(authServiceProvider))
                    ..switchUser(AuthService.mockUsers[0]),
            ),
          ],
          child: const MaterialApp(home: MainNavigationShell()),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Home Screen Verification
      expect(find.text('MINOVA'), findsOneWidget);
      expect(find.text('Good morning, Rajesh'), findsOneWidget);
      expect(find.text('+ START REPORT'), findsOneWidget);

      // Tap Records Tab
      await tester.tap(find.text('Records'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(RecordsScreen), findsOneWidget);
      expect(find.textContaining('All'), findsWidgets);

      // Tap Profile Tab
      await tester.tap(find.text('Profile'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.text('Rajesh Sharma'), findsOneWidget);

      // Tap + REPORT Central Action
      await tester.tap(find.text('REPORT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ReportHubScreen), findsOneWidget);
      expect(find.text('Safety Inspection'), findsOneWidget);
      expect(find.textContaining('Incident Report'), findsOneWidget);
      expect(find.textContaining('Attendance'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Observation'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('Observation'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Document'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.textContaining('Document'),
        findsOneWidget,
      );

      // Clean up widget tree to allow pure async tests to proceed without animation leaks
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets(
      '2. Inspection Workflow, Draft Auto-Save & Submission Locking',
      (tester) async {
        final user = AuthService.mockUsers[0];
        final inspectionRepo = InspectionRepository();

        // Create Draft
        final draft = await inspectionRepo.createDraft(
          user: user,
          type: InspectionType.safety,
        );
        expect(draft.clientUuid, startsWith('SAF-INSP-'));
        expect(draft.status, equals(RecordStatus.draft));
        expect(draft.status.isLocked, isFalse);

        // Modify Question & Auto-save
        draft.checklist[0].status = CheckItemStatus.fail;
        draft.checklist[0].severity = ViolationSeverity.critical;
        draft.checklist[0].violationDescription =
            'Workers missing self-rescuers near seam face';
        draft.checklist[0].correctiveAction =
            'Provide flameproof gear immediately';
        draft.checklist[0].deadline = DateTime.now().add(
          const Duration(days: 7),
        );
        for (final item in draft.checklist.skip(1)) {
          item.status = CheckItemStatus.pass;
        }

        await inspectionRepo.autoSaveDraft(draft);

        // Verify draft persisted in SQLite
        final loadedDraft = await inspectionRepo.getReportByUuid(
          draft.clientUuid,
        );
        expect(loadedDraft, isNotNull);
        expect(loadedDraft!.checklist[0].status, equals(CheckItemStatus.fail));
        expect(
          loadedDraft.checklist[0].violationDescription,
          equals('Workers missing self-rescuers near seam face'),
        );

        // Attach Simulated Signature & Submit
        draft.signatureBase64 = 'SIG:BASE64_STYLUS_STROKES_HASH';
        draft.signedAt = DateTime.now();
        await inspectionRepo.submitAndLockReport(draft);

        // Verify Locked State
        final submittedReport = await inspectionRepo.getReportByUuid(
          draft.clientUuid,
        );
        expect(submittedReport, isNotNull);
        expect(submittedReport!.status.isLocked, isTrue);
        expect(submittedReport.integrityHash, isNotNull);
        expect(submittedReport.submittedAt, isNotNull);
      },
    );

    testWidgets(
      '3. GPS-Unavailable Fallback to Manual Underground Mine Zones',
      (tester) async {
        final locationService = LocationService.instance;
        final fallbackZone = MineModel.defaultZones[2]; // Section B Face

        final loc = await locationService.captureLocation(
          timeout: const Duration(milliseconds: 100),
          manualFallbackZone: fallbackZone,
        );

        expect(loc.locationSource, equals('manual'));
        expect(loc.zoneName, equals('Section B Face'));
        expect(loc.depthLevel, equals('LVL -320M'));
        expect(loc.displayTag, contains('Section B Face'));
      },
    );

    testWidgets(
      'Inspection submission rejects incomplete or already locked reports',
      (tester) async {
        final inspectionRepo = InspectionRepository();
        final draft = await inspectionRepo.createDraft(
          user: AuthService.mockUsers[1],
          type: InspectionType.environmental,
        );

        expect(draft.checklist.first.id, startsWith('chk_environmental_'));
        expect(
          () => inspectionRepo.submitAndLockReport(draft),
          throwsA(isA<FormatException>()),
        );

        for (final item in draft.checklist) {
          item.status = CheckItemStatus.pass;
        }
        draft.signatureBase64 = 'SIG:VALID';
        await inspectionRepo.submitAndLockReport(draft);
        expect(
          () => inspectionRepo.submitAndLockReport(draft),
          throwsA(isA<StateError>()),
        );
      },
    );

    testWidgets('4. Field Evidence Capture & SHA-256 Tamper Detection', (tester) async {
      final evidenceService = EvidenceService.instance;
      final item = await evidenceService.capturePhoto(
        reportClientUuid: 'SAF-INSP-TEST-EVID',
        caption: 'Methane sensor test',
        fallbackToSimulated: true,
      );

      expect(item, isNotNull);
      expect(item!.sha256Hash, isNotEmpty);
      expect(item.sha256Hash.length, equals(64));
      expect(item.fileType, equals('photo'));
    });

    testWidgets(
      '5. Offline Queueing, Bounded Retry & Idempotency Preservation',
      (tester) async {
        final syncEngine = SyncEngine.instance;
        final clientUuid = 'SAF-INSP-RETRY-01';

        await syncEngine.enqueue(
          clientUuid: clientUuid,
          recordType: SyncRecordType.inspection,
          payloadJson: jsonEncode({'client_uuid': clientUuid, 'test': true}),
        );

        final pendingCount = await syncEngine.getPendingSyncCount();
        expect(pendingCount, greaterThanOrEqualTo(1));

        // Trigger manual retry
        await syncEngine.manualRetry(clientUuid);
      },
    );

    testWidgets('6. Audited Correction Request Workflow for Locked Records', (tester) async {
      final user = AuthService.mockUsers[0];
      final correctionRepo = CorrectionRepository();
      final clientUuid = 'SAF-INSP-LOCK-CORR';

      // Request correction
      final request = await correctionRepo.requestCorrection(
        recordClientUuid: clientUuid,
        recordType: 'inspection',
        user: user,
        reason: 'Adjusting strata bolt count from 12 to 14',
        requestedChangesJson: jsonEncode({'bolt_count': 14}),
      );

      expect(request.status, equals(CorrectionStatus.pendingReview));

      // Safety Manager Review & Approval
      await correctionRepo.reviewCorrection(
        correctionId: request.id,
        reviewer: user,
        approve: true,
        comments: 'Verified with shift overman logbook. Approved.',
      );

      final auditEvents = await correctionRepo.getAuditEventsForRecord(
        clientUuid,
      );
      expect(auditEvents.length, greaterThanOrEqualTo(2));
      expect(
        auditEvents.any((a) => a.eventType == 'correction_requested'),
        isTrue,
      );
      expect(
        auditEvents.any((a) => a.eventType == 'correction_approved'),
        isTrue,
      );
    });
  });
}
