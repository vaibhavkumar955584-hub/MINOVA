import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/auth/role_permissions.dart';
import 'package:minesafe/core/shortcuts/launcher_shortcut_service.dart';
import 'package:minesafe/models/emergency_notification_model.dart';
import 'package:minesafe/models/incident_model.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/specialist_category.dart';
import 'package:minesafe/models/user_model.dart';
import 'package:minesafe/data/dto/incident_dto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Employee / Field Responder Role Model & Permissions', () {
    final employeeUser = UserModel(
      id: 'usr_emp_ramesh_123',
      employeeId: 'EMP-9042',
      fullName: 'Ramesh Verma',
      role: UserRole.employee,
      designation: 'Mechanical Specialist',
      assignedMineId: 'JH-DHA-BCCL-007',
      assignedMineName: 'BCCL Pit-7 (Dhanbad)',
      assignedMineIds: ['JH-DHA-BCCL-007'],
      preferredLanguage: 'hi',
      accountStatus: 'active',
    );

    final inspectorUser = UserModel(
      id: 'usr_insp_priya_456',
      employeeId: 'DGMS-INSP-404',
      fullName: 'Priya Mukhopadhyay',
      role: UserRole.inspector,
      designation: 'Statutory Mine Inspector',
      assignedMineId: 'JH-DHA-BCCL-007',
      assignedMineName: 'BCCL Pit-7 (Dhanbad)',
      assignedMineIds: ['JH-DHA-BCCL-007'],
      preferredLanguage: 'en',
      accountStatus: 'active',
      managerId: 'MGR-001',
    );

    test('UserRoleExtension correctly serializes and deserializes employee role', () {
      expect(UserRole.employee.value, 'employee');
      expect(UserRole.employee.displayName, 'Field Responder');
      expect(UserRoleExtension.fromString('employee'), UserRole.employee);
      expect(UserRoleExtension.fromString('field_responder'), UserRole.employee);
      expect(UserRoleExtension.fromString('worker'), UserRole.employee);
      expect(UserRoleExtension.fromString('inspector'), UserRole.inspector);
    });

    test('Employee has strict restricted permissions (Incident ONLY)', () {
      final permissions = RolePermissions.forUser(employeeUser);

      expect(permissions.canReportIncident, isTrue,
          reason: 'Employee must be allowed to report incidents');
      expect(permissions.canPerformInspection, isFalse,
          reason: 'Employee must NOT perform statutory inspections');
      expect(permissions.canManageAttendance, isFalse,
          reason: 'Employee must NOT manage muster/attendance');
      expect(permissions.canSubmitObservation, isFalse,
          reason: 'Employee must NOT submit gas observations');
      expect(permissions.canUploadDocument, isFalse,
          reason: 'Employee must NOT upload vault documents');
      expect(permissions.canDirectlyApproveCorrections, isFalse);
      expect(permissions.canRequestCorrection, isFalse);
    });

    test('Inspector maintains full statutory permissions (Regression Test)', () {
      final permissions = RolePermissions.forUser(inspectorUser);

      expect(permissions.canPerformInspection, isTrue);
      expect(permissions.canReportIncident, isTrue);
      expect(permissions.canSubmitObservation, isTrue);
      expect(permissions.canUploadDocument, isTrue);
      expect(permissions.canRequestCorrection, isTrue);
    });
  });

  group('Specialist Category & Emergency Notification Model', () {
    test('SpecialistCategory key and bilingual mapping', () {
      expect(SpecialistCategory.fromKey('mechanical'), SpecialistCategory.mechanical);
      expect(SpecialistCategory.fromKey('electrical'), SpecialistCategory.electrical);
      expect(SpecialistCategory.fromKey('ventilation'), SpecialistCategory.ventilation);
      expect(SpecialistCategory.fromKey('fire_safety'), SpecialistCategory.fireSafety);
      expect(SpecialistCategory.fromKey('rescue'), SpecialistCategory.rescue);
      expect(SpecialistCategory.fromKey('medical'), SpecialistCategory.medical);
      expect(SpecialistCategory.fromKey('unknown_xyz'), SpecialistCategory.general);

      expect(SpecialistCategory.mechanical.displayName, 'Mechanical Specialist');
      expect(SpecialistCategory.mechanical.hindiName, 'मैकेनिकल विशेषज्ञ');
    });

    test('EmergencyNotificationModel serialization and deserialization', () {
      final now = DateTime.now();
      final notification = EmergencyNotificationModel(
        id: 'EMG-TEST-100',
        incidentType: IncidentType.fire,
        severity: ViolationSeverity.critical,
        title: '🚨 Fire in Workshop Panel 4',
        description: 'Smoke detected near electrical panel.',
        mineId: 'JH-DHA-BCCL-007',
        locationDisplay: 'Underground Workshop — Panel 4',
        latitude: 23.7957,
        longitude: 86.4304,
        createdAt: now,
        targetSpecialist: 'mechanical',
        instructions: 'Isolate power and deploy Class B extinguisher.',
        isRead: false,
      );

      final map = notification.toMap();
      expect(map['id'], 'EMG-TEST-100');
      expect(map['incident_type'], 'fire');
      expect(map['severity'], 'critical');
      expect(map['is_read'], 0);

      final restored = EmergencyNotificationModel.fromMap(map);
      expect(restored.id, notification.id);
      expect(restored.incidentType, IncidentType.fire);
      expect(restored.severity, ViolationSeverity.critical);
      expect(restored.targetSpecialist, 'mechanical');
      expect(restored.latitude, 23.7957);
      expect(restored.isRead, isFalse);

      final readCopy = restored.copyWith(isRead: true);
      expect(readCopy.isRead, isTrue);
    });
  });

  group('Employee Incident Reporting with Existing Schema (No Schema Changes)', () {
    test('IncidentReport maps employee userId & userName seamlessly to IncidentDto inspector fields', () {
      final now = DateTime.now();
      final employeeReport = IncidentReport(
        clientUuid: 'INC-EMP-TEST-001',
        mineId: 'JH-DHA-BCCL-007',
        mineName: 'BCCL Pit-7 (Dhanbad)',
        userId: 'usr_emp_ramesh_123',
        userName: 'Ramesh Verma',
        userDesignation: 'Mechanical Specialist',
        type: IncidentType.fire,
        severity: ViolationSeverity.critical,
        peopleAffected: 0,
        affectedPersonDetails: [],
        description: 'Underground switchgear panel smoke detected.',
        immediateActionTaken: 'Power isolated; foam extinguisher deployed.',
        medicalAttentionRequired: false,
        notifyAuthorityImmediately: true,
        createdAt: now,
        updatedAt: now,
        latitude: 23.7957,
        longitude: 86.4304,
        locationSource: 'gps',
        status: RecordStatus.draft,
      );

      // Verify DB Serialization uses standard SQLite table format
      final dbMap = employeeReport.toDbMap();
      expect(dbMap['client_uuid'], 'INC-EMP-TEST-001');
      expect(dbMap['user_id'], 'usr_emp_ramesh_123');
      expect(dbMap['user_name'], 'Ramesh Verma');
      expect(dbMap['type'], 'fire');
      expect(dbMap['severity'], 'critical');

      // Verify DTO Serialization maps to existing backend contract without schema changes
      final dto = IncidentDto.fromDomain(employeeReport);
      expect(dto.submissionId, 'INC-EMP-TEST-001');
      expect(dto.mineId, 'JH-DHA-BCCL-007');
      expect(dto.inspectorId, 'usr_emp_ramesh_123');
      expect(dto.inspectorName, 'Ramesh Verma');
      expect(dto.incidentType, 'fire');
      expect(dto.severity, 'critical');

      final json = dto.toJson();
      expect(json['submission_id'], 'INC-EMP-TEST-001');
      expect(json['inspector_id'], 'usr_emp_ramesh_123');
      expect(json['inspector_name'], 'Ramesh Verma');
      expect(json['incident_type'], 'fire');
    });
  });

  group('Launcher Shortcut Role Protection', () {
    test('Launcher shortcut mapping for emergencyIncident and attendance', () {
      expect(LauncherShortcut.fromString('emergency_incident'), LauncherShortcut.emergencyIncident);
      expect(LauncherShortcut.fromString('incident'), LauncherShortcut.emergencyIncident);
      expect(LauncherShortcut.fromString('attendance'), LauncherShortcut.attendance);
      expect(LauncherShortcut.fromString('unknown'), isNull);
    });
  });
}
