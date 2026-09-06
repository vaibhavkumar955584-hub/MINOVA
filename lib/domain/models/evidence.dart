/// Provider-independent evidence model used at the domain boundary.
enum MediaType { image, video }

enum EvidenceUploadStatus { pending, uploading, uploaded, failed }

class Evidence {
  final String evidenceId;
  final String reportId;
  final String localPath;
  final String fileName;
  final MediaType mediaType;
  final String sha256;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? locationSource;
  final EvidenceUploadStatus uploadStatus;
  final String storageProvider;
  final String? storagePath;
  final String? secureUrl;
  final int? width;
  final int? height;
  final int? durationSeconds;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  const Evidence({
    required this.evidenceId,
    required this.reportId,
    required this.localPath,
    required this.fileName,
    required this.mediaType,
    required this.sha256,
    required this.capturedAt,
    required this.uploadStatus,
    required this.storageProvider,
    required this.createdAt,
    required this.retryCount,
    this.latitude,
    this.longitude,
    this.locationSource,
    this.storagePath,
    this.secureUrl,
    this.width,
    this.height,
    this.durationSeconds,
    this.lastError,
  });
}
