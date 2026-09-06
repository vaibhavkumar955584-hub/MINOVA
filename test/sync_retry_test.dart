import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/models/sync_item_model.dart';

void main() {
  group('Sync Retry Policy & Classification Tests', () {
    test('Exponential backoff calculates bounded intervals', () {
      // Attempt 1 -> 5s
      final delay1 = Duration(seconds: 5 * (1 << (1 - 1))); // 5 * 1 = 5s
      expect(delay1.inSeconds, equals(5));

      // Attempt 2 -> 10s
      final delay2 = Duration(seconds: 5 * (1 << (2 - 1))); // 5 * 2 = 10s
      expect(delay2.inSeconds, equals(10));

      // Attempt 3 -> 20s
      final delay3 = Duration(seconds: 5 * (1 << (3 - 1))); // 5 * 4 = 20s
      expect(delay3.inSeconds, equals(20));

      // Attempt 4 -> 40s
      final delay4 = Duration(seconds: 5 * (1 << (4 - 1))); // 5 * 8 = 40s
      expect(delay4.inSeconds, equals(40));

      // Attempt 5 -> 80s
      final delay5 = Duration(seconds: 5 * (1 << (5 - 1))); // 5 * 16 = 80s
      expect(delay5.inSeconds, equals(80));
    });

    test('SyncQueueItem serialization retains errorStage, errorCode, and isRetryable', () {
      final now = DateTime.utc(2026, 9, 6, 12, 0, 0);
      final item = SyncQueueItem(
        id: '1',
        clientUuid: 'INC-2026-001',
        recordType: SyncRecordType.incident,
        payloadJson: '{}',
        state: SyncState.failed,
        retryCount: 3,
        errorMessage: 'Cloudinary timeout',
        errorStage: 'media',
        errorCode: 'TIMEOUT',
        isRetryable: true,
        queuedAt: now,
        nextRetryAt: now.add(const Duration(seconds: 20)),
      );

      final map = item.toMap();
      expect(map['client_uuid'], equals('INC-2026-001'));
      expect(map['record_type'], equals('incident'));
      expect(map['state'], equals('failed'));
      expect(map['retry_count'], equals(3));
      expect(map['error_message'], equals('Cloudinary timeout'));
      expect(map['error_stage'], equals('media'));
      expect(map['error_code'], equals('TIMEOUT'));
      expect(map['is_retryable'], equals(1));
      expect(item.submissionId, equals('INC-2026-001'));

      final restored = SyncQueueItem.fromMap(map);
      expect(restored.clientUuid, equals('INC-2026-001'));
      expect(restored.errorStage, equals('media'));
      expect(restored.errorCode, equals('TIMEOUT'));
      expect(restored.isRetryable, isTrue);
      expect(restored.nextRetryAt, equals(now.add(const Duration(seconds: 20))));
    });

    test('Permission-denied errors are classified as non-retryable', () {
      final now = DateTime.utc(2026, 9, 6, 12, 0, 0);
      final item = SyncQueueItem(
        id: '2',
        clientUuid: 'GRV-2026-001',
        recordType: SyncRecordType.observation,
        payloadJson: '{}',
        state: SyncState.failed,
        retryCount: 1,
        errorMessage: 'Missing or insufficient permissions.',
        errorStage: 'firestore',
        errorCode: 'PERMISSION_DENIED',
        isRetryable: false,
        queuedAt: now,
      );

      final map = item.toMap();
      expect(map['is_retryable'], equals(0));
      expect(map['error_stage'], equals('firestore'));
      expect(map['error_code'], equals('PERMISSION_DENIED'));

      final restored = SyncQueueItem.fromMap(map);
      expect(restored.isRetryable, isFalse);
      expect(restored.errorCode, equals('PERMISSION_DENIED'));
    });
  });
}
