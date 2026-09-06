/// Provider-neutral binary media storage boundary.
///
/// UI, repositories, and domain models only receive [UploadResult]. They never
/// need to know whether Cloudinary or another provider stored a file.
abstract class StorageService {
  Future<UploadResult> uploadImage({
    required String localPath,
    required String evidenceId,
    required String reportId,
    required String mineId,
    required String reportType,
  });

  Future<UploadResult> uploadVideo({
    required String localPath,
    required String evidenceId,
    required String reportId,
    required String mineId,
    required String reportType,
  });

  Future<UploadResult> uploadDocument({
    required String localPath,
    required String evidenceId,
    required String reportId,
    required String mineId,
  });

  Future<void> delete({required String storagePath});
}

class UploadResult {
  final String provider;
  final String storagePath;
  final String secureUrl;
  final int? width;
  final int? height;
  final int? durationSeconds;

  const UploadResult({
    required this.provider,
    required this.storagePath,
    required this.secureUrl,
    this.width,
    this.height,
    this.durationSeconds,
  });
}

class StorageUploadException implements Exception {
  /// Safe for field-user UI. Deliberately excludes provider HTTP internals.
  final String message;
  const StorageUploadException(this.message);

  @override
  String toString() => message;
}
