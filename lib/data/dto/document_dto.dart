import '../../models/document_model.dart';
import '../../models/inspection_model.dart';
import 'contract_helpers.dart';

/// DTO for statutory compliance documents and safety certificates.
class DocumentDto {
  final String submissionId;
  final String mineId;
  final String userId;
  final String userName;
  final String category;
  final String title;
  final String? documentNumber;
  final String? associatedContractor;
  final DateTime? expiryDate;
  final String? remarks;
  final List<String> files;
  final DateTime dateTime;
  final String syncStatus;
  final String reviewStatus;

  const DocumentDto({
    required this.submissionId,
    required this.mineId,
    required this.userId,
    required this.userName,
    required this.category,
    required this.title,
    this.documentNumber,
    this.associatedContractor,
    this.expiryDate,
    this.remarks,
    required this.files,
    required this.dateTime,
    required this.syncStatus,
    required this.reviewStatus,
  });

  factory DocumentDto.fromJson(Map<String, dynamic> json) => DocumentDto(
        submissionId: json['submission_id'] as String,
        mineId: json['mine_id'] as String,
        userId: json['user_id'] as String,
        userName: json['user_name'] as String,
        category: json['category'] as String,
        title: json['title'] as String,
        documentNumber: json['document_number'] as String?,
        associatedContractor: json['associated_contractor'] as String?,
        expiryDate: parseDateTime(json['expiry_date']),
        remarks: json['remarks'] as String?,
        files: (json['files'] as List?)?.cast<String>() ??
            (json['photos_or_videos'] as List?)?.cast<String>() ??
            [],
        dateTime: DateTime.parse(json['date_time'] as String),
        syncStatus: json['sync_status'] as String,
        reviewStatus: json['review_status'] as String,
      );

  factory DocumentDto.fromDomain(ComplianceDocument doc) => DocumentDto(
        submissionId: doc.clientUuid,
        mineId: doc.mineId,
        userId: doc.userId,
        userName: doc.userName,
        category: doc.category.name,
        title: doc.title,
        documentNumber: doc.documentNumber,
        associatedContractor: doc.associatedContractor,
        expiryDate: doc.expiryDate,
        remarks: doc.remarks,
        files: doc.files.map(externalEvidenceValue).whereType<String>().toList(),
        dateTime: doc.submittedAt ?? doc.createdAt,
        syncStatus: backendSyncStatus(doc.status),
        reviewStatus: doc.status == RecordStatus.underReview
            ? 'under_review'
            : 'submitted',
      );

  ComplianceDocument toDomain({String mineName = ''}) => ComplianceDocument(
        clientUuid: submissionId,
        mineId: mineId,
        mineName: mineName,
        userId: userId,
        userName: userName,
        category: DocumentCategory.values.firstWhere(
          (c) => c.name == category,
          orElse: () => DocumentCategory.otherCompliance,
        ),
        title: title,
        documentNumber: documentNumber,
        associatedContractor: associatedContractor,
        expiryDate: expiryDate,
        remarks: remarks,
        status: reviewStatus == 'under_review'
            ? RecordStatus.underReview
            : RecordStatus.synced,
        createdAt: dateTime,
        submittedAt: dateTime,
        updatedAt: dateTime,
        files: [],
      );

  Map<String, dynamic> toJson() => {
        'submission_id': submissionId,
        'mine_id': mineId,
        'user_id': userId,
        'user_name': userName,
        'category': category,
        'title': title,
        'document_number': documentNumber,
        'associated_contractor': associatedContractor,
        'expiry_date': expiryDate?.toIso8601String(),
        'remarks': remarks,
        'files': files,
        'date_time': dateTime.toIso8601String(),
        'sync_status': syncStatus,
        'review_status': reviewStatus,
      };
}
