import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/auth_service.dart';
import 'package:minesafe/data/dto/inspection_dto.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/user_model.dart';
import 'package:minesafe/repositories/inspection_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late InspectionRepository inspectionRepo;
  late UserModel mockUser;

  setUp(() {
    inspectionRepo = InspectionRepository();
    mockUser = AuthService.mockUsers[0];
  });

  group('Inspection Submit Validation & Mixed Answer Tests', () {
    test('1. All PASS checklist -> submit allowed', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      for (final item in report.checklist) {
        item.status = CheckItemStatus.pass;
      }
      report.signatureBase64 = base64Encode(utf8.encode('SIG:pass_only'));

      // Validate does not throw
      expect(() => inspectionRepo.validateBeforeSubmit(report), returnsNormally);
      await inspectionRepo.submitAndLockReport(report);
      expect(report.status, equals(RecordStatus.pendingSync));
      expect(report.integrityHash, isNotNull);
    });

    test('2. Mixed PASS + FAIL checklist -> submit allowed without forced fields', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      // Item 0 = PASS, Item 1 = FAIL with no corrective action, Item 2+ = PASS
      report.checklist[0].status = CheckItemStatus.pass;
      report.checklist[1].status = CheckItemStatus.fail;
      report.checklist[1].severity = ViolationSeverity.major;
      report.checklist[1].violationDescription = 'Guard rail loose';
      report.checklist[1].correctiveAction = null; // not filled
      report.checklist[1].deadline = null; // not filled

      for (int i = 2; i < report.checklist.length; i++) {
        report.checklist[i].status = CheckItemStatus.pass;
      }
      report.signatureBase64 = base64Encode(utf8.encode('SIG:pass_fail'));

      expect(() => inspectionRepo.validateBeforeSubmit(report), returnsNormally);
      await inspectionRepo.submitAndLockReport(report);
      expect(report.status, equals(RecordStatus.pendingSync));
      expect(report.integrityHash, isNotNull);
    });

    test('3. PASS + N/A checklist -> submit allowed', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.electrical,
      );
      for (int i = 0; i < report.checklist.length; i++) {
        report.checklist[i].status = (i % 2 == 0) ? CheckItemStatus.pass : CheckItemStatus.na;
      }
      report.signatureBase64 = base64Encode(utf8.encode('SIG:pass_na'));

      expect(() => inspectionRepo.validateBeforeSubmit(report), returnsNormally);
      await inspectionRepo.submitAndLockReport(report);
      expect(report.status, equals(RecordStatus.pendingSync));
    });

    test('4. FAIL + N/A checklist -> submit allowed', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.ventilation,
      );
      for (int i = 0; i < report.checklist.length; i++) {
        report.checklist[i].status = (i % 2 == 0) ? CheckItemStatus.fail : CheckItemStatus.na;
      }
      report.signatureBase64 = base64Encode(utf8.encode('SIG:fail_na'));

      expect(() => inspectionRepo.validateBeforeSubmit(report), returnsNormally);
      await inspectionRepo.submitAndLockReport(report);
      expect(report.status, equals(RecordStatus.pendingSync));
    });

    test('5. Mixed PASS / FAIL / N/A checklist -> submit allowed', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      report.checklist[0].status = CheckItemStatus.pass;
      report.checklist[1].status = CheckItemStatus.fail;
      report.checklist[2].status = CheckItemStatus.na;
      for (int i = 3; i < report.checklist.length; i++) {
        report.checklist[i].status = CheckItemStatus.pass;
      }
      report.signatureBase64 = base64Encode(utf8.encode('SIG:mixed_answers'));

      expect(() => inspectionRepo.validateBeforeSubmit(report), returnsNormally);
      await inspectionRepo.submitAndLockReport(report);
      expect(report.status, equals(RecordStatus.pendingSync));
    });

    test('6. Unanswered checklist item blocks submission', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      report.checklist[0].status = CheckItemStatus.pass;
      // rest remain unanswered
      report.signatureBase64 = base64Encode(utf8.encode('SIG:unanswered'));

      expect(
        () => inspectionRepo.validateBeforeSubmit(report),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Complete every checklist item before submitting.',
        )),
      );
    });

    test('7. Missing signature blocks submission', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      for (final item in report.checklist) {
        item.status = CheckItemStatus.pass;
      }
      report.signatureBase64 = null;

      expect(
        () => inspectionRepo.validateBeforeSubmit(report),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Please add your signature before submitting.',
        )),
      );
    });

    test('8. InspectionDto serialization preserves mixed PASS, FAIL, N/A answers exactly', () async {
      final report = await inspectionRepo.createDraft(
        user: mockUser,
        type: InspectionType.safety,
      );
      report.checklist[0].status = CheckItemStatus.pass;
      report.checklist[1].status = CheckItemStatus.fail;
      report.checklist[1].violationDescription = 'Methane sensor faulty';
      report.checklist[2].status = CheckItemStatus.na;

      final dto = InspectionDto.fromDomain(report);
      final json = dto.toJson();

      expect(json['violation_found'], equals('yes'));
      expect(json['violation_description'], contains('Methane sensor faulty'));

      final checklistJson = json['checklist'] as List;
      expect(checklistJson[0]['answer'], equals('pass'));
      expect(checklistJson[1]['answer'], equals('fail'));
      expect(checklistJson[2]['answer'], equals('not_applicable'));
    });
  });
}
