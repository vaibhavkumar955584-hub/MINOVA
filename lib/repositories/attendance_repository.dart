import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../core/sync/sync_engine.dart';
import '../models/attendance_model.dart';
import '../models/audit_event_model.dart';
import '../models/inspection_model.dart';
import '../models/sync_item_model.dart';
import '../models/user_model.dart';

class AttendanceRepository {
  final AppDatabase _db;
  final SyncEngine _syncEngine;

  AttendanceRepository({
    AppDatabase? db,
    SyncEngine? syncEngine,
  })  : _db = db ?? AppDatabase.instance,
        _syncEngine = syncEngine ?? SyncEngine.instance;

  Future<AttendanceReport> createDraft({
    required UserModel user,
    required String shiftName,
    required String musterLocation,
    required int expectedHeadcount,
    required int actualHeadcount,
    required List<WorkerAttendanceEntry> entries,
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
    final clientUuid = 'ATT-MST-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final report = AttendanceReport(
      clientUuid: clientUuid,
      mineId: effectiveMineId,
      mineName: effectiveMineName,
      userId: user.id,
      userName: user.fullName,
      shiftName: shiftName,
      musterLocation: musterLocation,
      expectedHeadcount: expectedHeadcount,
      actualHeadcount: actualHeadcount,
      entries: entries,
      status: RecordStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    final db = await _db.database;
    await db.insert(
      'attendances',
      report.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return report;
  }

  Future<void> submitAndLockAttendance(AttendanceReport report) async {
    final payloadString = jsonEncode(report.toDbMap());
    final integrityHash = sha256.convert(utf8.encode(payloadString)).toString();

    final now = DateTime.now();
    report.submittedAt = now;
    report.updatedAt = now;
    report.integrityHash = integrityHash;
    report.status = RecordStatus.pendingSync;

    final db = await _db.database;
    await db.update(
      'attendances',
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
      description: 'Muster roll submitted with headcount: ${report.actualHeadcount}/${report.expectedHeadcount}',
      integrityHash: integrityHash,
      timestamp: now,
    );
    await db.insert('audit_events', audit.toDbMap());

    await _syncEngine.enqueue(
      clientUuid: report.clientUuid,
      recordType: SyncRecordType.attendance,
      payloadJson: jsonEncode(report.toDbMap()),
    );
  }

  Future<List<AttendanceReport>> getAllAttendances({String? userId}) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps;
    if (userId != null) {
      maps = await db.query(
        'attendances',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query('attendances', orderBy: 'created_at DESC');
    }
    return maps.map((e) => AttendanceReport.fromDbMap(e)).toList();
  }
}
