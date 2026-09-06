import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/evidence/evidence_service.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/user_model.dart';
import 'package:minesafe/repositories/incident_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late UserModel mockInspector;
  late IncidentRepository repo;

  setUp(() {
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
    repo = IncidentRepository();
  });

  group('Incident Session & Draft SQLite Persistence Tests', () {
    test('1. Draft auto-saves and is retrievable by client UUID', () async {
      const testUuid = 'INC-EMG-DRAFT-PERSIST-01';
      final draft = await repo.createDraft(
        clientUuid: testUuid,
        user: mockInspector,
        type: IncidentType.injury,
        severity: ViolationSeverity.critical,
        description: 'Initial draft before camera open.',
        immediateActionTaken: 'First aid applied.',
        peopleAffected: 2,
        affectedPersonDetails: ['S. K. Verma', 'M. Soren'],
        medicalAttentionRequired: true,
      );

      expect(draft.clientUuid, equals(testUuid));

      // Modify draft & autoSave
      final updatedDraft = IncidentReport(
        clientUuid: testUuid,
        mineId: draft.mineId,
        mineName: draft.mineName,
        userId: draft.userId,
        userName: draft.userName,
        userDesignation: draft.userDesignation,
        type: draft.type,
        severity: ViolationSeverity.major,
        peopleAffected: draft.peopleAffected,
        affectedPersonDetails: draft.affectedPersonDetails,
        description: draft.description,
        immediateActionTaken: draft.immediateActionTaken,
        medicalAttentionRequired: draft.medicalAttentionRequired,
        equipmentInvolved: draft.equipmentInvolved,
        notifyAuthorityImmediately: draft.notifyAuthorityImmediately,
        status: draft.status,
        createdAt: draft.createdAt,
        updatedAt: DateTime.now(),
      );
      await repo.autoSaveDraft(updatedDraft);

      // Retrieve from SQLite
      final retrieved = await repo.getDraftByClientUuid(testUuid);
      expect(retrieved, isNotNull);
      expect(retrieved!.clientUuid, equals(testUuid));
      expect(retrieved.severity, equals(ViolationSeverity.major));
      expect(retrieved.description, equals('Initial draft before camera open.'));
      expect(retrieved.affectedPersonDetails.length, equals(2));
      expect(retrieved.affectedPersonDetails[0], equals('S. K. Verma'));
    });

    test('2. Evidence insertion persists with SHA-256 and links to Incident clientUuid', () async {
      const testUuid = 'INC-EMG-EVIDENCE-LINK-01';
      final evService = EvidenceService.instance;

      final photo = await evService.capturePhoto(
        reportClientUuid: testUuid,
        caption: 'Highwall Spalling Fracture',
        fallbackToSimulated: true,
      );

      expect(photo, isNotNull);
      expect(photo!.reportClientUuid, equals(testUuid));
      expect(photo.sha256Hash.length, equals(64));
      expect(photo.fileType, equals('photo'));

      final draft = await repo.createDraft(
        clientUuid: testUuid,
        user: mockInspector,
        type: IncidentType.other,
        severity: ViolationSeverity.major,
        description: 'Highwall fracture observation.',
        immediateActionTaken: 'Cordoned off bench.',
      );
      draft.evidence.add(photo);
      await repo.autoSaveDraft(draft);

      final loaded = await repo.getDraftByClientUuid(testUuid);
      expect(loaded, isNotNull);
      expect(loaded!.evidence.length, equals(1));
      expect(loaded.evidence.first.sha256Hash, equals(photo.sha256Hash));
      expect(loaded.evidence.first.reportClientUuid, equals(testUuid));
    });

    test('3. Submission without signature is strictly blocked', () async {
      const testUuid = 'INC-EMG-NO-SIG-01';
      final draft = await repo.createDraft(
        clientUuid: testUuid,
        user: mockInspector,
        type: IncidentType.gasLeak,
        severity: ViolationSeverity.critical,
        description: 'CO level elevated at Return Airway.',
        immediateActionTaken: 'Evacuated district.',
      );

      // Verify validation fails
      expect(
        () => repo.submitAndLockIncident(draft),
        throwsA(isA<FormatException>()),
      );
    });

    test('4. Full Submit & Lock calculates integrity hash and locks draft', () async {
      const testUuid = 'INC-EMG-LOCK-01';
      final draft = await repo.createDraft(
        clientUuid: testUuid,
        user: mockInspector,
        type: IncidentType.equipmentFailure,
        severity: ViolationSeverity.major,
        description: 'Winder rope tension anomaly.',
        immediateActionTaken: 'Emergency brake tested.',
      );

      draft.signatureBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
      draft.signedAt = DateTime.now();

      await repo.submitAndLockIncident(draft);

      final submitted = await repo.getDraftByClientUuid(testUuid);
      expect(submitted, isNotNull);
      expect(submitted!.status, equals(RecordStatus.pendingSync));
      expect(submitted.integrityHash, isNotNull);
      expect(submitted.integrityHash!.length, equals(64));
    });
  });
}
