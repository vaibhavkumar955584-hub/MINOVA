enum CorrectionStatus {
  pendingReview,
  approved,
  rejected,
}

class CorrectionRequest {
  final String id;
  final String recordClientUuid;
  final String recordType; // 'inspection' | 'incident' | 'attendance' | 'observation' | 'document'
  final String requestedByUserId;
  final String requestedByUserName;
  final String reason;
  final String requestedChangesJson;
  CorrectionStatus status;
  final DateTime requestedAt;
  DateTime? reviewedAt;
  String? reviewedByUserId;
  String? reviewerComments;

  CorrectionRequest({
    required this.id,
    required this.recordClientUuid,
    required this.recordType,
    required this.requestedByUserId,
    required this.requestedByUserName,
    required this.reason,
    required this.requestedChangesJson,
    this.status = CorrectionStatus.pendingReview,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedByUserId,
    this.reviewerComments,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'record_client_uuid': recordClientUuid,
      'record_type': recordType,
      'requested_by_user_id': requestedByUserId,
      'requested_by_user_name': requestedByUserName,
      'reason': reason,
      'requested_changes_json': requestedChangesJson,
      'status': status.name,
      'requested_at': requestedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by_user_id': reviewedByUserId,
      'reviewer_comments': reviewerComments,
    };
  }

  factory CorrectionRequest.fromDbMap(Map<String, dynamic> map) {
    return CorrectionRequest(
      id: map['id'] as String,
      recordClientUuid: map['record_client_uuid'] as String,
      recordType: map['record_type'] as String,
      requestedByUserId: map['requested_by_user_id'] as String,
      requestedByUserName: map['requested_by_user_name'] as String,
      reason: map['reason'] as String,
      requestedChangesJson: map['requested_changes_json'] as String,
      status: CorrectionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CorrectionStatus.pendingReview,
      ),
      requestedAt: DateTime.parse(map['requested_at'] as String),
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.tryParse(map['reviewed_at'] as String)
          : null,
      reviewedByUserId: map['reviewed_by_user_id'] as String?,
      reviewerComments: map['reviewer_comments'] as String?,
    );
  }
}
