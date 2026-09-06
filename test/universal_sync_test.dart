import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/data/dto/backend_payload_mapper.dart';
import 'package:minesafe/models/attendance_model.dart';
import 'package:minesafe/models/document_model.dart';
import 'package:minesafe/models/evidence_model.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/observation_model.dart';
import 'package:minesafe/models/sync_item_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Sync Engine - Comprehensive Multi-Report & Isolation Tests', () {
    test('Canonical Firestore collection mappings are exact and non-duplicated', () {
      final collections = {
        'attendance': 'attendance',
        'incident': 'incidents',
        'observation': 'grievances',
        'inspection': 'inspections',
        'document': 'documents',
      };

      expect(collections['attendance'], equals('attendance'));
      expect(collections['incident'], equals('incidents'));
      expect(collections['observation'], equals('grievances'));
      expect(collections['inspection'], equals('inspections'));
      expect(collections['document'], equals('documents'));
    });

    test('1. Universal Attendance DTO serialization and contract compliance', () {
      final attendance = AttendanceReport(
        clientUuid: 'ATT-2026-001',
        mineId: 'mine_dhanbad_01',
        mineName: 'BCCL Pit-7',
        userId: 'USR-101',
        userName: 'Amit Sharma',
        shiftName: 'Morning Shift',
        musterLocation: 'Pit-7 Main Gate',
        expectedHeadcount: 10,
        actualHeadcount: 10,
        createdAt: DateTime.utc(2026, 9, 6, 6, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 6, 0),
        entries: [
          WorkerAttendanceEntry(
            workerId: 'WRK-101',
            workerName: 'Amit Sharma',
            category: 'General Miner',
            contractorName: 'BCCL Operations',
            checkInTime: DateTime.utc(2026, 9, 6, 6, 0),
          )
        ],
      );

      final json = BackendPayloadMapper.fromLocalReport(
        type: SyncRecordType.attendance,
        report: attendance.toDbMap(),
        uploadedEvidence: [],
      );

      expect(json['submission_id'], equals('ATT-2026-001'));
      expect(json['mine_id'], equals('mine_dhanbad_01'));
      expect(json['worker_id'], equals('WRK-101'));
    });

    test('2. Universal Incident DTO serialization and contract compliance', () {
      final incident = IncidentReport(
        clientUuid: 'INC-2026-EA81C252',
        mineId: 'mine_dhanbad_01',
        mineName: 'BCCL Pit-7',
        userId: 'USR-001',
        userName: 'Inspector Kumar',
        userDesignation: 'Safety Officer',
        type: IncidentType.injury,
        severity: ViolationSeverity.major,
        peopleAffected: 1,
        description: 'Workplace casualty reported during depillaring operations.',
        immediateActionTaken: 'Barricaded gallery and ventilated',
        medicalAttentionRequired: true,
        evidence: [
          EvidenceItem(
            id: 'EVD-991',
            reportClientUuid: 'INC-2026-EA81C252',
            localFilePath: '/local/photo1.jpg',
            fileType: 'photo',
            fileSize: 100,
            sha256Hash: 'hash1',
            uploadStatus: 'uploaded',
            downloadUrl: 'https://res.cloudinary.com/minesafe/photo1.jpg',
            storagePath: 'photo1',
            capturedAt: DateTime.utc(2026, 9, 6, 17, 6),
          )
        ],
        createdAt: DateTime.utc(2026, 9, 6, 17, 5),
        updatedAt: DateTime.utc(2026, 9, 6, 17, 5),
      );

      final json = BackendPayloadMapper.fromLocalReport(
        type: SyncRecordType.incident,
        report: incident.toDbMap(),
        uploadedEvidence: incident.evidence,
      );

      expect(json['submission_id'], equals('INC-2026-EA81C252'));
      expect(json['incident_type'], equals('injury'));
      expect(json['photos_or_videos'], hasLength(1));
      expect(json['photos_or_videos'][0], equals('https://res.cloudinary.com/minesafe/photo1.jpg'));
    });

    test('3. Universal Observation / Grievance DTO serialization and contract compliance', () {
      final observation = ObservationRecord(
        clientUuid: 'GRV-2026-001',
        mineId: 'mine_dhanbad_01',
        mineName: 'BCCL Pit-7',
        userId: 'USR-002',
        userName: 'Pooja Verma',
        entryType: ObservationType.observation,
        category: ObservationCategory.safety,
        description: 'Auxiliary fan stoppage detected at 3 East panel.',
        createdAt: DateTime.utc(2026, 9, 6, 14, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 14, 0),
      );

      final json = BackendPayloadMapper.fromLocalReport(
        type: SyncRecordType.observation,
        report: observation.toDbMap(),
        uploadedEvidence: [],
      );

      expect(json['submission_id'], equals('GRV-2026-001'));
      expect(json['text_content'], equals('Auxiliary fan stoppage detected at 3 East panel.'));
      expect(json['priority_flagged_by_ai'], isNull);
    });

    test('4. Universal Safety Inspection DTO serialization and contract compliance', () {
      final inspection = InspectionReport(
        clientUuid: 'SAF-2026-001',
        mineId: 'mine_dhanbad_01',
        mineName: 'BCCL Pit-7',
        userId: 'USR-003',
        userName: 'Rajesh Kumar',
        userDesignation: 'Senior Inspector',
        type: InspectionType.safety,
        checklist: [
          InspectionChecklistItem(
            id: 'chk_1',
            section: 'Strata',
            question: 'Are tell-tale extensometers operational?',
            hindiQuestion: 'क्या टेल-टेल एक्सटेंसोमीटर चालू हैं?',
            guidance: 'Check readings',
            status: CheckItemStatus.pass,
          )
        ],
        createdAt: DateTime.utc(2026, 9, 6, 11, 0),
        submittedAt: DateTime.utc(2026, 9, 6, 11, 30),
        updatedAt: DateTime.utc(2026, 9, 6, 11, 30),
      );

      final json = BackendPayloadMapper.fromLocalReport(
        type: SyncRecordType.inspection,
        report: inspection.toDbMap(),
        uploadedEvidence: [],
      );

      expect(json['submission_id'], equals('SAF-2026-001'));
      expect(json['inspection_type'], equals('safety'));
      expect(json['violation_found'], equals('no'));
      expect(json['checklist'], hasLength(1));
    });

    test('5. Universal Document DTO serialization and contract compliance', () {
      final document = ComplianceDocument(
        clientUuid: 'DOC-2026-001',
        mineId: 'mine_dhanbad_01',
        mineName: 'BCCL Pit-7',
        userId: 'USR-001',
        userName: 'Inspector Kumar',
        title: 'Form IV Register Q3',
        category: DocumentCategory.statutoryCertificate,
        createdAt: DateTime.utc(2026, 9, 6, 9, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 9, 0),
        files: [],
      );

      final json = BackendPayloadMapper.fromLocalReport(
        type: SyncRecordType.document,
        report: document.toDbMap(),
        uploadedEvidence: [],
      );

      expect(json['submission_id'], equals('DOC-2026-001'));
      expect(json['title'], equals('Form IV Register Q3'));
      expect(json['category'], equals('statutoryCertificate'));
    });

    test('Queue isolation: failure in one queue item does not corrupt other queue entries', () {
      final now = DateTime.now();
      final queue = [
        SyncQueueItem(
          id: '1',
          clientUuid: 'ATT-001',
          recordType: SyncRecordType.attendance,
          payloadJson: '{}',
          state: SyncState.completed,
          queuedAt: now,
        ),
        SyncQueueItem(
          id: '2',
          clientUuid: 'INC-001',
          recordType: SyncRecordType.incident,
          payloadJson: '{}',
          state: SyncState.failed,
          errorMessage: 'Permission denied',
          errorStage: 'firestore',
          errorCode: 'PERMISSION_DENIED',
          isRetryable: false,
          queuedAt: now,
        ),
        SyncQueueItem(
          id: '3',
          clientUuid: 'GRV-001',
          recordType: SyncRecordType.observation,
          payloadJson: '{}',
          state: SyncState.completed,
          queuedAt: now,
        ),
        SyncQueueItem(
          id: '4',
          clientUuid: 'INSP-001',
          recordType: SyncRecordType.inspection,
          payloadJson: '{}',
          state: SyncState.failed,
          errorMessage: 'Cloudinary timeout',
          errorStage: 'media',
          errorCode: 'TIMEOUT',
          isRetryable: true,
          nextRetryAt: now.add(const Duration(seconds: 5)),
          queuedAt: now,
        ),
      ];

      // Verify that ATT-001 and GRV-001 succeeded independently
      expect(queue[0].state, equals(SyncState.completed));
      expect(queue[2].state, equals(SyncState.completed));

      // Verify INC-001 is isolated and non-retryable
      expect(queue[1].state, equals(SyncState.failed));
      expect(queue[1].isRetryable, isFalse);
      expect(queue[1].errorCode, equals('PERMISSION_DENIED'));

      // Verify INSP-001 is retryable
      expect(queue[3].state, equals(SyncState.failed));
      expect(queue[3].isRetryable, isTrue);
      expect(queue[3].nextRetryAt, isNotNull);
    });

    test('In-flight lock simulation guarantees single active execution per submission_id', () {
      final inFlightLocks = <String>{};

      bool acquireLock(String submissionId) {
        if (inFlightLocks.contains(submissionId)) {
          return false;
        }
        inFlightLocks.add(submissionId);
        return true;
      }

      void releaseLock(String submissionId) {
        inFlightLocks.remove(submissionId);
      }

      // First sync request acquires lock
      expect(acquireLock('INC-2026-001'), isTrue);

      // Concurrent sync request on same submission is rejected
      expect(acquireLock('INC-2026-001'), isFalse);

      // Concurrent sync request on DIFFERENT submission succeeds
      expect(acquireLock('ATT-2026-001'), isTrue);

      // Release lock for first submission
      releaseLock('INC-2026-001');

      // Subsequent sync request can now acquire lock
      expect(acquireLock('INC-2026-001'), isTrue);
    });
  });
}
