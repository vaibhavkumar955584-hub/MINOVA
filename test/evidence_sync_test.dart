import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/models/evidence_model.dart';
import 'package:minesafe/data/dto/incident_dto.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';

void main() {
  group('Universal Evidence Sync & Selective Re-upload Tests', () {
    test('Evidence items preserve stable evidence_id and SHA-256 hash', () {
      final evidence1 = EvidenceItem(
        id: 'EVD-001',
        reportClientUuid: 'INC-2026-001',
        localFilePath: '/data/user/0/com.minesafe.app/app_flutter/photo_1.jpg',
        fileType: 'photo',
        fileSize: 204800,
        sha256Hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        capturedAt: DateTime.utc(2026, 9, 6, 12, 0),
        uploadStatus: 'uploaded',
        downloadUrl: 'https://res.cloudinary.com/minesafe/image/upload/v1234/photo_1.jpg',
        storagePath: 'minesafe/incidents/photo_1',
      );

      final evidence2 = EvidenceItem(
        id: 'EVD-002',
        reportClientUuid: 'INC-2026-001',
        localFilePath: '/data/user/0/com.minesafe.app/app_flutter/photo_2.jpg',
        fileType: 'photo',
        fileSize: 102400,
        sha256Hash: 'ca978112ca1bbdcafac231b39a23dc4da7860814961409705f6fb71cad822f07',
        capturedAt: DateTime.utc(2026, 9, 6, 12, 1),
        uploadStatus: 'pending',
      );

      expect(evidence1.id, equals('EVD-001'));
      expect(evidence1.sha256Hash, isNotEmpty);
      expect(evidence1.uploadStatus, equals('uploaded'));
      expect(evidence1.downloadUrl, isNotNull);

      expect(evidence2.id, equals('EVD-002'));
      expect(evidence2.uploadStatus, equals('pending'));
      expect(evidence2.downloadUrl, isNull);
    });

    test('Partial failure logic skips already-uploaded media during retry', () {
      final items = [
        EvidenceItem(
          id: 'EVD-001',
          reportClientUuid: 'INC-2026-001',
          localFilePath: '/path/photo_1.jpg',
          fileType: 'photo',
          fileSize: 100,
          sha256Hash: 'hash1',
          uploadStatus: 'uploaded',
          downloadUrl: 'https://res.cloudinary.com/test/photo_1.jpg',
          storagePath: 'photo_1',
          capturedAt: DateTime.now(),
        ),
        EvidenceItem(
          id: 'EVD-002',
          reportClientUuid: 'INC-2026-001',
          localFilePath: '/path/photo_2.jpg',
          fileType: 'photo',
          fileSize: 100,
          sha256Hash: 'hash2',
          uploadStatus: 'uploaded',
          downloadUrl: 'https://res.cloudinary.com/test/photo_2.jpg',
          storagePath: 'photo_2',
          capturedAt: DateTime.now(),
        ),
        EvidenceItem(
          id: 'EVD-003',
          reportClientUuid: 'INC-2026-001',
          localFilePath: '/path/photo_3.jpg',
          fileType: 'photo',
          fileSize: 100,
          sha256Hash: 'hash3',
          uploadStatus: 'pending',
          downloadUrl: null,
          capturedAt: DateTime.now(),
        ),
      ];

      final needsUpload = items.where((e) => e.uploadStatus != 'uploaded' || e.downloadUrl == null).toList();
      final alreadyUploaded = items.where((e) => e.uploadStatus == 'uploaded' && e.downloadUrl != null).toList();

      expect(alreadyUploaded.length, equals(2));
      expect(needsUpload.length, equals(1));
      expect(needsUpload.first.id, equals('EVD-003'));
    });

    test('Incident DTO maps hydrated Cloudinary media URLs into external contract without raw binary', () {
      final incident = IncidentReport(
        clientUuid: 'INC-2026-001',
        mineId: 'mine_dhanbad_01',
        mineName: 'BCCL Pit-7',
        userId: 'user_001',
        userName: 'Inspector Vikram',
        userDesignation: 'Safety Officer',
        type: IncidentType.equipmentFailure,
        severity: ViolationSeverity.major,
        peopleAffected: 0,
        description: 'Gas regulator fault detected at seam 3.',
        immediateActionTaken: 'Barricaded gallery and ventilated',
        medicalAttentionRequired: false,
        evidence: [
          EvidenceItem(
            id: 'EVD-001',
            reportClientUuid: 'INC-2026-001',
            localFilePath: '/local/path/photo_1.jpg',
            fileType: 'photo',
            fileSize: 100,
            sha256Hash: 'hash1',
            uploadStatus: 'uploaded',
            downloadUrl: 'https://res.cloudinary.com/minesafe/image/upload/v1/seam3_leak.jpg',
            storagePath: 'seam3_leak',
            capturedAt: DateTime.utc(2026, 9, 6, 12, 0),
          ),
        ],
        createdAt: DateTime.utc(2026, 9, 6, 12, 0),
        updatedAt: DateTime.utc(2026, 9, 6, 12, 0),
      );

      final dto = IncidentDto.fromDomain(incident);
      final json = dto.toJson();

      expect(json['photos_or_videos'], hasLength(1));
      expect(json['photos_or_videos'][0], equals('https://res.cloudinary.com/minesafe/image/upload/v1/seam3_leak.jpg'));
      expect(json.containsKey('file_bytes'), isFalse);
    });
  });
}
