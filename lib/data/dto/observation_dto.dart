import '../../models/inspection_model.dart';
import '../../models/observation_model.dart';
import 'contract_helpers.dart';

/// Transport representation of a grievance/observation dataset row.
/// AI priority is intentionally nullable: it is assigned by the backend.
class ObservationDto {
  final String submissionId;
  final String mineId;
  final String inspectorId;
  final String inspectorName;
  final String entryType;
  final String category;
  final String textContent;
  final List<String> photosOrVideos;
  final Map<String, dynamic>? location;
  final DateTime dateTime;
  final Object? priorityFlaggedByAi;
  final String syncStatus;
  final String reviewStatus;

  const ObservationDto({
    required this.submissionId, required this.mineId, required this.inspectorId,
    required this.inspectorName, required this.entryType, required this.category,
    required this.textContent, required this.photosOrVideos, required this.location,
    required this.dateTime, required this.priorityFlaggedByAi,
    required this.syncStatus, required this.reviewStatus,
  });

  factory ObservationDto.fromJson(Map<String, dynamic> json) => ObservationDto(
    submissionId: json['submission_id'] as String,
    mineId: json['mine_id'] as String,
    inspectorId: json['inspector_id'] as String,
    inspectorName: json['inspector_name'] as String,
    entryType: json['entry_type'] as String,
    category: json['category'] as String,
    textContent: json['text_content'] as String,
    photosOrVideos: (json['photos_or_videos'] as List).cast<String>(),
    location: json['location'] == null ? null : Map<String, dynamic>.from(json['location'] as Map),
    dateTime: DateTime.parse(json['date_time'] as String),
    priorityFlaggedByAi: json['priority_flagged_by_ai'],
    syncStatus: json['sync_status'] as String,
    reviewStatus: json['review_status'] as String,
  );

  factory ObservationDto.fromDomain(ObservationRecord report) => ObservationDto(
    submissionId: report.clientUuid,
    mineId: report.mineId,
    inspectorId: report.userId,
    inspectorName: report.userName,
    entryType: report.entryType.name,
    category: report.category.name,
    textContent: report.description,
    photosOrVideos: report.evidence.map(externalEvidenceValue).whereType<String>().toList(),
    location: locationJson(report.latitude, report.longitude),
    dateTime: report.submittedAt ?? report.createdAt,
    priorityFlaggedByAi: null,
    syncStatus: backendSyncStatus(report.status),
    reviewStatus: report.status == RecordStatus.resolved
        ? 'resolved'
        : (report.status == RecordStatus.underReview ? 'under_review' : 'pending'),
  );

  ObservationRecord toDomain({String mineName = ''}) => ObservationRecord(
        clientUuid: submissionId,
        mineId: mineId,
        mineName: mineName,
        userId: inspectorId,
        userName: inspectorName,
        entryType: ObservationType.values.firstWhere(
          (t) => t.name == entryType,
          orElse: () => ObservationType.observation,
        ),
        category: ObservationCategory.values.firstWhere(
          (c) => c.name == category,
          orElse: () => ObservationCategory.other,
        ),
        description: textContent,
        evidence: [],
        latitude: (location?['latitude'] as num?)?.toDouble(),
        longitude: (location?['longitude'] as num?)?.toDouble(),
        status: reviewStatus == 'under_review'
            ? RecordStatus.underReview
            : RecordStatus.synced,
        createdAt: dateTime,
        submittedAt: dateTime,
        updatedAt: dateTime,
      );

  Map<String, dynamic> toJson() => {
    'submission_id': submissionId, 'mine_id': mineId, 'inspector_id': inspectorId,
    'inspector_name': inspectorName, 'entry_type': entryType, 'category': category,
    'text_content': textContent, 'photos_or_videos': photosOrVideos,
    'location': location, 'date_time': formatContractDateTime(dateTime),
    'priority_flagged_by_ai': priorityFlaggedByAi, 'sync_status': syncStatus,
    'review_status': reviewStatus,
  };
}
