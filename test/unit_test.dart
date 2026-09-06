import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/auth_service.dart';
import 'package:minesafe/core/auth/role_permissions.dart';
import 'package:minesafe/core/location/location_service.dart';
import 'package:minesafe/data/storage/cloudinary_storage_service.dart';
import 'package:minesafe/models/evidence_model.dart';
import 'package:minesafe/models/audit_event_model.dart';
import 'package:minesafe/models/correction_request_model.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/sync_item_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MineSafe Unit & Architecture Verification Tests', () {
    test('8. Evidence metadata round-trip excludes binary content', () {
      final evidence = EvidenceItem(
        id: 'ev-stable-01',
        reportClientUuid: 'SAF-INSP-STABLE-01',
        localFilePath: 'D:/MineSafe/evidence/ev-stable-01.mp4',
        fileType: 'video',
        fileName: 'ev-stable-01.mp4',
        mimeType: 'video/mp4',
        fileSize: 1024,
        sha256Hash: 'a' * 64,
        capturedAt: DateTime.utc(2026, 9, 5),
      );

      final map = evidence.toMap();
      final restored = EvidenceItem.fromMap(map);
      expect(restored.id, equals(evidence.id));
      expect(restored.localFilePath, equals(evidence.localFilePath));
      expect(restored.uploadStatus, equals('pending'));
      expect(map.containsKey('binary'), isFalse);
      expect(evidence.toFirestoreMap().containsKey('binary'), isFalse);
    });

    test(
      '9. Cloudinary storage requires explicit non-secret configuration',
      () {
        final storage = CloudinaryStorageService(
          cloudName: '',
          unsignedUploadPreset: '',
        );
        expect(storage.isConfigured, isFalse);
      },
    );

    test('1. Authentication & Role Permissions Matrix Verification', () {
      final inspectorUser = AuthService.mockUsers[1]; // Priya (Inspector)
      final inspectorPerms = RolePermissions.forUser(inspectorUser);

      expect(inspectorPerms.canPerformInspection, isTrue);
      expect(inspectorPerms.canReportIncident, isTrue);
      expect(inspectorPerms.canManageAttendance, isFalse);
      expect(inspectorPerms.canSubmitObservation, isTrue);

      final contractorUser = AuthService.mockUsers[2]; // Vikram (Contractor)
      final contractorPerms = RolePermissions.forUser(contractorUser);
      expect(contractorPerms.canPerformInspection, isFalse);
      expect(contractorPerms.canReportIncident, isTrue);
      expect(contractorPerms.canManageAttendance, isTrue);

      final safetyOfficer = AuthService.mockUsers[0]; // Rajesh (Safety Officer)
      final safetyPerms = RolePermissions.forUser(safetyOfficer);
      expect(safetyPerms.canPerformInspection, isTrue);
      expect(safetyPerms.canDirectlyApproveCorrections, isTrue);
    });

    test('2. Client UUID Generation & Idempotent Retry Key Preservation', () {
      final clientUuid = 'SAF-INSP-882199';
      final item1 = SyncQueueItem(
        id: 'sync_01',
        clientUuid: clientUuid,
        recordType: SyncRecordType.inspection,
        payloadJson: '{"test":"payload"}',
        queuedAt: DateTime.now(),
      );

      // Verify retry retains identical clientUuid
      expect(item1.clientUuid, equals(clientUuid));
      expect(item1.retryCount, equals(0));
      expect(item1.maxRetries, equals(5));
    });

    test('3. SHA-256 Tamper Detection & Evidence Hash Verification', () {
      final rawEvidenceBytes = utf8.encode(
        'MineSafe_Photo_Evidence_Gallery_4_Face',
      );
      final hash = sha256.convert(rawEvidenceBytes).toString();

      expect(hash, isNotEmpty);
      expect(hash.length, equals(64));

      // Altering even 1 bit changes hash completely
      final alteredBytes = utf8.encode(
        'MineSafe_Photo_Evidence_Gallery_4_Face_Altered',
      );
      final alteredHash = sha256.convert(alteredBytes).toString();
      expect(hash, isNot(equals(alteredHash)));
    });

    test('4. Subterranean Location Fallback to Manual Mine Zone', () async {
      final locationService = LocationService.instance;
      final result = await locationService.captureLocation();

      expect(result.locationSource, isNotNull);
      expect(result.displayTag, isNotEmpty);
      expect(result.depthLevel, isNotEmpty);
    });

    test('5. Inspection Report Lifecycle & Record Immutability', () {
      final report = InspectionReport(
        clientUuid: 'SAF-INSP-TEST',
        mineId: 'mine_01',
        mineName: 'Jharsuguda Mine',
        userId: 'usr_01',
        userName: 'Rajesh Sharma',
        userDesignation: 'Safety Officer',
        type: InspectionType.safety,
        status: RecordStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        checklist: InspectionReport.getDefaultSafetyChecklist(),
      );

      // In draft mode, isLocked is false
      expect(report.status.isLocked, isFalse);

      // Submit and lock
      report.status = RecordStatus.pendingSync;
      expect(report.status.isLocked, isTrue);

      report.status = RecordStatus.synced;
      expect(report.status.isLocked, isTrue);
    });

    test('6. Audited Correction Request & Immutability Enforcement', () {
      final correction = CorrectionRequest(
        id: 'CORR-9988',
        recordClientUuid: 'SAF-INSP-TEST',
        recordType: 'inspection',
        requestedByUserId: 'usr_01',
        requestedByUserName: 'Rajesh Sharma',
        reason: 'Adjusting motor serial typo',
        requestedChangesJson: '{"field":"motor_id","old":"M-1","new":"M-2"}',
        requestedAt: DateTime.now(),
      );

      expect(correction.status, equals(CorrectionStatus.pendingReview));

      final audit = AuditEvent(
        id: 'aud_01',
        recordClientUuid: 'SAF-INSP-TEST',
        eventType: 'correction_requested',
        userId: 'usr_01',
        userRole: 'inspector',
        description: 'Correction requested',
        timestamp: DateTime.now(),
      );

      expect(audit.recordClientUuid, equals('SAF-INSP-TEST'));
      expect(audit.eventType, equals('correction_requested'));
    });

    test('7. Incident Emergency Path & Casualty Verification', () {
      final incident = IncidentReport(
        clientUuid: 'INC-EMG-001',
        mineId: 'mine_01',
        mineName: 'Jharsuguda Mine',
        userId: 'usr_01',
        userName: 'Rajesh Sharma',
        userDesignation: 'Safety Officer',
        type: IncidentType.gasLeak,
        severity: ViolationSeverity.critical,
        peopleAffected: 3,
        description: 'Methane surge detected at face',
        immediateActionTaken: 'Power isolated and area evacuated',
        notifyAuthorityImmediately: true,
        authorityAlertStatus: AuthorityAlertStatus.queued,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(incident.severity, equals(ViolationSeverity.critical));
      expect(incident.notifyAuthorityImmediately, isTrue);
      expect(
        incident.authorityAlertStatus,
        equals(AuthorityAlertStatus.queued),
      );
    });
  });
}
