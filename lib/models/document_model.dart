import 'dart:convert';
import 'evidence_model.dart';
import 'inspection_model.dart';

enum DocumentCategory {
  contractorLicense,
  statutoryCertificate,
  environmentalClearance,
  equipmentFitnessCertificate,
  mineSafetyPlan,
  otherCompliance,
}

extension DocumentCategoryExtension on DocumentCategory {
  String get displayName {
    switch (this) {
      case DocumentCategory.contractorLicense:
        return 'Contractor DGMS License';
      case DocumentCategory.statutoryCertificate:
        return 'Statutory Competency Certificate';
      case DocumentCategory.environmentalClearance:
        return 'State Environmental Clearance';
      case DocumentCategory.equipmentFitnessCertificate:
        return 'Flameproof / Machinery Fitness';
      case DocumentCategory.mineSafetyPlan:
        return 'Mine Safety Management Plan (SMP)';
      case DocumentCategory.otherCompliance:
        return 'Other Compliance Record';
    }
  }
}

class ComplianceDocument {
  final String clientUuid;
  final String? serverId;
  final String mineId;
  final String mineName;
  final String userId;
  final String userName;
  final DocumentCategory category;
  final String title;
  final String? documentNumber;
  final String? associatedContractor;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? remarks;
  RecordStatus status;
  final DateTime createdAt;
  DateTime? submittedAt;
  DateTime updatedAt;

  // Attached Document File
  final List<EvidenceItem> files;
  String? integrityHash;
  String? syncError;

  ComplianceDocument({
    required this.clientUuid,
    this.serverId,
    required this.mineId,
    required this.mineName,
    required this.userId,
    required this.userName,
    required this.category,
    required this.title,
    this.documentNumber,
    this.associatedContractor,
    this.issueDate,
    this.expiryDate,
    this.remarks,
    this.status = RecordStatus.draft,
    required this.createdAt,
    this.submittedAt,
    required this.updatedAt,
    required this.files,
    this.integrityHash,
    this.syncError,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'client_uuid': clientUuid,
      'server_id': serverId,
      'mine_id': mineId,
      'mine_name': mineName,
      'user_id': userId,
      'user_name': userName,
      'category': category.name,
      'title': title,
      'document_number': documentNumber,
      'associated_contractor': associatedContractor,
      'issue_date': issueDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'remarks': remarks,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'files_json': jsonEncode(files.map((e) => e.toMap()).toList()),
      'integrity_hash': integrityHash,
      'sync_error': syncError,
    };
  }

  factory ComplianceDocument.fromDbMap(Map<String, dynamic> map) {
    List<EvidenceItem> files = [];
    if (map['files_json'] != null) {
      final decoded = jsonDecode(map['files_json'] as String) as List;
      files = decoded
          .map((e) => EvidenceItem.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return ComplianceDocument(
      clientUuid: map['client_uuid'] as String,
      serverId: map['server_id'] as String?,
      mineId: map['mine_id'] as String,
      mineName: map['mine_name'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      category: DocumentCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => DocumentCategory.otherCompliance,
      ),
      title: map['title'] as String,
      documentNumber: map['document_number'] as String?,
      associatedContractor: map['associated_contractor'] as String?,
      issueDate: map['issue_date'] != null
          ? DateTime.tryParse(map['issue_date'] as String)
          : null,
      expiryDate: map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
      remarks: map['remarks'] as String?,
      status: RecordStatusExtension.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'] as String)
          : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      files: files,
      integrityHash: map['integrity_hash'] as String?,
      syncError: map['sync_error'] as String?,
    );
  }
}
