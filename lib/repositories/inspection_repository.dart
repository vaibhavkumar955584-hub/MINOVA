import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/sync/sync_engine.dart';
import '../models/audit_event_model.dart';
import '../models/inspection_model.dart';
import '../models/sync_item_model.dart';
import '../models/user_model.dart';

class InspectionRepository {
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  InspectionRepository({AppDatabase? db, SyncEngine? syncEngine})
    : _db = db ?? AppDatabase.instance,
      _syncEngine = syncEngine ?? SyncEngine.instance;

  Future<InspectionReport> createDraft({
    required UserModel user,
    required InspectionType type,
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
    final clientUuid =
        'SAF-INSP-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final report = InspectionReport(
      clientUuid: clientUuid,
      mineId: effectiveMineId,
      mineName: effectiveMineName,
      userId: user.id,
      userName: user.fullName,
      userDesignation: user.designation,
      type: type,
      status: RecordStatus.draft,
      createdAt: now,
      updatedAt: now,
      version: 1,
      locationSource: 'manual',
      zoneId: 'mz_seam3_gal4',
      zoneName: 'Seam 3 - Gallery 4',
      checklist: InspectionReport.getDefaultChecklist(type),
    );

    final db = await _db.database;
    await db.insert(
      'inspections',
      report.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Audit Event
    final audit = AuditEvent(
      id: 'aud_${const Uuid().v4()}',
      recordClientUuid: clientUuid,
      eventType: 'created',
      userId: user.id,
      userRole: user.role.value,
      description: 'Initialized inspection draft with client UUID $clientUuid',
      timestamp: now,
    );
    await db.insert('audit_events', audit.toDbMap());

    return report;
  }

  Future<void> autoSaveDraft(InspectionReport report) async {
    if (report.status != RecordStatus.draft) return;
    report.updatedAt = DateTime.now();
    final db = await _db.database;
    await db.update(
      'inspections',
      report.toDbMap(),
      where: 'client_uuid = ?',
      whereArgs: [report.clientUuid],
    );
  }

  Future<void> discardDraft(String clientUuid) async {
    final db = await _db.database;
    await db.delete(
      'inspections',
      where: 'client_uuid = ? AND status = ?',
      whereArgs: [clientUuid, RecordStatus.draft.value],
    );
  }

  Future<InspectionReport?> getReportByUuid(String clientUuid) async {
    final db = await _db.database;
    final results = await db.query(
      'inspections',
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return InspectionReport.fromDbMap(results.first);
  }

  Future<List<InspectionReport>> getAllReports({
    RecordStatus? statusFilter,
    String? userId,
  }) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps;
    if (statusFilter != null && userId != null) {
      maps = await db.query(
        'inspections',
        where: 'status = ? AND user_id = ?',
        whereArgs: [statusFilter.value, userId],
        orderBy: 'created_at DESC',
      );
    } else if (userId != null) {
      maps = await db.query(
        'inspections',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else if (statusFilter != null) {
      maps = await db.query(
        'inspections',
        where: 'status = ?',
        whereArgs: [statusFilter.value],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('inspections', orderBy: 'created_at DESC');
    }
    return maps.map((e) => InspectionReport.fromDbMap(e)).toList();
  }

  void validateBeforeSubmit(InspectionReport report) {
    _validateForSubmission(report);
  }

  Future<void> submitAndLockReport(InspectionReport report) async {
    if (report.status != RecordStatus.draft) {
      throw StateError('This inspection is already locked.');
    }
    validateBeforeSubmit(report);
    // 1. Calculate integrity hash of full record payload
    final payloadString = jsonEncode(report.toDbMap());
    final integrityHash = sha256.convert(utf8.encode(payloadString)).toString();

    final now = DateTime.now();
    report.submittedAt = now;
    report.updatedAt = now;
    report.integrityHash = integrityHash;
    report.status = RecordStatus.pendingSync;

    final db = await _db.database;

    // 2. Persist all global and checklist evidence items into SQLite evidence table
    for (final ev in report.globalEvidence) {
      final evMap = ev.toMap();
      evMap['report_client_uuid'] = report.clientUuid;
      await db.insert(
        'evidence',
        evMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (final checkItem in report.checklist) {
      for (final ev in checkItem.evidence) {
        final evMap = ev.toMap();
        evMap['report_client_uuid'] = report.clientUuid;
        await db.insert(
          'evidence',
          evMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    // 3. Persist locked inspection record state locally
    await db.update(
      'inspections',
      report.toDbMap(),
      where: 'client_uuid = ?',
      whereArgs: [report.clientUuid],
    );

    // 4. Record tamper-evident statutory audit event
    final audit = AuditEvent(
      id: 'aud_${const Uuid().v4()}',
      recordClientUuid: report.clientUuid,
      eventType: 'submitted_locked',
      userId: report.userId,
      userRole: report.userDesignation,
      description: 'Statutory Safety Audit submitted and cryptographically sealed with SHA-256.',
      integrityHash: integrityHash,
      timestamp: now,
    );
    await db.insert('audit_events', audit.toDbMap());

    // 5. Enqueue in reliable offline sync engine
    await _syncEngine.enqueue(
      clientUuid: report.clientUuid,
      recordType: SyncRecordType.inspection,
      payloadJson: jsonEncode(report.toDbMap()),
    );
  }

  void _validateForSubmission(InspectionReport report) {
    if (report.clientUuid.trim().isEmpty) {
      throw const FormatException('Missing required submission identity.');
    }
    if (report.mineId.trim().isEmpty) {
      throw const FormatException('Missing required mine identifier.');
    }
    if (report.userId.trim().isEmpty) {
      throw const FormatException('Missing required inspector identifier.');
    }
    if (report.checklist.isEmpty ||
        report.checklist.any(
          (item) => item.status == CheckItemStatus.unanswered,
        )) {
      throw const FormatException(
        'Complete every checklist item before submitting.',
      );
    }
    if (report.signatureBase64 == null || report.signatureBase64!.trim().isEmpty) {
      throw const FormatException('Please add your signature before submitting.');
    }
    if (report.locationSource == 'manual' &&
        (report.zoneId == null || report.zoneName == null)) {
      throw const FormatException('Select a mine zone before submitting.');
    }
  }
}
