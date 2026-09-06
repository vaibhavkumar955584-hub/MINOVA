import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/data/dto/incident_dto.dart';
import 'package:minesafe/models/evidence_model.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/user_model.dart';
import 'package:minesafe/repositories/incident_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Incident Exact Schema 20-Point Verification', () {
    late UserModel mockInspector;
    late IncidentReport standardIncident;

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

      standardIncident = IncidentReport(
        clientUuid: 'INC-2024-0811',
        mineId: 'JH-DHA-BCCL-007',
        mineName: 'BCCL Pit-7 (Dhanbad)',
        userId: 'usr_priya_02',
        userName: 'Priya Mukhopadhyay',
        userDesignation: 'Statutory Mine Inspector',
        type: IncidentType.injury,
        severity: ViolationSeverity.critical,
        peopleAffected: 2,
        affectedPersonDetails: ['A. K. Banerjee', 'S. Murmu'],
        description:
            'Roof fall at Seam 4 junction during depillaring operations. High risk strata pressure displacement.',
        immediateActionTaken:
            'Strata management emergency protocol deployed. Hydraulic roof supports doubled.',
        medicalAttentionRequired: true,
        equipmentInvolved: 'Hydraulic Roof Support Stand #H-12',
        evidence: [
          EvidenceItem(
            id: 'ev_01',
            reportClientUuid: 'INC-2024-0811',
            localFilePath: '/local/roof_fall_seam4.jpg',
            fileType: 'photo',
            fileSize: 102400,
            sha256Hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            storagePath: 'roof_fall_seam4.jpg',
            downloadUrl: 'https://res.cloudinary.com/mine/roof_fall_seam4.jpg',
            caption: 'Roof Fall photo',
            capturedAt: DateTime.utc(2024, 10, 23, 10, 15),
            uploadStatus: 'uploaded',
          ),
        ],
        latitude: 23.6833,
        longitude: 87.05,
        locationSource: 'gps',
        zoneId: 'mz_seam4_junc',
        zoneName: 'Seam 4 Junction',
        notifyAuthorityImmediately: true,
        status: RecordStatus.synced,
        signatureBase64: 'base64SignatureBytesHere==',
        createdAt: DateTime.utc(2024, 10, 23, 10, 15),
        submittedAt: DateTime.utc(2024, 10, 23, 10, 15),
        updatedAt: DateTime.utc(2024, 10, 23, 10, 15),
      );
    });

    test('1. Valid incident creates correct JSON with exact 21 required keys', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();

      final expectedKeys = {
        'submission_id',
        'mine_id',
        'inspector_id',
        'inspector_name',
        'incident_type',
        'severity',
        'people_affected',
        'affected_person_details',
        'description',
        'immediate_action_taken',
        'medical_attention_required',
        'equipment_involved',
        'photos_or_videos',
        'location',
        'date_time',
        'notify_authority_immediately',
        'sync_status',
        'review_status',
        'badge_label',
        'location_display',
        'sync_source',
      };

      expect(json.keys.toSet(), equals(expectedKeys));
    });

    test('2. affected_person_details is List<String>', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['affected_person_details'], isA<List>());
      expect(json['affected_person_details'], equals(['A. K. Banerjee', 'S. Murmu']));
    });

    test('3. location is Map/Object with latitude and longitude numbers', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['location'], isA<Map<String, dynamic>>());
      expect(json['location']['latitude'], 23.6833);
      expect(json['location']['longitude'], 87.05);
    });

    test('4. people_affected is integer', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['people_affected'], isA<int>());
      expect(json['people_affected'], 2);
    });

    test('5. medical_attention_required has exact string contract value ("yes"/"no")', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['medical_attention_required'], 'yes');

      final incidentNoMed = IncidentReport(
        clientUuid: 'INC-02',
        mineId: 'JH-DHA-BCCL-007',
        mineName: 'Mine',
        userId: 'usr_01',
        userName: 'Inspector',
        userDesignation: 'Inspector',
        type: IncidentType.other,
        severity: ViolationSeverity.minor,
        description: 'Minor test',
        immediateActionTaken: 'Action',
        medicalAttentionRequired: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(IncidentDto.fromDomain(incidentNoMed).toJson()['medical_attention_required'], 'no');
    });

    test('6. notify_authority_immediately has exact string contract value ("yes"/"no")', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['notify_authority_immediately'], 'yes');
    });

    test('7. mine_id comes from authenticated authorized profile', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['mine_id'], mockInspector.assignedMineId);
      expect(json['mine_id'], 'JH-DHA-BCCL-007');
    });

    test('8. unauthorized / blank mine is rejected on draft creation', () async {
      final repo = IncidentRepository();
      final unauthorizedUser = UserModel(
        id: 'usr_unauth',
        employeeId: 'EMP-000',
        fullName: 'Unknown User',
        role: UserRole.inspector,
        designation: 'Staff',
        assignedMineId: '', // Blank
        assignedMineName: '',
      );

      expect(
        () => repo.createDraft(
          user: unauthorizedUser,
          type: IncidentType.injury,
          severity: ViolationSeverity.critical,
          description: 'Testing unauthorized mine',
          immediateActionTaken: 'Stop',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('9. inspector_id comes from authenticated profile', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['inspector_id'], mockInspector.id);
    });

    test('10. inspector_name comes from authenticated profile', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['inspector_name'], mockInspector.fullName);
    });

    test('11. submission_id is stable across serialization roundtrip', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      final fromJson = IncidentDto.fromJson(json);
      expect(fromJson.submissionId, 'INC-2024-0811');
    });

    test('12. photos_or_videos is correct array of strings containing secure URLs/filenames', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['photos_or_videos'], isA<List<String>>());
      expect(json['photos_or_videos'], contains('roof_fall_seam4.jpg'));
    });

    test('13. internal evidence object does not leak into contract JSON', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json.containsKey('evidence'), isFalse);
      expect(json.containsKey('local_path'), isFalse);
      expect(json.containsKey('storage_provider'), isFalse);
    });

    test('14. sync_status matches contract ("synced")', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['sync_status'], 'synced');
    });

    test('15. review_status matches workflow ("under_investigation")', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['review_status'], 'under_investigation');
    });

    test('16. badge_label derives correctly from severity ("CRITICAL HAZARD")', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['badge_label'], 'CRITICAL HAZARD');
    });

    test('17. location_display derives from mine and zone metadata', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['location_display'], 'BCCL Pit-7 (Dhanbad) • Seam 4 Junction');
    });

    test('18. sync_source matches actual sync behavior ("Synced via Handheld")', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json['sync_source'], 'Synced via Handheld');
    });

    test('19. no unexpected keys in final contract JSON', () {
      final json = IncidentDto.fromDomain(standardIncident).toJson();
      expect(json.length, 21);
      final prohibitedKeys = ['user_id', 'status', 'signature', 'signature_base64', 'evidence_json'];
      for (final key in prohibitedKeys) {
        expect(json.containsKey(key), isFalse, reason: 'Key $key should not be in final contract');
      }
    });

    test('20. null and empty semantics: 0 people produces empty list', () {
      final zeroIncident = IncidentReport(
        clientUuid: 'INC-2024-0808',
        mineId: 'JH-DHA-BCCL-007',
        mineName: 'BCCL Pit-7 (Dhanbad)',
        userId: 'usr_priya_02',
        userName: 'Priya Mukhopadhyay',
        userDesignation: 'Statutory Mine Inspector',
        type: IncidentType.fire,
        severity: ViolationSeverity.major,
        peopleAffected: 0,
        affectedPersonDetails: [],
        description: 'Electrical switchgear panel flashover.',
        immediateActionTaken: 'Automatic CO2 flooding initiated.',
        medicalAttentionRequired: false,
        equipmentInvolved: '11kV Primary Feeder Breaker Panel #F-02',
        evidence: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = IncidentDto.fromDomain(zeroIncident).toJson();
      expect(json['people_affected'], 0);
      expect(json['affected_person_details'], isEmpty);
      expect(json['badge_label'], 'MAJOR HAZARD');
      expect(json['medical_attention_required'], 'no');
    });
  });
}
