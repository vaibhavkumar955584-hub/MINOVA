import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/sync/sync_engine.dart';
import '../models/audit_event_model.dart';
import '../models/document_model.dart';
import '../models/evidence_model.dart';
import '../models/inspection_model.dart';
import '../models/sync_item_model.dart';
import '../models/user_model.dart';

class DocumentRepository {
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  DocumentRepository({
    AppDatabase? db,
    SyncEngine? syncEngine,
  })  : _db = db ?? AppDatabase.instance,
        _syncEngine = syncEngine ?? SyncEngine.instance;

  Future<ComplianceDocument> createDraft({
    required UserModel user,
    required DocumentCategory category,
    required String title,
    String? documentNumber,
    String? associatedContractor,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? remarks,
    required List<EvidenceItem> files,
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
    final clientUuid = 'DOC-CMP-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final report = ComplianceDocument(
      clientUuid: clientUuid,
      mineId: effectiveMineId,
      mineName: effectiveMineName,
      userId: user.id,
      userName: user.fullName,
      category: category,
      title: title,
      documentNumber: documentNumber,
      associatedContractor: associatedContractor,
      issueDate: issueDate,
      expiryDate: expiryDate,
      remarks: remarks,
      status: RecordStatus.draft,
      createdAt: now,
      updatedAt: now,
      files: files,
    );

    final db = await _db.database;
    await db.insert(
      'documents',
      report.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return report;
  }

  Future<void> submitAndLockDocument(ComplianceDocument report) async {
    final payloadString = jsonEncode(report.toDbMap());
    final integrityHash = sha256.convert(utf8.encode(payloadString)).toString();

    final now = DateTime.now();
    report.submittedAt = now;
    report.updatedAt = now;
    report.integrityHash = integrityHash;
    report.status = RecordStatus.pendingSync;

    final db = await _db.database;
    for (final ev in report.files) {
      final evMap = ev.toMap();
      evMap['report_client_uuid'] = report.clientUuid;
      await db.insert(
        'evidence',
        evMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await db.update(
      'documents',
      report.toDbMap(),
      where: 'client_uuid = ?',
      whereArgs: [report.clientUuid],
    );

    final audit = AuditEvent(
      id: 'aud_${const Uuid().v4()}',
      recordClientUuid: report.clientUuid,
      eventType: 'submitted_locked',
      userId: report.userId,
      userRole: report.userName,
      description: 'Statutory compliance document uploaded (${report.title})',
      integrityHash: integrityHash,
      timestamp: now,
    );
    await db.insert('audit_events', audit.toDbMap());

    await _syncEngine.enqueue(
      clientUuid: report.clientUuid,
      recordType: SyncRecordType.document,
      payloadJson: jsonEncode(report.toDbMap()),
    );
  }

  Future<List<ComplianceDocument>> getAllDocuments({String? userId}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        'documents',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('documents', orderBy: 'created_at DESC');
    }
    return maps.map((e) => ComplianceDocument.fromDbMap(e)).toList();
  }
}
