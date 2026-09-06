import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'storage_service.dart';

/// Cloudinary implementation for evidence binaries.
///
/// Configure with --dart-define=CLOUDINARY_CLOUD_NAME=... and either an
/// unsigned upload preset (--dart-define=CLOUDINARY_UNSIGNED_UPLOAD_PRESET=...)
/// for a demo, or a backend signing endpoint. API secrets are never present in
/// this client.
class CloudinaryStorageService implements StorageService {
  static final CloudinaryStorageService instance = CloudinaryStorageService();

  final http.Client _client;
  final String cloudName;
  final String unsignedUploadPreset;
  final String signingEndpoint;

  static const String defaultCloudName = 'krcsszeo';
  static const String defaultUnsignedPreset = 'minova_mobile_demo';

  CloudinaryStorageService({
    http.Client? client,
    String? cloudName,
    String? unsignedUploadPreset,
    String? signingEndpoint,
  }) : _client = client ?? http.Client(),
       cloudName = cloudName ??
           (const String.fromEnvironment('CLOUDINARY_CLOUD_NAME').isNotEmpty
               ? const String.fromEnvironment('CLOUDINARY_CLOUD_NAME')
               : defaultCloudName),
       unsignedUploadPreset = unsignedUploadPreset ??
           (const String.fromEnvironment('CLOUDINARY_UNSIGNED_UPLOAD_PRESET').isNotEmpty
               ? const String.fromEnvironment('CLOUDINARY_UNSIGNED_UPLOAD_PRESET')
               : defaultUnsignedPreset),
       signingEndpoint =
           signingEndpoint ??
           const String.fromEnvironment('MEDIA_SIGNING_ENDPOINT');

  bool get isConfigured =>
      cloudName.trim().isNotEmpty &&
      (unsignedUploadPreset.trim().isNotEmpty ||
          signingEndpoint.trim().isNotEmpty);

  @override
  Future<UploadResult> uploadImage({
    required String localPath,
    required String evidenceId,
    required String reportId,
    required String mineId,
    required String reportType,
  }) => _upload(
    localPath: localPath,
    evidenceId: evidenceId,
    resourceType: 'image',
    publicId: _publicId(mineId, reportType, reportId, evidenceId),
  );

  @override
  Future<UploadResult> uploadVideo({
    required String localPath,
    required String evidenceId,
    required String reportId,
    required String mineId,
    required String reportType,
  }) => _upload(
    localPath: localPath,
    evidenceId: evidenceId,
    resourceType: 'video',
    publicId: _publicId(mineId, reportType, reportId, evidenceId),
  );

  @override
  Future<UploadResult> uploadDocument({
    required String localPath,
    required String evidenceId,
    required String reportId,
    required String mineId,
  }) => _upload(
    localPath: localPath,
    evidenceId: evidenceId,
    resourceType: 'raw',
    publicId: _publicId(mineId, 'document', reportId, evidenceId),
  );

  @override
  Future<void> delete({required String storagePath}) async {
    // Deletion must be signed and is deliberately backend-owned. Keeping this
    // no-op prevents exposing a Cloudinary API secret in a mobile client.
    if (storagePath.trim().isEmpty) return;
    throw const StorageUploadException(
      'Media removal is managed by the server.',
    );
  }

  String _publicId(
    String mineId,
    String reportType,
    String reportId,
    String evidenceId,
  ) => 'minesafe/$mineId/$reportType/$reportId/$evidenceId';

  Future<UploadResult> _upload({
    required String localPath,
    required String evidenceId,
    required String resourceType,
    required String publicId,
  }) async {
    if (!isConfigured) {
      throw const StorageUploadException('Media upload is not configured yet.');
    }
    final file = File(localPath);
    if (!await file.exists()) {
      throw const StorageUploadException(
        'Media file is no longer available on this phone.',
      );
    }
    // A signing endpoint is intentionally only a configuration seam. The
    // backend contract has not been supplied, so unsigned preset upload is the
    // supported demo flow until that endpoint is integrated.
    if (unsignedUploadPreset.trim().isEmpty) {
      throw const StorageUploadException(
        'Secure media signing is not available yet.',
      );
    }
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse(
                'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
              ),
            )
            ..fields['upload_preset'] = unsignedUploadPreset
            ..files.add(await http.MultipartFile.fromPath('file', localPath));
      final response = await _client.send(request);
      final body = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String detail = 'HTTP ${response.statusCode}';
        try {
          final errJson = jsonDecode(body) as Map<String, dynamic>;
          detail = (errJson['error']?['message'] as String?) ?? body;
        } catch (_) {
          detail = body;
        }
        if (kDebugMode) {
          print('[SYNC][CLOUDINARY_ERROR] status=${response.statusCode} detail=$detail');
        }
        throw StorageUploadException('Media upload failed ($detail). Will try again.');
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final secureUrl = json['secure_url'] as String?;
      final storagePath = json['public_id'] as String?;
      if (secureUrl == null || storagePath == null) {
        throw const StorageUploadException(
          'Media upload response was incomplete.',
        );
      }
      return UploadResult(
        provider: 'cloudinary',
        storagePath: storagePath,
        secureUrl: secureUrl,
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
        durationSeconds: (json['duration'] as num?)?.round(),
      );
    } on StorageUploadException {
      rethrow;
    } on SocketException {
      throw const StorageUploadException('Waiting for internet.');
    } catch (e) {
      if (kDebugMode) {
        print('[SYNC][CLOUDINARY_EXCEPTION] $e');
      }
      throw StorageUploadException(
        'Media upload failed ($e). Will try again.',
      );
    }
  }
}
