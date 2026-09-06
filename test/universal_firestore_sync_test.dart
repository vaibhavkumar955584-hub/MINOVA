import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/data/dto/attendance_dto.dart';
import 'package:minesafe/data/dto/document_dto.dart';
import 'package:minesafe/data/dto/incident_dto.dart';
import 'package:minesafe/data/dto/inspection_dto.dart';
import 'package:minesafe/data/dto/observation_dto.dart';
import 'package:minesafe/models/attendance_model.dart';
import 'package:minesafe/models/document_model.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/observation_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Firestore Document Schema & Ownership Verification', () {
    const authUid = 'firebase_user_uid_101';
    const mineId = 'JH-DHA-BCCL-007';

    test('1. Attendance document payload conforms strictly to canonical schema', () {
      final report = AttendanceReport(
        clientUuid: 'ATT-2026-001',
        mineId: mineId,
        mineName: 'BCCL Pit-7 (Dhanbad)',
        userId: authUid,
        userName: 'Priya Mukhopadhyay',
        shiftName: 'Morning',
        musterLocation: 'Pit-7 Main Gate',
        expectedHeadcount: 1,
        actualHeadcount: 1,
        createdAt: DateTime.utc(2026, 9, 6, 6, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 6, 0),
        entries: [
          WorkerAttendanceEntry(
            workerId: 'WRK-101',
            workerName: 'Amit Sharma',
            category: 'permanent',
            contractorName: '',
            checkInTime: DateTime.utc(2026, 9, 6, 6, 0),
          )
        ],
      );

      final dto = AttendanceDto.fromDomain(
        report,
        report.entries.first,
        latitude: 23.79,
        longitude: 86.43,
      );
      final json = dto.toJson();

      expect(json['submission_id'], equals('ATT-2026-001'));
      expect(json['mine_id'], equals(mineId));
      expect(json['worker_id'], equals('WRK-101'));
      expect(json['sync_status'], equals('pending'));
      expect(json['check_in_location'], equals({'latitude': 23.79, 'longitude': 86.43}));
    });

    test('2. Incident document payload conforms strictly to 21-field schema with authUid inspector_id', () {
      final incident = IncidentReport(
        clientUuid: 'INC-2026-001',
        mineId: mineId,
        mineName: 'BCCL Pit-7 (Dhanbad)',
        userId: authUid,
        userName: 'Priya Mukhopadhyay',
        userDesignation: 'Statutory Mine Inspector',
        type: IncidentType.equipmentFailure,
        severity: ViolationSeverity.major,
        peopleAffected: 0,
        description: 'Brake pressure loss',
        immediateActionTaken: 'Tag out vehicle',
        medicalAttentionRequired: false,
        notifyAuthorityImmediately: false,
        createdAt: DateTime.utc(2026, 9, 6, 12, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 12, 0),
      );

      final dto = IncidentDto.fromDomain(incident);
      final json = dto.toJson();

      expect(json['submission_id'], equals('INC-2026-001'));
      expect(json['mine_id'], equals(mineId));
      expect(json['inspector_id'], equals(authUid));
      expect(json['inspector_name'], equals('Priya Mukhopadhyay'));
      expect(json['sync_status'], equals('pending'));
      expect(json.length, equals(21));
    });

    test('3. Grievance/Observation document payload conforms to canonical schema', () {
      final obs = ObservationRecord(
        clientUuid: 'GRV-2026-001',
        mineId: mineId,
        mineName: 'BCCL Pit-7 (Dhanbad)',
        userId: authUid,
        userName: 'Priya Mukhopadhyay',
        entryType: ObservationType.grievance,
        category: ObservationCategory.safety,
        description: 'Airflow velocity reduction at junction 3',
        createdAt: DateTime.utc(2026, 9, 6, 14, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 14, 0),
      );

      final dto = ObservationDto.fromDomain(obs);
      final json = dto.toJson();

      expect(json['submission_id'], equals('GRV-2026-001'));
      expect(json['mine_id'], equals(mineId));
      expect(json['inspector_id'], equals(authUid));
      expect(json['text_content'], equals('Airflow velocity reduction at junction 3'));
      expect(json['priority_flagged_by_ai'], isNull);
    });

    test('4. Inspection document payload conforms to canonical schema', () {
      final insp = InspectionReport(
        clientUuid: 'SAF-INSP-2026-001',
        mineId: mineId,
        mineName: 'BCCL Pit-7 (Dhanbad)',
        userId: authUid,
        userName: 'Priya Mukhopadhyay',
        userDesignation: 'Statutory Mine Inspector',
        type: InspectionType.safety,
        checklist: [],
        createdAt: DateTime.utc(2026, 9, 6, 11, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 11, 0),
      );

      final dto = InspectionDto.fromDomain(insp);
      final json = dto.toJson();

      expect(json['submission_id'], equals('SAF-INSP-2026-001'));
      expect(json['mine_id'], equals(mineId));
      expect(json['inspector_id'], equals(authUid));
      expect(json['violation_found'], equals('no'));
    });

    test('5. Document payload conforms to canonical schema', () {
      final doc = ComplianceDocument(
        clientUuid: 'DOC-2026-001',
        mineId: mineId,
        mineName: 'BCCL Pit-7 (Dhanbad)',
        userId: authUid,
        userName: 'Priya Mukhopadhyay',
        title: 'Form IV Registration',
        category: DocumentCategory.statutoryCertificate,
        createdAt: DateTime.utc(2026, 9, 6, 9, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 9, 0),
        files: [],
      );

      final dto = DocumentDto.fromDomain(doc);
      final json = dto.toJson();

      expect(json['submission_id'], equals('DOC-2026-001'));
      expect(json['mine_id'], equals(mineId));
      expect(json['user_id'], equals(authUid));
      expect(json['title'], equals('Form IV Registration'));
    });
  });
}
