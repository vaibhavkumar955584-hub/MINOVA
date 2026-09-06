import 'package:uuid/uuid.dart';
import '../core/database/app_database.dart';
import '../models/audit_event_model.dart';
import '../models/correction_request_model.dart';
import '../models/user_model.dart';

class CorrectionRepository {
  final AppDatabase _db;

  CorrectionRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  Future<CorrectionRequest> requestCorrection({
    required String recordClientUuid,
    required String recordType,
    required UserModel user,
    required String reason,
    required String requestedChangesJson,
  }) async {
    final id = 'CORR-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now();

    final request = CorrectionRequest(
      id: id,
      recordClientUuid: recordClientUuid,
      recordType: recordType,
      requestedByUserId: user.id,
      requestedByUserName: user.fullName,
      reason: reason,
      requestedChangesJson: requestedChangesJson,
      status: CorrectionStatus.pendingReview,
      requestedAt: now,
    );

    final db = await _db.database;
    await db.insert('correction_requests', request.toDbMap());

    // Record audit event
    final audit = AuditEvent(
      id: 'aud_${const Uuid().v4()}',
      recordClientUuid: recordClientUuid,
      eventType: 'correction_requested',
      userId: user.id,
      userRole: user.role.value,
      description: 'Correction requested ($id): $reason',
      timestamp: now,
    );
    await db.insert('audit_events', audit.toDbMap());

    return request;
  }

  Future<void> reviewCorrection({
    required String correctionId,
    required UserModel reviewer,
    required bool approve,
    required String comments,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();

    final status = approve ? CorrectionStatus.approved : CorrectionStatus.rejected;

    await db.update(
      'correction_requests',
      {
        'status': status.name,
        'reviewed_at': now.toIso8601String(),
        'reviewed_by_user_id': reviewer.id,
        'reviewer_comments': comments,
      },
      where: 'id = ?',
      whereArgs: [correctionId],
    );

    final maps = await db.query(
      'correction_requests',
      where: 'id = ?',
      whereArgs: [correctionId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final req = CorrectionRequest.fromDbMap(maps.first);
      final audit = AuditEvent(
        id: 'aud_${const Uuid().v4()}',
        recordClientUuid: req.recordClientUuid,
        eventType: approve ? 'correction_approved' : 'correction_rejected',
        userId: reviewer.id,
        userRole: reviewer.role.value,
        description: 'Correction $correctionId ${approve ? "Approved" : "Rejected"}. Comments: $comments',
        timestamp: now,
      );
      await db.insert('audit_events', audit.toDbMap());
    }
  }

  Future<List<CorrectionRequest>> getCorrectionsForRecord(String recordClientUuid) async {
    final db = await _db.database;
    final maps = await db.query(
      'correction_requests',
      where: 'record_client_uuid = ?',
      whereArgs: [recordClientUuid],
      orderBy: 'requested_at DESC',
    );
    return maps.map((e) => CorrectionRequest.fromDbMap(e)).toList();
  }

  Future<List<AuditEvent>> getAuditEventsForRecord(String recordClientUuid) async {
    final db = await _db.database;
    final maps = await db.query(
      'audit_events',
      where: 'record_client_uuid = ?',
      whereArgs: [recordClientUuid],
      orderBy: 'timestamp ASC',
    );
    return maps.map((e) => AuditEvent.fromDbMap(e)).toList();
  }
}
