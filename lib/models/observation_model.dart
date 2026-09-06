import 'dart:convert';
import 'evidence_model.dart';
import 'inspection_model.dart';

enum ObservationType {
  observation,
  grievance,
}

enum ObservationCategory {
  safety,
  environmental,
  labour,
  gasReading,
  other,
}

extension ObservationCategoryExtension on ObservationCategory {
  String get displayName {
    switch (this) {
      case ObservationCategory.safety:
        return 'Safety Hazard';
      case ObservationCategory.environmental:
        return 'Environmental Notice';
      case ObservationCategory.labour:
        return 'Labour Grievance';
      case ObservationCategory.gasReading:
        return 'Gas & Atmospheric Log';
      case ObservationCategory.other:
        return 'General Observation';
    }
  }
}

class ObservationRecord {
  final String clientUuid;
  final String? serverId;
  final String mineId;
  final String mineName;
  final String userId;
  final String userName;
  final ObservationType entryType;
  final ObservationCategory category;
  final String description;
  final String? voiceNotePath;
  final String? voiceTranscription;
  final double? ch4Percent;
  final int? coPpm;
  final double? o2Percent;
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
  String? integrityHash;
  String? syncError;

  ObservationRecord({
    required this.clientUuid,
    this.serverId,
    required this.mineId,
    required this.mineName,
    required this.userId,
    required this.userName,
    required this.entryType,
    required this.category,
    required this.description,
    this.voiceNotePath,
    this.voiceTranscription,
    this.ch4Percent,
    this.coPpm,
    this.o2Percent,
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
    this.integrityHash,
    this.syncError,
  }) : evidence = evidence ?? [];

  Map<String, dynamic> toDbMap() {
    return {
      'client_uuid': clientUuid,
      'server_id': serverId,
      'mine_id': mineId,
      'mine_name': mineName,
      'user_id': userId,
      'user_name': userName,
      'entry_type': entryType.name,
      'category': category.name,
      'description': description,
      'voice_note_path': voiceNotePath,
      'voice_transcription': voiceTranscription,
      'ch4_percent': ch4Percent,
      'co_ppm': coPpm,
      'o2_percent': o2Percent,
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
      'integrity_hash': integrityHash,
      'sync_error': syncError,
    };
  }

  factory ObservationRecord.fromDbMap(Map<String, dynamic> map) {
    List<EvidenceItem> evidence = [];
    if (map['evidence_json'] != null) {
      final decoded = jsonDecode(map['evidence_json'] as String) as List;
      evidence = decoded
          .map((e) => EvidenceItem.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return ObservationRecord(
      clientUuid: map['client_uuid'] as String,
      serverId: map['server_id'] as String?,
      mineId: map['mine_id'] as String,
      mineName: map['mine_name'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      entryType: ObservationType.values.firstWhere(
        (e) => e.name == map['entry_type'],
        orElse: () => ObservationType.observation,
      ),
      category: ObservationCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ObservationCategory.safety,
      ),
      description: map['description'] as String,
      voiceNotePath: map['voice_note_path'] as String?,
      voiceTranscription: map['voice_transcription'] as String?,
      ch4Percent: (map['ch4_percent'] as num?)?.toDouble(),
      coPpm: map['co_ppm'] as int?,
      o2Percent: (map['o2_percent'] as num?)?.toDouble(),
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
      integrityHash: map['integrity_hash'] as String?,
      syncError: map['sync_error'] as String?,
    );
  }
}
