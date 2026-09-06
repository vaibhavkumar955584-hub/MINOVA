import '../../models/incident_model.dart';
import '../../models/inspection_model.dart';
import 'contract_helpers.dart';

class IncidentDto {
  final String submissionId;
  final String mineId;
  final String inspectorId;
  final String inspectorName;
  final String incidentType;
  final String severity;
  final int peopleAffected;
  final List<String> affectedPersonDetails;
  final String description;
  final String immediateActionTaken;
  final String medicalAttentionRequired;
  final String? equipmentInvolved;
  final List<String> photosOrVideos;
  final Map<String, dynamic>? location;
  final DateTime dateTime;
  final String notifyAuthorityImmediately;
  final String syncStatus;
  final String reviewStatus;
  final String badgeLabel;
  final String locationDisplay;
  final String syncSource;

  const IncidentDto({
    required this.submissionId,
    required this.mineId,
    required this.inspectorId,
    required this.inspectorName,
    required this.incidentType,
    required this.severity,
    required this.peopleAffected,
    required this.affectedPersonDetails,
    required this.description,
    required this.immediateActionTaken,
    required this.medicalAttentionRequired,
    required this.equipmentInvolved,
    required this.photosOrVideos,
    required this.location,
    required this.dateTime,
    required this.notifyAuthorityImmediately,
    required this.syncStatus,
    required this.reviewStatus,
    this.badgeLabel = 'CRITICAL HAZARD',
    this.locationDisplay = '',
    this.syncSource = 'Synced via Handheld',
  });

  factory IncidentDto.fromJson(Map<String, dynamic> json) {
    List<String> parseDetails(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      final str = val.toString().trim();
      if (str.isEmpty) return [];
      return str
          .split(RegExp(r'[,;\n]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final severityStr = (json['severity'] ?? 'minor').toString();
    final badgeDefault = severityStr == 'critical'
        ? 'CRITICAL HAZARD'
        : (severityStr == 'major' ? 'MAJOR HAZARD' : 'SAFETY INCIDENT');

    return IncidentDto(
      submissionId: json['submission_id'] as String,
      mineId: json['mine_id'] as String,
      inspectorId: json['inspector_id'] as String,
      inspectorName: json['inspector_name'] as String,
      incidentType: json['incident_type'] as String,
      severity: severityStr,
      peopleAffected: (json['people_affected'] as num?)?.toInt() ?? 0,
      affectedPersonDetails: parseDetails(json['affected_person_details']),
      description: (json['description'] ?? '') as String,
      immediateActionTaken: (json['immediate_action_taken'] ?? '') as String,
      medicalAttentionRequired:
          (json['medical_attention_required'] ?? 'no').toString(),
      equipmentInvolved: json['equipment_involved'] as String?,
      photosOrVideos:
          (json['photos_or_videos'] as List?)?.cast<String>() ?? [],
      location: json['location'] == null
          ? null
          : Map<String, dynamic>.from(json['location'] as Map),
      dateTime: DateTime.parse(json['date_time'] as String),
      notifyAuthorityImmediately:
          (json['notify_authority_immediately'] ?? 'no').toString(),
      syncStatus: (json['sync_status'] ?? 'synced').toString(),
      reviewStatus: (json['review_status'] ?? 'under_investigation').toString(),
      badgeLabel: (json['badge_label'] ?? badgeDefault) as String,
      locationDisplay: (json['location_display'] ?? '') as String,
      syncSource: (json['sync_source'] ?? 'Synced via Handheld') as String,
    );
  }

  factory IncidentDto.fromDomain(IncidentReport report) {
    final badge = report.severity == ViolationSeverity.critical
        ? 'CRITICAL HAZARD'
        : (report.severity == ViolationSeverity.major
            ? 'MAJOR HAZARD'
            : 'SAFETY INCIDENT');

    final locDisplay = report.zoneName != null && report.zoneName!.isNotEmpty
        ? '${report.mineName} • ${report.zoneName}'
        : (report.mineName.isNotEmpty ? report.mineName : 'Mining Sector');

    final revStatus = report.status == RecordStatus.underReview
        ? 'under_investigation'
        : (report.status == RecordStatus.draft ? 'pending' : 'under_investigation');

    return IncidentDto(
      submissionId: report.clientUuid,
      mineId: report.mineId,
      inspectorId: report.userId,
      inspectorName: report.userName,
      incidentType: report.type.value,
      severity: report.severity.name,
      peopleAffected: report.peopleAffected,
      affectedPersonDetails: report.affectedPersonDetails,
      description: report.description,
      immediateActionTaken: report.immediateActionTaken,
      medicalAttentionRequired:
          report.medicalAttentionRequired ? 'yes' : 'no',
      equipmentInvolved: report.equipmentInvolved,
      photosOrVideos: report.evidence
          .map(externalEvidenceValue)
          .whereType<String>()
          .toList(),
      location: locationJson(report.latitude, report.longitude),
      dateTime: report.submittedAt ?? report.createdAt,
      notifyAuthorityImmediately:
          report.notifyAuthorityImmediately ? 'yes' : 'no',
      syncStatus: backendSyncStatus(report.status),
      reviewStatus: revStatus,
      badgeLabel: badge,
      locationDisplay: locDisplay,
      syncSource: 'Synced via Handheld',
    );
  }

  IncidentReport toDomain({
    String mineName = '',
    String userDesignation = '',
  }) =>
      IncidentReport(
        clientUuid: submissionId,
        mineId: mineId,
        mineName: mineName.isNotEmpty ? mineName : locationDisplay,
        userId: inspectorId,
        userName: inspectorName,
        userDesignation: userDesignation,
        type: IncidentType.values.firstWhere(
          (t) => t.value == incidentType,
          orElse: () => IncidentType.nearMiss,
        ),
        severity: ViolationSeverity.values.firstWhere(
          (s) => s.name == severity,
          orElse: () => ViolationSeverity.minor,
        ),
        peopleAffected: peopleAffected,
        affectedPersonDetails: affectedPersonDetails,
        description: description,
        immediateActionTaken: immediateActionTaken,
        medicalAttentionRequired: medicalAttentionRequired == 'yes',
        equipmentInvolved: equipmentInvolved,
        evidence: [],
        latitude: (location?['latitude'] as num?)?.toDouble(),
        longitude: (location?['longitude'] as num?)?.toDouble(),
        notifyAuthorityImmediately: notifyAuthorityImmediately == 'yes',
        status: (reviewStatus == 'under_review' ||
                reviewStatus == 'under_investigation')
            ? RecordStatus.underReview
            : RecordStatus.synced,
        createdAt: dateTime,
        submittedAt: dateTime,
        updatedAt: dateTime,
      );

  Map<String, dynamic> toJson() => {
        'submission_id': submissionId,
        'mine_id': mineId,
        'inspector_id': inspectorId,
        'inspector_name': inspectorName,
        'incident_type': incidentType,
        'severity': severity,
        'people_affected': peopleAffected,
        'affected_person_details': affectedPersonDetails,
        'description': description,
        'immediate_action_taken': immediateActionTaken,
        'medical_attention_required': medicalAttentionRequired,
        'equipment_involved': equipmentInvolved,
        'photos_or_videos': photosOrVideos,
        'location': location,
        'date_time': formatContractDateTime(dateTime),
        'notify_authority_immediately': notifyAuthorityImmediately,
        'sync_status': syncStatus,
        'review_status': reviewStatus,
        'badge_label': badgeLabel,
        'location_display': locationDisplay,
        'sync_source': syncSource,
      };
}
