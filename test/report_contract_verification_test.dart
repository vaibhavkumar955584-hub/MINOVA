import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/data/dto/attendance_dto.dart';
import 'package:minesafe/data/dto/backend_payload_mapper.dart';
import 'package:minesafe/data/dto/document_dto.dart';
import 'package:minesafe/data/dto/incident_dto.dart';
import 'package:minesafe/data/dto/inspection_dto.dart';
import 'package:minesafe/data/dto/observation_dto.dart';
import 'package:minesafe/models/attendance_model.dart';
import 'package:minesafe/models/document_model.dart';
import 'package:minesafe/models/evidence_model.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/observation_model.dart';
import 'package:minesafe/models/sync_item_model.dart';
import 'package:minesafe/repositories/incident_repository.dart';
import 'package:minesafe/repositories/inspection_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Safety Inspection Contract & Validation Tests', () {
    test('Valid inspection with NO violations produces violation_found="no" and null conditional fields', () {
      final report = InspectionReport(
        clientUuid: 'SAF-INSP-001',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Pit-4',
        userId: 'user_insp_007',
        userName: 'Rajesh Kumar',
        userDesignation: 'Senior Mining Inspector',
        type: InspectionType.safety,
        checklist: [
          InspectionChecklistItem(
            id: 'chk_1',
            section: 'Ventilation',
            question: 'Is auxiliary ventilation operating normally?',
            guidance: 'Check air velocity',
            hindiQuestion: 'क्या वेंटिलेशन चालू है?',
            status: CheckItemStatus.pass,
          ),
          InspectionChecklistItem(
            id: 'chk_2',
            section: 'Strata Control',
            question: 'Are roof bolts tested for anchorage capacity?',
            guidance: 'Min 6 ton anchor load',
            hindiQuestion: 'क्या रूफ बोल्ट की जांच की गई है?',
            status: CheckItemStatus.na,
          ),
        ],
        latitude: 21.85,
        longitude: 84.01,
        status: RecordStatus.synced,
        createdAt: DateTime.utc(2026, 9, 6, 10, 0),
        submittedAt: DateTime.utc(2026, 9, 6, 10, 30),
        updatedAt: DateTime.utc(2026, 9, 6, 10, 30),
      );

      final dto = InspectionDto.fromDomain(report);
      final json = dto.toJson();

      expect(json['violation_found'], equals('no'));
      expect(json['violation_severity'], isNull);
      expect(json['violation_description'], isNull);
      expect(json['corrective_action'], isNull);
      expect(json['checklist'], hasLength(2));
      expect(json['checklist'][0]['answer'], equals('pass'));
      expect(json['checklist'][1]['answer'], equals('not_applicable'));
      expect(json['submission_id'], equals('SAF-INSP-001'));
      expect(json['location'], equals({'latitude': 21.85, 'longitude': 84.01}));
    });

    test('Inspection with violations produces violation_found="yes" and populated severity/action', () {
      final report = InspectionReport(
        clientUuid: 'SAF-INSP-002',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Pit-4',
        userId: 'user_insp_007',
        userName: 'Rajesh Kumar',
        userDesignation: 'Senior Mining Inspector',
        type: InspectionType.safety,
        checklist: [
          InspectionChecklistItem(
            id: 'chk_1',
            section: 'Strata Control',
            question: 'Are side-wall supports erected at junction?',
            guidance: 'CMR 2017 Reg 123',
            hindiQuestion: 'क्या सपोर्ट लगाए गए हैं?',
            status: CheckItemStatus.fail,
            severity: ViolationSeverity.critical,
            violationDescription: 'Excessive spalling from side-wall at 4th dipole junction',
            correctiveAction: 'Immediately erect steel arch supports and barricade area',
            deadline: DateTime.utc(2026, 9, 8),
          ),
        ],
        latitude: 21.85,
        longitude: 84.01,
        status: RecordStatus.synced,
        createdAt: DateTime.utc(2026, 9, 6, 10, 0),
        submittedAt: DateTime.utc(2026, 9, 6, 10, 30),
        updatedAt: DateTime.utc(2026, 9, 6, 10, 30),
      );

      final dto = InspectionDto.fromDomain(report);
      final json = dto.toJson();

      expect(json['violation_found'], equals('yes'));
      expect(json['violation_severity'], equals('critical'));
      expect(json['violation_description'], contains('spalling'));
      expect(json['corrective_action'], contains('steel arch'));
    });

    test('Inspection missing signature is rejected by repository validator', () {
      final repo = InspectionRepository();
      final report = InspectionReport(
        clientUuid: 'SAF-INSP-UNS',
        mineId: 'mine_01',
        mineName: 'Test Mine',
        userId: 'user_01',
        userName: 'Tester',
        userDesignation: 'Inspector',
        type: InspectionType.safety,
        checklist: [
          InspectionChecklistItem(
            id: 'chk_1',
            section: 'General',
            question: 'All ok?',
            guidance: '',
            hindiQuestion: '',
            status: CheckItemStatus.pass,
          ),
        ],
        signatureBase64: null, // MISSING
        locationSource: 'manual',
        zoneId: 'mz_01',
        zoneName: 'Zone 1',
        createdAt: DateTime.utc(2026, 9, 6, 10, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 10, 0),
      );

      expect(() => repo.validateBeforeSubmit(report), throwsA(isA<FormatException>()));
    });
  });

  group('2. Incident Report Contract & Validation Tests', () {
    test('Incident DTO strictly maps string booleans "yes"/"no" and captures all contract keys', () {
      final incident = IncidentReport(
        clientUuid: 'INC-EMG-001',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Pit-4',
        userId: 'user_insp_007',
        userName: 'Rajesh Kumar',
        userDesignation: 'Senior Inspector',
        type: IncidentType.gasLeak,
        severity: ViolationSeverity.critical,
        peopleAffected: 3,
        affectedPersonDetails: 'Worker EMP-101, EMP-102, EMP-103',
        description: 'Methane surge detected exceeding 2.0% at longwall face',
        immediateActionTaken: 'Power isolated, auxiliary fan switched to boost, section evacuated',
        medicalAttentionRequired: true,
        equipmentInvolved: 'Continuous Miner CM-02',
        notifyAuthorityImmediately: true,
        latitude: 21.85,
        longitude: 84.01,
        status: RecordStatus.synced,
        createdAt: DateTime.utc(2026, 9, 6, 11, 0),
        submittedAt: DateTime.utc(2026, 9, 6, 11, 15),
        updatedAt: DateTime.utc(2026, 9, 6, 11, 15),
      );

      final dto = IncidentDto.fromDomain(incident);
      final json = dto.toJson();

      expect(json['medical_attention_required'], equals('yes'));
      expect(json['notify_authority_immediately'], equals('yes'));
      expect(json['severity'], equals('critical'));
      expect(json['incident_type'], equals('gas_leak'));
      expect(json['people_affected'], equals(3));
      expect(json['location'], equals({'latitude': 21.85, 'longitude': 84.01}));
    });

    test('Incident missing signature throws FormatException', () {
      final repo = IncidentRepository();
      final incident = IncidentReport(
        clientUuid: 'INC-EMG-002',
        mineId: 'mine_01',
        mineName: 'Mine 1',
        userId: 'user_01',
        userName: 'User 1',
        userDesignation: 'Inspector',
        type: IncidentType.injury,
        severity: ViolationSeverity.major,
        peopleAffected: 1,
        description: 'Minor leg strain',
        immediateActionTaken: 'First aid applied',
        signatureBase64: '   ', // Blank
        createdAt: DateTime.utc(2026, 9, 6, 11, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 11, 0),
      );

      expect(() => repo.validateBeforeSubmit(incident), throwsA(isA<FormatException>()));
    });
  });

  group('3. Attendance Contract & Validation Tests', () {
    test('Attendance DTO serializes nested check_in_location and excludes check_out on check-in', () {
      final report = AttendanceReport(
        clientUuid: 'ATT-ROST-001',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Pit-4',
        userId: 'user_insp_007',
        userName: 'Rajesh Kumar',
        shiftName: 'Shift A (06:00 - 14:00)',
        musterLocation: 'Pit-4 Main Shaft Muster Gate',
        expectedHeadcount: 10,
        actualHeadcount: 9,
        entries: [],
        status: RecordStatus.synced,
        createdAt: DateTime.utc(2026, 9, 6, 6, 0),
        submittedAt: DateTime.utc(2026, 9, 6, 6, 30),
        updatedAt: DateTime.utc(2026, 9, 6, 6, 30),
      );

      final entry = WorkerAttendanceEntry(
        workerId: 'WRK-001',
        workerName: 'Sunil Munda',
        category: 'permanent',
        contractorName: 'CIL Direct',
        checkInTime: DateTime.utc(2026, 9, 6, 6, 5),
        checkOutTime: null,
      );

      final dto = AttendanceDto.fromDomain(
        report,
        entry,
        contractorId: 'CONT-CIL-01',
        latitude: 21.8512,
        longitude: 84.0125,
      );

      final json = dto.toJson();
      expect(json['worker_id'], equals('WRK-001'));
      expect(json['shift'], equals('Shift A (06:00 - 14:00)'));
      expect(json['check_in_location'], equals({'latitude': 21.8512, 'longitude': 84.0125}));
      expect(json['check_out_time'], isNull);
      expect(json['check_out_location'], isNull);
      expect(json['expected_headcount'], equals(10));
      expect(json['actual_headcount'], equals(9));
    });

    test('Attendance throws FormatException when GPS location is missing', () {
      final report = AttendanceReport(
        clientUuid: 'ATT-ROST-002',
        mineId: 'mine_01',
        mineName: 'Mine 1',
        userId: 'u1',
        userName: 'Tester',
        shiftName: 'Morning',
        musterLocation: 'Gate',
        expectedHeadcount: 5,
        actualHeadcount: 5,
        entries: [],
        createdAt: DateTime.utc(2026, 9, 6, 6, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 6, 0),
      );
      final entry = WorkerAttendanceEntry(
        workerId: 'W1',
        workerName: 'Worker 1',
        category: 'contractor',
        contractorName: 'ABC',
        checkInTime: DateTime.now(),
      );

      expect(
        () => AttendanceDto.fromDomain(report, entry, latitude: null, longitude: null),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('4. Observation Contract & AI Field Invariant Tests', () {
    test('Observation DTO preserves original text and leaves priority_flagged_by_ai as null', () {
      final obs = ObservationRecord(
        clientUuid: 'OBS-LOG-001',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Pit-4',
        userId: 'user_insp_007',
        userName: 'Rajesh Kumar',
        entryType: ObservationType.observation,
        category: ObservationCategory.gasReading,
        description: 'CH4 meter detected 0.8% near heading 3, slight damp smell',
        ch4Percent: 0.8,
        coPpm: 12,
        o2Percent: 20.4,
        latitude: 21.85,
        longitude: 84.01,
        status: RecordStatus.synced,
        createdAt: DateTime.utc(2026, 9, 6, 9, 0),
        submittedAt: DateTime.utc(2026, 9, 6, 9, 10),
        updatedAt: DateTime.utc(2026, 9, 6, 9, 10),
      );

      final dto = ObservationDto.fromDomain(obs);
      final json = dto.toJson();

      expect(json['entry_type'], equals('observation'));
      expect(json['category'], equals('gasReading'));
      expect(json['text_content'], contains('CH4 meter detected 0.8%'));
      expect(json['priority_flagged_by_ai'], isNull, reason: 'Mobile must never fabricate AI priority');
      expect(json['submission_id'], equals('OBS-LOG-001'));
    });
  });

  group('5. Compliance Document Contract & Entity Tests', () {
    test('Document DTO serializes certificate details, expiry and file list cleanly', () {
      final doc = ComplianceDocument(
        clientUuid: 'DOC-CMP-001',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Pit-4',
        userId: 'user_insp_007',
        userName: 'Rajesh Kumar',
        category: DocumentCategory.equipmentFitnessCertificate,
        title: 'Flameproof Switchgear Certificate - Substation 3',
        documentNumber: 'DGMS/FLP/2026/8942',
        associatedContractor: 'Siemens Mining India',
        expiryDate: DateTime.utc(2027, 3, 31),
        remarks: 'Valid for Zone 1 underground hazardous atmosphere',
        files: [
          EvidenceItem(
            id: 'ev_flp_01',
            reportClientUuid: 'DOC-CMP-001',
            localFilePath: '/local/cert.jpg',
            fileType: 'photo',
            fileSize: 204800,
            sha256Hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            capturedAt: DateTime.utc(2026, 9, 6, 8, 0),
            downloadUrl: 'https://res.cloudinary.com/minesafe/flp_cert.jpg',
          ),
        ],
        status: RecordStatus.synced,
        createdAt: DateTime.utc(2026, 9, 6, 8, 0),
        submittedAt: DateTime.utc(2026, 9, 6, 8, 15),
        updatedAt: DateTime.utc(2026, 9, 6, 8, 15),
      );

      final dto = DocumentDto.fromDomain(doc);
      final json = dto.toJson();

      expect(json['category'], equals('equipmentFitnessCertificate'));
      expect(json['document_number'], equals('DGMS/FLP/2026/8942'));
      expect(json['associated_contractor'], equals('Siemens Mining India'));
      expect(json['expiry_date'], equals('2027-03-31T00:00:00.000Z'));
      expect(json['files'], contains('https://res.cloudinary.com/minesafe/flp_cert.jpg'));
    });
  });

  group('6. Backend Payload Mapper & Boundary Integrity Tests', () {
    test('BackendPayloadMapper strips all mobile-internal fields before transport', () {
      final rawDbInspection = {
        'client_uuid': 'SAF-INSP-HYD',
        'server_id': 'srv_123',
        'mine_id': 'mine_01',
        'mine_name': 'Test Mine',
        'user_id': 'u1',
        'user_name': 'Tester',
        'user_designation': 'Inspector',
        'type': 'safety',
        'status': 'pending_sync',
        'created_at': '2026-09-06T10:00:00.000Z',
        'submitted_at': '2026-09-06T10:15:00.000Z',
        'updated_at': '2026-09-06T10:15:00.000Z',
        'version': 1,
        'latitude': 21.85,
        'longitude': 84.01,
        'accuracy': 5.0,
        'location_source': 'gps',
        'zone_id': 'mz_01',
        'zone_name': 'Main North',
        'checklist_json': '[]',
        'global_evidence_json': '[]',
        'signature_base64': 'dGVzdA==',
        'signature_hash': 'sig_hash_123',
        'integrity_hash': 'integ_hash_456',
        'signed_at': '2026-09-06T10:15:00.000Z',
        'sync_error': null,
      };

      final payload = BackendPayloadMapper.fromLocalReport(
        type: SyncRecordType.inspection,
        report: rawDbInspection,
        uploadedEvidence: [],
      );

      expect(payload.containsKey('clientUuid'), isFalse);
      expect(payload.containsKey('localPath'), isFalse);
      expect(payload.containsKey('retryCount'), isFalse);
      expect(payload.containsKey('uploadAttempts'), isFalse);
      expect(payload.containsKey('locationSource'), isFalse);
      expect(payload.containsKey('locationAccuracy'), isFalse);
      expect(payload.containsKey('zoneName'), isFalse);
      expect(payload.containsKey('integrityHash'), isFalse);
      expect(payload.containsKey('signatureHash'), isFalse);
      expect(payload.containsKey('uploadStatus'), isFalse);
      expect(payload.containsKey('storagePath'), isFalse);
      expect(payload['submission_id'], equals('SAF-INSP-HYD'));
      expect(payload['mine_id'], equals('mine_01'));
      expect(payload['violation_found'], equals('no'));
    });
  });
}
