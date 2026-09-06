enum SyncRecordType {
  inspection,
  incident,
  attendance,
  observation,
  document,
  correctionRequest,
}

enum SyncState {
  pending,
  inProgress,
  completed,
  failed,
}

class SyncQueueItem {
  final String id;
  final String clientUuid;
  final SyncRecordType recordType;
  final String payloadJson;
  int retryCount;
  final int maxRetries;
  SyncState state;
  final DateTime queuedAt;
  DateTime? lastAttemptAt;
  DateTime? nextRetryAt;
  String? errorMessage;
  String? errorStage;
  String? errorCode;
  bool isRetryable;

  SyncQueueItem({
    required this.id,
    required this.clientUuid,
    required this.recordType,
    required this.payloadJson,
    this.retryCount = 0,
    this.maxRetries = 5,
    this.state = SyncState.pending,
    required this.queuedAt,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.errorMessage,
    this.errorStage,
    this.errorCode,
    this.isRetryable = true,
  });

  String get submissionId => clientUuid;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_uuid': clientUuid,
      'record_type': recordType.name,
      'payload_json': payloadJson,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'state': state.name,
      'queued_at': queuedAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'error_message': errorMessage,
      'error_stage': errorStage,
      'error_code': errorCode,
      'is_retryable': isRetryable ? 1 : 0,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      clientUuid: map['client_uuid'] as String,
      recordType: SyncRecordType.values.firstWhere(
        (e) => e.name == map['record_type'],
        orElse: () => SyncRecordType.inspection,
      ),
      payloadJson: map['payload_json'] as String,
      retryCount: (map['retry_count'] as int?) ?? 0,
      maxRetries: (map['max_retries'] as int?) ?? 5,
      state: SyncState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => SyncState.pending,
      ),
      queuedAt: DateTime.parse(map['queued_at'] as String),
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.tryParse(map['last_attempt_at'] as String)
          : null,
      nextRetryAt: map['next_retry_at'] != null
          ? DateTime.tryParse(map['next_retry_at'] as String)
          : null,
      errorMessage: map['error_message'] as String?,
      errorStage: map['error_stage'] as String?,
      errorCode: map['error_code'] as String?,
      isRetryable: (map['is_retryable'] as int?) != 0,
    );
  }

  SyncQueueItem copyWith({
    String? id,
    String? clientUuid,
    SyncRecordType? recordType,
    String? payloadJson,
    int? retryCount,
    int? maxRetries,
    SyncState? state,
    DateTime? queuedAt,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? errorMessage,
    String? errorStage,
    String? errorCode,
    bool? isRetryable,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      recordType: recordType ?? this.recordType,
      payloadJson: payloadJson ?? this.payloadJson,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      state: state ?? this.state,
      queuedAt: queuedAt ?? this.queuedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      errorMessage: errorMessage ?? this.errorMessage,
      errorStage: errorStage ?? this.errorStage,
      errorCode: errorCode ?? this.errorCode,
      isRetryable: isRetryable ?? this.isRetryable,
    );
  }
}
