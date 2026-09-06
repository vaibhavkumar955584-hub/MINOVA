import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/data/dto/attendance_dto.dart';
import 'package:minesafe/data/dto/backend_payload_mapper.dart';
import 'package:minesafe/data/dto/contractor_dto.dart';
import 'package:minesafe/data/dto/document_dto.dart';
import 'package:minesafe/data/dto/incident_dto.dart';
import 'package:minesafe/data/dto/inspection_dto.dart';
import 'package:minesafe/data/dto/mine_dto.dart';
import 'package:minesafe/data/dto/observation_dto.dart';
import 'package:minesafe/data/dto/user_dto.dart';
import 'package:minesafe/models/attendance_model.dart';
import 'package:minesafe/models/document_model.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/mine_model.dart';
import 'package:minesafe/models/observation_model.dart';
import 'package:minesafe/models/sync_item_model.dart';
import 'package:minesafe/models/user_model.dart';

void main() {
  group('InspectionDto Tests', () {
    test('serializes with exact snake_case keys and no-violation semantics', () {
      final report = InspectionReport(
        clientUuid: 'INSP-101',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Mine (Pit-4)',
        userId: 'usr_priya_02',
        userName: 'Priya Mukhopadhyay',
        userDesignation: 'Statutory Mine Inspector',
        type: InspectionType.safety,
        createdAt: DateTime.utc(2026, 1, 15, 10, 0),
        updatedAt: DateTime.utc(2026, 1, 15, 10, 0),
        latitude: 21.85,
        longitude: 84.01,
        checklist: [
          InspectionChecklistItem(
            id: 'c1',
            section: 'Safety',
            question: 'Are hard hats worn?',
            guidance: '',
            hindiQuestion: '',
            status: CheckItemStatus.pass,
          ),
        ],
      );
      final json = InspectionDto.fromDomain(report).toJson();
      expect(json['submission_id'], 'INSP-101');
      expect(json['mine_id'], 'mine_jharsuguda_01');
      expect(json['inspector_id'], 'usr_priya_02');
      expect(json['violation_found'], 'no');
      expect(json['violation_severity'], isNull);
      expect(json['violation_description'], isNull);
      expect(json['corrective_action'], isNull);
      expect(json['location'], {'latitude': 21.85, 'longitude': 84.01});
      expect(json['date_time'], '2026-01-15T10:00:00.000Z');

      // Roundtrip test
      final fromJsonDto = InspectionDto.fromJson(json);
      final domain = fromJsonDto.toDomain(mineName: 'Jharsuguda Mine (Pit-4)');
      expect(domain.clientUuid, 'INSP-101');
      expect(domain.checklist.first.question, 'Are hard hats worn?');
    });

    test('serializes violations with severity and description', () {
      final report = InspectionReport(
        clientUuid: 'INSP-102',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Mine (Pit-4)',
        userId: 'usr_priya_02',
        userName: 'Priya Mukhopadhyay',
        userDesignation: 'Statutory Mine Inspector',
        type: InspectionType.production,
        createdAt: DateTime.utc(2026, 1, 15, 11, 0),
        updatedAt: DateTime.utc(2026, 1, 15, 11, 0),
        checklist: [
          InspectionChecklistItem(
            id: 'c2',
            section: 'Cables',
            question: 'Are trailing cables undamaged?',
            guidance: '',
            hindiQuestion: '',
            status: CheckItemStatus.fail,
            severity: ViolationSeverity.critical,
            violationDescription: 'Frayed armor exposed',
            correctiveAction: 'Isolate breaker immediately',
          ),
        ],
      );
      final json = InspectionDto.fromDomain(report).toJson();
      expect(json['violation_found'], 'yes');
      expect(json['violation_severity'], 'critical');
      expect(json['violation_description'], 'Frayed armor exposed');
      expect(json['corrective_action'], 'Isolate breaker immediately');
    });
  });

  group('AttendanceDto Tests', () {
    test('preserves required nested location and null checkout', () {
      final report = AttendanceReport(
        clientUuid: 'ATT-201',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Mine (Pit-4)',
        userId: 'usr_rajesh_01',
        userName: 'Rajesh Sharma',
        shiftName: 'Morning Shift A',
        musterLocation: 'Main Incline Pit-4',
        expectedHeadcount: 45,
        actualHeadcount: 42,
        createdAt: DateTime.utc(2026, 2, 1, 6, 0),
        updatedAt: DateTime.utc(2026, 2, 1, 6, 0),
        entries: [
          WorkerAttendanceEntry(
            workerId: 'WRK-1001',
            workerName: 'Ramesh Tudu',
            category: 'contractor',
            contractorName: 'Eastern Mining Services',
            checkInTime: DateTime.utc(2026, 2, 1, 6, 15),
          ),
        ],
      );
      final dto = AttendanceDto.fromDomain(
        report,
        report.entries.first,
        contractorId: 'EMS-01',
        latitude: 21.85,
        longitude: 84.01,
      );
      final json = dto.toJson();
      expect(json['submission_id'], 'ATT-201');
      expect(json['worker_id'], 'WRK-1001');
      expect(json['contractor_id'], 'EMS-01');
      expect(json['check_in_location'], {'latitude': 21.85, 'longitude': 84.01});
      expect(json['check_out_time'], isNull);
      expect(json['check_out_location'], isNull);

      // Roundtrip
      final fromJsonDto = AttendanceDto.fromJson(json);
      final entryDomain = fromJsonDto.toEntryDomain();
      expect(entryDomain.workerName, 'Ramesh Tudu');
    });
  });

  group('IncidentDto Tests', () {
    test('normalizes booleans to yes/no and includes all contract fields', () {
      final incident = IncidentReport(
        clientUuid: 'INC-301',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Mine (Pit-4)',
        userId: 'usr_priya_02',
        userName: 'Priya Mukhopadhyay',
        userDesignation: 'Statutory Mine Inspector',
        type: IncidentType.equipmentFailure,
        severity: ViolationSeverity.major,
        peopleAffected: 1,
        affectedPersonDetails: 'Operator suffered minor sprain',
        description: 'Haul truck brake line pressure loss',
        immediateActionTaken: 'Brought to controlled stop, vehicle red-tagged',
        medicalAttentionRequired: true,
        equipmentInvolved: 'CAT 777D Haul Truck #12',
        evidence: [],
        latitude: 21.851,
        longitude: 84.012,
        notifyAuthorityImmediately: true,
        createdAt: DateTime.utc(2026, 2, 10, 14, 30),
        updatedAt: DateTime.utc(2026, 2, 10, 14, 30),
      );
      final json = IncidentDto.fromDomain(incident).toJson();
      expect(json['submission_id'], 'INC-301');
      expect(json['medical_attention_required'], 'yes');
      expect(json['notify_authority_immediately'], 'yes');
      expect(json['equipment_involved'], 'CAT 777D Haul Truck #12');
      expect(json['location'], {'latitude': 21.851, 'longitude': 84.012});

      // Roundtrip
      final fromJsonDto = IncidentDto.fromJson(json);
      final domain = fromJsonDto.toDomain();
      expect(domain.medicalAttentionRequired, isTrue);
      expect(domain.notifyAuthorityImmediately, isTrue);
      expect(domain.peopleAffected, 1);
    });
  });

  group('ObservationDto Tests', () {
    test('leaves priority_flagged_by_ai as null for backend/AI derivation', () {
      final obs = ObservationRecord(
        clientUuid: 'OBS-401',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Mine (Pit-4)',
        userId: 'usr_priya_02',
        userName: 'Priya Mukhopadhyay',
        entryType: ObservationType.grievance,
        category: ObservationCategory.safety,
        description: 'Airflow in gallery 3B feels sluggish',
        latitude: 21.85,
        longitude: 84.01,
        createdAt: DateTime.utc(2026, 2, 15, 9, 0),
        updatedAt: DateTime.utc(2026, 2, 15, 9, 0),
      );
      final json = ObservationDto.fromDomain(obs).toJson();
      expect(json['submission_id'], 'OBS-401');
      expect(json['text_content'], 'Airflow in gallery 3B feels sluggish');
      expect(json['priority_flagged_by_ai'], isNull);

      // Roundtrip
      final fromJsonDto = ObservationDto.fromJson(json);
      final domain = fromJsonDto.toDomain();
      expect(domain.description, 'Airflow in gallery 3B feels sluggish');
    });
  });

  group('DocumentDto Tests', () {
    test('serializes compliance document with remarks and expiry', () {
      final doc = ComplianceDocument(
        clientUuid: 'DOC-501',
        mineId: 'mine_jharsuguda_01',
        mineName: 'Jharsuguda Mine (Pit-4)',
        userId: 'usr_priya_02',
        userName: 'Priya Mukhopadhyay',
        category: DocumentCategory.contractorLicense,
        title: 'DGMS Form IV Contractor Clearance',
        documentNumber: 'DGMS/CZ/2026/884',
        associatedContractor: 'Eastern Mining Services',
        expiryDate: DateTime.utc(2027, 3, 31),
        remarks: 'Valid for opencast loading operations',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        files: [],
      );
      final json = DocumentDto.fromDomain(doc).toJson();
      expect(json['submission_id'], 'DOC-501');
      expect(json['category'], 'contractorLicense');
      expect(json['expiry_date'], '2027-03-31T00:00:00.000Z');
      expect(json['document_number'], 'DGMS/CZ/2026/884');

      // Roundtrip
      final fromJsonDto = DocumentDto.fromJson(json);
      final domain = fromJsonDto.toDomain();
      expect(domain.title, 'DGMS Form IV Contractor Clearance');
      expect(domain.category, DocumentCategory.contractorLicense);
    });
  });

  group('Master Data DTO Tests (Mine, Contractor, User)', () {
    test('MineDto serializes and roundtrips', () {
      final mine = MineModel(
        id: 'mine_jharsuguda_01',
        name: 'Jharsuguda Mine (Pit-4)',
        location: 'Jharsuguda, Odisha',
        state: 'Odisha',
        zones: const [],
      );
      final dto = MineDto.fromDomain(mine);
      final json = dto.toJson();
      expect(json['mine_id'], 'mine_jharsuguda_01');
      expect(json['mine_name'], 'Jharsuguda Mine (Pit-4)');

      final roundtrip = MineDto.fromJson(json).toDomain();
      expect(roundtrip.id, 'mine_jharsuguda_01');
    });

    test('ContractorDto parses supplied master json', () {
      final json = {
        'contractor_id': 'CONT-001',
        'company_name': 'Eastern Mining Services Pvt Ltd',
        'license_validity': '2027-12-31',
        'insurance_status': 'active',
        'compliance_documents': ['doc_lic_01.pdf'],
      };
      final dto = ContractorDto.fromJson(json);
      expect(dto.contractorId, 'CONT-001');
      expect(dto.companyName, 'Eastern Mining Services Pvt Ltd');
      expect(dto.toJson()['insurance_status'], 'active');
    });

    test('UserDto serializes profile and roundtrips to domain', () {
      final user = UserModel(
        id: 'usr_priya_02',
        employeeId: 'DGMS-INSP-404',
        fullName: 'Priya Mukhopadhyay',
        role: UserRole.inspector,
        designation: 'Statutory Mine Inspector',
        assignedMineId: 'mine_jharsuguda_01',
        assignedMineName: 'Jharsuguda Mine (Pit-4)',
        email: 'p.mukhopadhyay@dgms.gov.in',
        preferredLanguage: 'en',
      );
      final dto = UserDto.fromDomain(user, registeredAt: DateTime.utc(2026, 1, 1));
      final json = dto.toJson();
      expect(json['user_id'], 'usr_priya_02');
      expect(json['employee_id_or_contractor_id'], 'DGMS-INSP-404');
      expect(json['role'], 'inspector');

      final roundtrip = UserDto.fromJson(json).toDomain();
      expect(roundtrip.fullName, 'Priya Mukhopadhyay');
      expect(roundtrip.role, UserRole.inspector);
    });
  });

  group('BackendPayloadMapper Integration Tests', () {
    test('maps local inspection to exact backend payload', () {
      final inspection = InspectionReport(
        clientUuid: 'INSP-MAP-1',
        mineId: 'mine_01',
        mineName: 'Mine A',
        userId: 'U1',
        userName: 'Inspector',
        userDesignation: 'Safety Officer',
        type: InspectionType.safety,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        checklist: [],
      );
      final payload = BackendPayloadMapper.fromLocalReport(
        type: SyncRecordType.inspection,
        report: inspection.toDbMap(),
        uploadedEvidence: [],
      );
      expect(payload['submission_id'], 'INSP-MAP-1');
      expect(payload['violation_found'], 'no');
    });

    test('maps local incident to exact backend payload', () {
      final incident = IncidentReport(
        clientUuid: 'INC-MAP-1',
        mineId: 'mine_01',
        mineName: 'Mine A',
        userId: 'U1',
        userName: 'Inspector',
        userDesignation: 'Safety Officer',
        type: IncidentType.nearMiss,
        severity: ViolationSeverity.minor,
        peopleAffected: 0,
        description: 'Minor near miss',
        immediateActionTaken: 'Cautioned crew',
        medicalAttentionRequired: false,
        evidence: [],
        notifyAuthorityImmediately: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final payload = BackendPayloadMapper.fromLocalReport(
        type: SyncRecordType.incident,
        report: incident.toDbMap(),
        uploadedEvidence: [],
      );
      expect(payload['submission_id'], 'INC-MAP-1');
      expect(payload['medical_attention_required'], 'no');
    });
  });
}
