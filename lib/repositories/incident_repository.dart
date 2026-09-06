import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/sync/sync_engine.dart';
import '../models/audit_event_model.dart';
import '../models/incident_model.dart';
import '../models/inspection_model.dart';
import '../models/sync_item_model.dart';
import '../models/user_model.dart';

class IncidentRepository {
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  IncidentRepository({
    AppDatabase? db,
    SyncEngine? syncEngine,
  })  : _db = db ?? AppDatabase.instance,
        _syncEngine = syncEngine ?? SyncEngine.instance;

  Future<IncidentReport> createDraft({
    String? clientUuid,
    required UserModel user,
    required IncidentType type,
    required ViolationSeverity severity,
    required String description,
    required String immediateActionTaken,
    int peopleAffected = 0,
    dynamic affectedPersonDetails,
    bool medicalAttentionRequired = false,
    String? equipmentInvolved,
    bool notifyAuthorityImmediately = true,
  }) async {
    final effectiveMineId = user.assignedMineId.isNotEmpty
        ? user.assignedMineId
        : (user.assignedMineIds.isNotEmpty ? user.assignedMineIds.first : '');
    final effectiveMineName = user.assignedMineName.isNotEmpty
        ? user.assignedMineName
        : 'Assigned Mine';

    if (effectiveMineId.trim().isEmpty) {
      throw const FormatException('Inspector must have an assigned mine before reporting.');
    }
    final effectiveClientUuid = (clientUuid != null && clientUuid.trim().isNotEmpty)
        ? clientUuid.trim()
        : 'INC-EMG-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final report = IncidentReport(
      clientUuid: effectiveClientUuid,
      mineId: effectiveMineId,
      mineName: effectiveMineName,
      userId: user.id,
      userName: user.fullName,
      userDesignation: user.designation,
      type: type,
      severity: severity,
      peopleAffected: peopleAffected,
      affectedPersonDetails: affectedPersonDetails,
      description: description,
      immediateActionTaken: immediateActionTaken,
      medicalAttentionRequired: medicalAttentionRequired,
      equipmentInvolved: equipmentInvolved,
      notifyAuthorityImmediately: notifyAuthorityImmediately,
      authorityAlertStatus: notifyAuthorityImmediately
          ? AuthorityAlertStatus.queued
          : AuthorityAlertStatus.notRequired,
      status: RecordStatus.draft,
      createdAt: now,
      updatedAt: now,
      zoneId: 'mz_seam3_gal4',
      zoneName: 'Seam 3 - Gallery 4',
      locationSource: 'manual',
    );

    final db = await _db.database;
    await db.insert(
      'incidents',
      report.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return report;
  }

  void validateBeforeSubmit(IncidentReport report) {
    if (report.mineId.trim().isEmpty) {
      throw const FormatException('Inspector must have an assigned mine before reporting.');
    }
    if (report.description.trim().isEmpty) {
      throw const FormatException('Incident description is required.');
    }
    if (report.immediateActionTaken.trim().isEmpty) {
      throw const FormatException('Immediate action taken is required.');
    }
    if (report.peopleAffected < 0) {
      throw const FormatException('Number of people affected cannot be negative.');
    }
    if (report.signatureBase64 == null || report.signatureBase64!.trim().isEmpty) {
      throw const FormatException('Please add your signature before submitting.');
    }
  }

  Future<void> submitAndLockIncident(IncidentReport report) async {
    if (report.status != RecordStatus.draft) {
      throw StateError('This incident report is already locked.');
    }
    validateBeforeSubmit(report);

    final payloadString = jsonEncode(report.toDbMap());
    final integrityHash = sha256.convert(utf8.encode(payloadString)).toString();

    final now = DateTime.now();
    report.submittedAt = now;
    report.updatedAt = now;
    report.integrityHash = integrityHash;
    report.status = RecordStatus.pendingSync;

    final db = await _db.database;
    for (final ev in report.evidence) {
      final evMap = ev.toMap();
      evMap['report_client_uuid'] = report.clientUuid;
      await db.insert(
        'evidence',
        evMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await db.update(
      'incidents',
      report.toDbMap(),
      where: 'client_uuid = ?',
      whereArgs: [report.clientUuid],
    );

    final audit = AuditEvent(
      id: 'aud_${const Uuid().v4()}',
      recordClientUuid: report.clientUuid,
      eventType: 'submitted_locked',
      userId: report.userId,
      userRole: report.userDesignation,
      description: 'Emergency Incident reported (${report.type.displayName} - ${report.severity.name.toUpperCase()}). Authority alert queued.',
      integrityHash: integrityHash,
      timestamp: now,
    );
    await db.insert('audit_events', audit.toDbMap());

    await _syncEngine.enqueue(
      clientUuid: report.clientUuid,
      recordType: SyncRecordType.incident,
      payloadJson: jsonEncode(report.toDbMap()),
    );
  }

  Future<void> autoSaveDraft(IncidentReport report) async {
    if (report.status != RecordStatus.draft) return;
    report.updatedAt = DateTime.now();
    final db = await _db.database;
    await db.insert(
      'incidents',
      report.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<IncidentReport?> getDraftByClientUuid(String clientUuid) async {
    final db = await _db.database;
    final results = await db.query(
      'incidents',
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return IncidentReport.fromDbMap(results.first);
  }

  Future<IncidentReport?> getLatestDraft({String? userId}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> results;
    if (userId != null) {
      results = await db.query(
        'incidents',
        where: 'user_id = ? AND status = ?',
        whereArgs: [userId, RecordStatus.draft.value],
        orderBy: 'updated_at DESC',
        limit: 1,
      );
    } else {
      results = await db.query(
        'incidents',
        where: 'status = ?',
        whereArgs: [RecordStatus.draft.value],
        orderBy: 'updated_at DESC',
        limit: 1,
      );
    }
    if (results.isEmpty) return null;
    return IncidentReport.fromDbMap(results.first);
  }

  Future<void> discardDraft(String clientUuid) async {
    final db = await _db.database;
    await db.delete(
      'incidents',
      where: 'client_uuid = ? AND status = ?',
      whereArgs: [clientUuid, RecordStatus.draft.value],
    );
  }

  Future<List<IncidentReport>> getAllIncidents({String? userId}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        'incidents',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('incidents', orderBy: 'created_at DESC');
    }
    return maps.map((e) => IncidentReport.fromDbMap(e)).toList();
  }
}
