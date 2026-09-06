import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/auth_service.dart';
import 'package:minesafe/core/localization/app_language.dart';
import 'package:minesafe/core/localization/language_controller.dart';
import 'package:minesafe/features/home/home_dashboard_screen.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/user_model.dart';
import 'package:minesafe/repositories/incident_repository.dart';
import 'package:minesafe/repositories/inspection_repository.dart';
import 'package:minesafe/shared/providers/app_providers.dart';
import 'package:minesafe/shared/widgets/signature_pad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('PHASE 1: Canonical Statutory Signature Tests', () {
    late InspectionRepository inspectionRepo;
    late IncidentRepository incidentRepo;
    late UserModel mockUser;

    setUp(() {
      inspectionRepo = InspectionRepository();
      incidentRepo = IncidentRepository();
      mockUser = AuthService.mockUsers[0];
    });

    test('Submit inspection report WITHOUT signature throws exact canonical message', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      for (final item in report.checklist) {
        item.status = CheckItemStatus.pass;
      }
      report.signatureBase64 = null;

      expect(
        () => inspectionRepo.submitAndLockReport(report),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Please add your signature before submitting.',
          ),
        ),
      );
    });

    test('Submit inspection report with EMPTY or BLANK signature throws canonical message', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      for (final item in report.checklist) {
        item.status = CheckItemStatus.pass;
      }
      report.signatureBase64 = '   ';

      expect(
        () => inspectionRepo.submitAndLockReport(report),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Please add your signature before submitting.',
          ),
        ),
      );
    });

    test('Submit inspection report with VALID signature successfully locks and seals report', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      for (final item in report.checklist) {
        item.status = CheckItemStatus.pass;
      }
      report.signatureBase64 = base64Encode(utf8.encode('SIG:10,10;20,20:validhash'));

      await inspectionRepo.submitAndLockReport(report);

      expect(report.status, equals(RecordStatus.pendingSync));
      expect(report.integrityHash, isNotNull);
      expect(report.integrityHash!.length, equals(64));
      expect(report.status.isLocked, isTrue);

      // Subsequent submit attempt throws StateError
      expect(
        () => inspectionRepo.submitAndLockReport(report),
        throwsA(isA<StateError>()),
      );
    });

    test('Submit incident report WITHOUT signature throws canonical message', () async {
      final incident = await incidentRepo.createDraft(
        user: mockUser,
        type: IncidentType.equipmentFailure,
        severity: ViolationSeverity.major,
        description: 'Conveyor motor overheated',
        immediateActionTaken: 'Belt stopped and isolated',
      );
      incident.signatureBase64 = null;

      expect(
        () => incidentRepo.submitAndLockIncident(incident),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Please add your signature before submitting.',
          ),
        ),
      );
    });

    test('Submit incident report with VALID signature succeeds and enqueues sync', () async {
      final incident = await incidentRepo.createDraft(
        user: mockUser,
        type: IncidentType.equipmentFailure,
        severity: ViolationSeverity.major,
        description: 'Conveyor motor overheated',
        immediateActionTaken: 'Belt stopped and isolated',
      );
      incident.signatureBase64 = base64Encode(utf8.encode('SIG:5,5;15,15:validhash2'));

      await incidentRepo.submitAndLockIncident(incident);
      expect(incident.status, equals(RecordStatus.pendingSync));
      expect(incident.integrityHash, isNotNull);
      expect(incident.status.isLocked, isTrue);
    });
  });

  group('PHASE 2: Inspector Data Scoping & Multi-User Isolation Tests', () {
    late InspectionRepository inspectionRepo;

    setUp(() {
      inspectionRepo = InspectionRepository();
    });

    test('Inspector A and Inspector B reports remain isolated by userId in queries', () async {
      final userA = AuthService.mockUsers[0]; // usr_01
      final userB = AuthService.mockUsers[1]; // usr_02

      final reportA = await inspectionRepo.createDraft(user: userA, type: InspectionType.safety);
      final reportB = await inspectionRepo.createDraft(user: userB, type: InspectionType.environmental);

      final reportsForA = await inspectionRepo.getAllReports(userId: userA.id);
      final reportsForB = await inspectionRepo.getAllReports(userId: userB.id);

      expect(reportsForA.any((r) => r.clientUuid == reportA.clientUuid), isTrue);
      expect(reportsForA.any((r) => r.clientUuid == reportB.clientUuid), isFalse);

      expect(reportsForB.any((r) => r.clientUuid == reportB.clientUuid), isTrue);
      expect(reportsForB.any((r) => r.clientUuid == reportA.clientUuid), isFalse);
    });
  });

  group('PHASE 4 & 5: Immediate Localization and UI Switching Tests', () {
    test('LanguageController updates state synchronously before disk persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = LanguageController(preferences: prefs);

      expect(controller.state.language.code, equals('en'));

      // Synchronous state update test
      final future = controller.select(AppLanguage.fromCode('te'));
      expect(controller.state.language.code, equals('te'));
      expect(controller.state.language.nativeName, equals('తెలుగు'));

      await future;
      expect(prefs.getString('minesafe_preferred_language'), equals('te'));
    });
  });

  group('PHASE 3: UI Overflow Resilience Tests', () {
    testWidgets('Home Dashboard renders metrics without overflow on narrow constraints', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => AuthNotifier(ref.watch(authServiceProvider))
                ..switchUser(AuthService.mockUsers[0]),
            ),
            pendingSyncCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
            connectivityStreamProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(
            home: HomeDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MINOVA'), findsOneWidget);
      expect(find.textContaining("Today's Logs"), findsOneWidget);
      expect(find.textContaining('Queue for Sync'), findsOneWidget);
    });

    testWidgets('SignaturePadWidget restores initial signature and displays locked badge in read-only mode', (tester) async {
      final sigData = base64Encode(utf8.encode('SIG:10,10;20,20:hash'));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignaturePadWidget(
              signerName: 'Priya Mukhopadhyay',
              signerRole: 'Statutory Mine Inspector',
              initialSignature: sigData,
              isReadOnly: true,
              onSignatureSaved: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('DIGITAL STATUTORY SIGNATURE'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('Signer: Priya Mukhopadhyay'), findsOneWidget);
      // Clear button should be hidden in read-only mode
      expect(find.text('CLEAR'), findsNothing);
    });
  });
}
