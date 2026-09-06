import 'dart:convert';
import 'evidence_model.dart';
import 'inspection_model.dart';

enum IncidentType {
  injury,
  equipmentFailure,
  nearMiss,
  fire,
  gasLeak,
  other,
}

extension IncidentTypeExtension on IncidentType {
  String get value {
    switch (this) {
      case IncidentType.injury:
        return 'injury';
      case IncidentType.equipmentFailure:
        return 'equipment_failure';
      case IncidentType.nearMiss:
        return 'near_miss';
      case IncidentType.fire:
        return 'fire';
      case IncidentType.gasLeak:
        return 'gas_leak';
      case IncidentType.other:
        return 'other';
    }
  }

  static IncidentType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'injury':
        return IncidentType.injury;
      case 'equipment_failure':
        return IncidentType.equipmentFailure;
      case 'near_miss':
        return IncidentType.nearMiss;
      case 'fire':
        return IncidentType.fire;
      case 'gas_leak':
        return IncidentType.gasLeak;
      case 'other':
      default:
        return IncidentType.other;
    }
  }

  String get displayName {
    switch (this) {
      case IncidentType.injury:
        return 'Worker Injury / Casualty';
      case IncidentType.equipmentFailure:
        return 'Heavy Machinery Breakdown';
      case IncidentType.nearMiss:
        return 'Near Miss Incident';
      case IncidentType.fire:
        return 'Underground Fire / Heating';
      case IncidentType.gasLeak:
        return 'Influx of Gas / Inundation';
      case IncidentType.other:
        return 'Other Hazardous Incident';
    }
  }
}

enum AuthorityAlertStatus {
  notRequired,
  queued,
  confirmed,
}

class IncidentReport {
  final String clientUuid;
  final String? serverId;
  final String mineId;
  final String mineName;
  final String userId;
  final String userName;
  final String userDesignation;
  final IncidentType type;
  final ViolationSeverity severity;
  final int peopleAffected;
  final List<String> affectedPersonDetails;
  final String description;
  final String immediateActionTaken;
  final bool medicalAttentionRequired;
  final String? equipmentInvolved;
  final bool notifyAuthorityImmediately;
  AuthorityAlertStatus authorityAlertStatus;
  RecordStatus status;
  final DateTime createdAt;
  DateTime? submittedAt;
  DateTime updatedAt;

  // Location
  double? latitude;
  double? longitude;
  double? accuracy;
  String locationSource; // 'gps' | 'gps_low' | 'manual'
  String? zoneId;
  String? zoneName;

  // Evidence & Signature
  List<EvidenceItem> evidence;
  String? signatureBase64;
  String? signatureHash;
  DateTime? signedAt;
  String? integrityHash;
  String? syncError;

  IncidentReport({
    required this.clientUuid,
    this.serverId,
    required this.mineId,
    required this.mineName,
    required this.userId,
    required this.userName,
    required this.userDesignation,
    required this.type,
    required this.severity,
    this.peopleAffected = 0,
    dynamic affectedPersonDetails,
    required this.description,
    required this.immediateActionTaken,
    this.medicalAttentionRequired = false,
    this.equipmentInvolved,
    this.notifyAuthorityImmediately = true,
    this.authorityAlertStatus = AuthorityAlertStatus.queued,
    this.status = RecordStatus.draft,
    required this.createdAt,
    this.submittedAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationSource = 'manual',
    this.zoneId,
    this.zoneName,
    List<EvidenceItem>? evidence,
    this.signatureBase64,
    this.signatureHash,
    this.signedAt,
    this.integrityHash,
    this.syncError,
  })  : affectedPersonDetails = _parseDetails(affectedPersonDetails),
        evidence = evidence ?? [];

  static List<String> _parseDetails(dynamic val) {
    if (val == null) return const [];
    if (val is List<String>) return val;
    if (val is List) return val.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    final str = val.toString().trim();
    if (str.isEmpty) return const [];
    try {
      final decoded = jsonDecode(str);
      if (decoded is List) {
        return decoded.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
    } catch (_) {}
    return str.split(RegExp(r'[,;\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Map<String, dynamic> toDbMap() {
    return {
      'client_uuid': clientUuid,
      'server_id': serverId,
      'mine_id': mineId,
      'mine_name': mineName,
      'user_id': userId,
      'user_name': userName,
      'user_designation': userDesignation,
      'type': type.value,
      'severity': severity.name,
      'people_affected': peopleAffected,
      'affected_person_details': jsonEncode(affectedPersonDetails),
      'description': description,
      'immediate_action_taken': immediateActionTaken,
      'medical_attention_required': medicalAttentionRequired ? 1 : 0,
      'equipment_involved': equipmentInvolved,
      'notify_authority_immediately': notifyAuthorityImmediately ? 1 : 0,
      'authority_alert_status': authorityAlertStatus.name,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'location_source': locationSource,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'evidence_json': jsonEncode(evidence.map((e) => e.toMap()).toList()),
      'signature_base64': signatureBase64,
      'signature_hash': signatureHash,
      'signed_at': signedAt?.toIso8601String(),
      'integrity_hash': integrityHash,
      'sync_error': syncError,
    };
  }

  factory IncidentReport.fromDbMap(Map<String, dynamic> map) {
    List<EvidenceItem> evidence = [];
    if (map['evidence_json'] != null) {
      final decoded = jsonDecode(map['evidence_json'] as String) as List;
      evidence = decoded
          .map((e) => EvidenceItem.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    dynamic affectedPersons;
    if (map['affected_person_details'] != null) {
      if (map['affected_person_details'] is String) {
        try {
          affectedPersons = jsonDecode(map['affected_person_details'] as String);
        } catch (_) {
          affectedPersons = [map['affected_person_details']];
        }
      } else {
        affectedPersons = map['affected_person_details'];
      }
    }

    return IncidentReport(
      clientUuid: map['client_uuid'] as String,
      serverId: map['server_id'] as String?,
      mineId: map['mine_id'] as String,
      mineName: map['mine_name'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userDesignation: map['user_designation'] as String,
      type: IncidentTypeExtension.fromString(map['type'] as String),
      severity: ViolationSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => ViolationSeverity.critical,
      ),
      peopleAffected: (map['people_affected'] as int?) ?? 0,
      affectedPersonDetails: affectedPersons,
      description: map['description'] as String,
      immediateActionTaken: map['immediate_action_taken'] as String,
      medicalAttentionRequired: (map['medical_attention_required'] as int?) == 1,
      equipmentInvolved: map['equipment_involved'] as String?,
      notifyAuthorityImmediately:
          (map['notify_authority_immediately'] as int?) == 1,
      authorityAlertStatus: AuthorityAlertStatus.values.firstWhere(
        (e) => e.name == map['authority_alert_status'],
        orElse: () => AuthorityAlertStatus.queued,
      ),
      status: RecordStatusExtension.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'] as String)
          : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      locationSource: (map['location_source'] as String?) ?? 'manual',
      zoneId: map['zone_id'] as String?,
      zoneName: map['zone_name'] as String?,
      evidence: evidence,
      signatureBase64: map['signature_base64'] as String?,
      signatureHash: map['signature_hash'] as String?,
      signedAt: map['signed_at'] != null
          ? DateTime.tryParse(map['signed_at'] as String)
          : null,
      integrityHash: map['integrity_hash'] as String?,
      syncError: map['sync_error'] as String?,
    );
  }
}
