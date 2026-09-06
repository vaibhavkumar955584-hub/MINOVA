import '../../models/inspection_model.dart';
import 'contract_helpers.dart';

/// Adapter for the supplied inspection contract. Checklist field details need
/// the missing inspections.json fixture before they can be declared exact.
class InspectionDto {
  final String submissionId;
  final String mineId;
  final String inspectorId;
  final String inspectorName;
  final String inspectionType;
  final List<Map<String, dynamic>> checklist;
  final String violationFound;
  final String? violationSeverity;
  final String? violationDescription;
  final String? correctiveAction;
  final List<String> photosOrVideos;
  final Map<String, dynamic>? location;
  final DateTime dateTime;
  final String syncStatus;
  final String reviewStatus;

  const InspectionDto({
    required this.submissionId,
    required this.mineId,
    required this.inspectorId,
    required this.inspectorName,
    required this.inspectionType,
    required this.checklist,
    required this.violationFound,
    required this.violationSeverity,
    required this.violationDescription,
    required this.correctiveAction,
    required this.photosOrVideos,
    required this.location,
    required this.dateTime,
    required this.syncStatus,
    required this.reviewStatus,
  });

  factory InspectionDto.fromJson(Map<String, dynamic> json) => InspectionDto(
        submissionId: json['submission_id'] as String,
        mineId: json['mine_id'] as String,
        inspectorId: json['inspector_id'] as String,
        inspectorName: json['inspector_name'] as String,
        inspectionType: json['inspection_type'] as String,
        checklist: (json['checklist'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList(),
        violationFound: json['violation_found'] as String,
        violationSeverity: json['violation_severity'] as String?,
        violationDescription: json['violation_description'] as String?,
        correctiveAction: json['corrective_action'] as String?,
        photosOrVideos: (json['photos_or_videos'] as List)
            .map((item) => item as String)
            .toList(),
        location: json['location'] == null
            ? null
            : Map<String, dynamic>.from(json['location'] as Map),
        dateTime: DateTime.parse(json['date_time'] as String),
        syncStatus: json['sync_status'] as String,
        reviewStatus: json['review_status'] as String,
      );

  factory InspectionDto.fromDomain(InspectionReport report) {
    final failed = report.checklist
        .where((item) => item.status == CheckItemStatus.fail)
        .toList();
    final evidence = [
      ...report.globalEvidence,
      ...report.checklist.expand((item) => item.evidence),
    ];
    final checklist = report.checklist
        .map((item) => {
              'question': item.question,
              'answer': item.status == CheckItemStatus.na
                  ? 'not_applicable'
                  : item.status.name,
              'remarks': item.remarks,
            })
        .toList();
    return InspectionDto(
      submissionId: report.clientUuid,
      mineId: report.mineId,
      inspectorId: report.userId,
      inspectorName: report.userName,
      inspectionType: report.type.value,
      checklist: checklist,
      violationFound: failed.isEmpty ? 'no' : 'yes',
      violationSeverity: failed
          .map((item) => item.severity?.name)
          .whereType<String>()
          .fold<String?>(null, _highestSeverity),
      violationDescription: _join(failed.map((item) => item.violationDescription)),
      correctiveAction: _join(failed.map((item) => item.correctiveAction)),
      photosOrVideos: evidence.map(externalEvidenceValue).whereType<String>().toList(),
      location: locationJson(report.latitude, report.longitude),
      dateTime: report.submittedAt ?? report.createdAt,
      syncStatus: backendSyncStatus(report.status),
      reviewStatus: report.status == RecordStatus.underReview ? 'under_review' : 'submitted',
    );
  }

  InspectionReport toDomain({String mineName = '', String userDesignation = ''}) {
    final parsedChecklist = checklist.asMap().entries.map((e) {
      final q = e.value['question'] as String? ?? 'Item ${e.key + 1}';
      final a = e.value['answer'] as String? ?? 'pass';
      final remarks = e.value['remarks'] as String?;
      CheckItemStatus status = CheckItemStatus.pass;
      if (a == 'fail') {
        status = CheckItemStatus.fail;
      } else if (a == 'not_applicable' || a == 'na') {
        status = CheckItemStatus.na;
      }
      return InspectionChecklistItem(
        id: 'chk_${e.key + 1}',
        section: 'General',
        question: q,
        guidance: '',
        hindiQuestion: '',
        status: status,
        remarks: remarks,
        violationDescription: violationDescription,
        correctiveAction: correctiveAction,
        severity: violationSeverity != null
            ? ViolationSeverity.values.firstWhere(
                (s) => s.name == violationSeverity,
                orElse: () => ViolationSeverity.minor,
              )
            : null,
      );
    }).toList();

    return InspectionReport(
      clientUuid: submissionId,
      mineId: mineId,
      mineName: mineName,
      userId: inspectorId,
      userName: inspectorName,
      userDesignation: userDesignation,
      type: InspectionType.values.firstWhere(
        (t) => t.value == inspectionType,
        orElse: () => InspectionType.safety,
      ),
      checklist: parsedChecklist,
      latitude: (location?['latitude'] as num?)?.toDouble(),
      longitude: (location?['longitude'] as num?)?.toDouble(),
      status: reviewStatus == 'under_review'
          ? RecordStatus.underReview
          : RecordStatus.synced,
      createdAt: dateTime,
      submittedAt: dateTime,
      updatedAt: dateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'submission_id': submissionId,
        'mine_id': mineId,
        'inspector_id': inspectorId,
        'inspector_name': inspectorName,
        'inspection_type': inspectionType,
        'checklist': checklist,
        'violation_found': violationFound,
        'violation_severity': violationSeverity,
        'violation_description': violationDescription,
        'corrective_action': correctiveAction,
        'photos_or_videos': photosOrVideos,
        'location': location,
        'date_time': formatContractDateTime(dateTime),
        'sync_status': syncStatus,
        'review_status': reviewStatus,
      };

  static String? _join(Iterable<String?> values) {
    final result = values.whereType<String>().where((value) => value.isNotEmpty).join('\n');
    return result.isEmpty ? null : result;
  }

  static String _highestSeverity(String? current, String next) {
    const rank = {'minor': 1, 'major': 2, 'critical': 3};
    if (current == null) return next;
    return (rank[next] ?? 0) > (rank[current] ?? 0) ? next : current;
  }
}
