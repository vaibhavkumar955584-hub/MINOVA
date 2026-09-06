class EvidenceItem {
  final String id;
  final String reportClientUuid;
  final String localFilePath;
  final String fileType; // 'photo' | 'video' | 'audio' | 'document'
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String sha256Hash;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? locationSource;
  final String? zoneName;
  final String? caption;
  String? storagePath;
  String? downloadUrl;
  String storageProvider;
  int? width;
  int? height;
  int? durationSeconds;
  String uploadStatus;
  int uploadAttempts;
  String? lastUploadError;

  EvidenceItem({
    required this.id,
    required this.reportClientUuid,
    required this.localFilePath,
    required this.fileType,
    String? fileName,
    String? mimeType,
    required this.fileSize,
    required this.sha256Hash,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.locationSource,
    this.zoneName,
    this.caption,
    this.storagePath,
    this.downloadUrl,
    this.storageProvider = 'cloudinary',
    this.width,
    this.height,
    this.durationSeconds,
    this.uploadStatus = 'pending',
    this.uploadAttempts = 0,
    this.lastUploadError,
  }) : fileName = fileName ?? localFilePath.split(RegExp(r'[/\\]')).last,
       mimeType = mimeType ?? _mimeTypeFor(fileType, localFilePath);

  String get reportId => reportClientUuid;
  String get type => fileType;
  String get localPath => localFilePath;
  String get sha256 => sha256Hash;

  static String _mimeTypeFor(String type, String path) {
    final extension = path.split('.').last.toLowerCase();
    if (type == 'photo') return 'image/$extension';
    if (type == 'video') return 'video/$extension';
    if (type == 'signature') return 'image/png';
    return 'application/octet-stream';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'evidence_id': id,
      'report_client_uuid': reportClientUuid,
      'report_id': reportClientUuid,
      'local_file_path': localFilePath,
      'local_path': localFilePath,
      'file_type': fileType,
      'media_type': fileType == 'photo' ? 'image' : fileType,
      'file_size': fileSize,
      'sha256_hash': sha256Hash,
      'sha256': sha256Hash,
      'captured_at': capturedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_source': locationSource,
      'zone_name': zoneName,
      'caption': caption,
      'file_name': fileName,
      'mime_type': mimeType,
      'storage_path': storagePath,
      'download_url': downloadUrl,
      'secure_url': downloadUrl,
      'storage_provider': storageProvider,
      'width': width,
      'height': height,
      'duration': durationSeconds,
      'upload_status': uploadStatus,
      'upload_attempts': uploadAttempts,
      'last_upload_error': lastUploadError,
    };
  }

  factory EvidenceItem.fromMap(Map<String, dynamic> map) {
    return EvidenceItem(
      id: (map['id'] ?? map['evidence_id']) as String,
      reportClientUuid:
          (map['report_client_uuid'] ?? map['report_id']) as String,
      localFilePath: (map['local_file_path'] ?? map['local_path']) as String,
      fileType: (map['file_type'] ?? map['media_type']) as String,
      fileSize: map['file_size'] as int,
      sha256Hash: (map['sha256_hash'] ?? map['sha256']) as String,
      capturedAt: DateTime.parse(map['captured_at'] as String),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationSource: map['location_source'] as String?,
      zoneName: map['zone_name'] as String?,
      caption: map['caption'] as String?,
      fileName: map['file_name'] as String?,
      mimeType: map['mime_type'] as String?,
      storagePath: map['storage_path'] as String?,
      downloadUrl: (map['download_url'] ?? map['secure_url']) as String?,
      storageProvider: map['storage_provider'] as String? ?? 'cloudinary',
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      durationSeconds: (map['duration'] as num?)?.toInt(),
      uploadStatus: map['upload_status'] as String? ?? 'pending',
      uploadAttempts: (map['upload_attempts'] as num?)?.toInt() ?? 0,
      lastUploadError: map['last_upload_error'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'evidence_id': id,
      'file_name': fileName,
      'media_type': fileType == 'photo' ? 'image' : fileType,
      'storage_provider': storageProvider,
      'storage_path': storagePath,
      'secure_url': downloadUrl,
      'sha256': sha256Hash,
      'captured_at': capturedAt,
      'latitude': latitude,
      'longitude': longitude,
      'location_source': locationSource,
      'upload_status': uploadStatus,
      'width': width,
      'height': height,
      'duration': durationSeconds,
    };
  }
}
