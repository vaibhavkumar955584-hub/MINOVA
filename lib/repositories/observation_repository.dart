import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/sync/sync_engine.dart';
import '../models/audit_event_model.dart';
import '../models/evidence_model.dart';
import '../models/inspection_model.dart';
import '../models/observation_model.dart';
import '../models/sync_item_model.dart';
import '../models/user_model.dart';

class ObservationRepository {
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  ObservationRepository({
    AppDatabase? db,
    SyncEngine? syncEngine,
  })  : _db = db ?? AppDatabase.instance,
        _syncEngine = syncEngine ?? SyncEngine.instance;

  Future<ObservationRecord> createDraft({
    required UserModel user,
    required ObservationType entryType,
    required ObservationCategory category,
    required String description,
    String? voiceTranscription,
    double? ch4Percent,
    int? coPpm,
    double? o2Percent,
    List<EvidenceItem>? evidence,
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
    final clientUuid = 'OBS-LOG-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final report = ObservationRecord(
      clientUuid: clientUuid,
      mineId: effectiveMineId,
      mineName: effectiveMineName,
      userId: user.id,
      userName: user.fullName,
      entryType: entryType,
      category: category,
      description: description,
      voiceTranscription: voiceTranscription,
      ch4Percent: ch4Percent,
      coPpm: coPpm,
      o2Percent: o2Percent,
      status: RecordStatus.draft,
      createdAt: now,
      updatedAt: now,
      zoneId: 'mz_vent_gal1',
      zoneName: 'Ventilation Gallery 1',
      locationSource: 'manual',
      evidence: evidence ?? [],
    );

    final db = await _db.database;
    await db.insert(
      'observations',
      report.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return report;
  }

  Future<void> submitAndLockObservation(ObservationRecord report) async {
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
      'observations',
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
      description: 'Field Observation logged (${report.category.displayName})',
      integrityHash: integrityHash,
      timestamp: now,
    );
    await db.insert('audit_events', audit.toDbMap());

    await _syncEngine.enqueue(
      clientUuid: report.clientUuid,
      recordType: SyncRecordType.observation,
      payloadJson: jsonEncode(report.toDbMap()),
    );
  }

  Future<List<ObservationRecord>> getAllObservations({String? userId}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        'observations',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('observations', orderBy: 'created_at DESC');
    }
    return maps.map((e) => ObservationRecord.fromDbMap(e)).toList();
  }
}
