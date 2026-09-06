class AuditEvent {
  final String id;
  final String recordClientUuid;
  final String eventType; // 'created' | 'auto_saved' | 'signed' | 'submitted_locked' | 'sync_attempted' | 'synced' | 'correction_requested' | 'correction_approved' | 'correction_rejected'
  final String userId;
  final String userRole;
  final String description;
  final String? previousStateJson;
  final String? newStateJson;
  final String? integrityHash;
  final DateTime timestamp;

  AuditEvent({
    required this.id,
    required this.recordClientUuid,
    required this.eventType,
    required this.userId,
    required this.userRole,
    required this.description,
    this.previousStateJson,
    this.newStateJson,
    this.integrityHash,
    required this.timestamp,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'record_client_uuid': recordClientUuid,
      'event_type': eventType,
      'user_id': userId,
      'user_role': userRole,
      'description': description,
      'previous_state_json': previousStateJson,
      'new_state_json': newStateJson,
      'integrity_hash': integrityHash,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditEvent.fromDbMap(Map<String, dynamic> map) {
    return AuditEvent(
      id: map['id'] as String,
      recordClientUuid: map['record_client_uuid'] as String,
      eventType: map['event_type'] as String,
      userId: map['user_id'] as String,
      userRole: map['user_role'] as String,
      description: map['description'] as String,
      previousStateJson: map['previous_state_json'] as String?,
      newStateJson: map['new_state_json'] as String?,
      integrityHash: map['integrity_hash'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
