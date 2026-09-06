import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/models/sync_item_model.dart';

void main() {
  group('Universal Sync Queue Model & Lifecycle Tests', () {
    test('Queue item supports all canonical report types without translation labels', () {
      final types = [
        SyncRecordType.attendance,
        SyncRecordType.incident,
        SyncRecordType.observation,
        SyncRecordType.inspection,
        SyncRecordType.document,
      ];
      for (final type in types) {
        final item = SyncQueueItem(
          id: '1',
          clientUuid: 'TEST-${type.name}-001',
          recordType: type,
          payloadJson: '{}',
          state: SyncState.pending,
          queuedAt: DateTime.now(),
        );

        expect(item.recordType, equals(type));
        expect(item.submissionId, equals('TEST-${type.name}-001'));
        expect(item.state, equals(SyncState.pending));

        final map = item.toMap();
        expect(map['record_type'], equals(type.name));
        final restored = SyncQueueItem.fromMap(map);
        expect(restored.recordType, equals(type));
      }
    });

    test('Queue item state transitions follow canonical lifecycle', () {
      final now = DateTime.utc(2026, 9, 6, 12, 0, 0);
      var item = SyncQueueItem(
        id: '1',
        clientUuid: 'INC-2026-001',
        recordType: SyncRecordType.incident,
        payloadJson: '{}',
        state: SyncState.pending,
        retryCount: 0,
        queuedAt: now,
      );

      expect(item.state, equals(SyncState.pending));

      // Transition to syncing / inProgress
      item = item.copyWith(state: SyncState.inProgress, lastAttemptAt: now.add(const Duration(seconds: 1)));
      expect(item.state, equals(SyncState.inProgress));

      // Transition on failure (retryable)
      item = item.copyWith(
        state: SyncState.failed,
        retryCount: 1,
        errorMessage: 'Network timeout',
        errorStage: 'media',
        errorCode: 'TIMEOUT',
        isRetryable: true,
        nextRetryAt: now.add(const Duration(seconds: 5)),
        lastAttemptAt: now.add(const Duration(seconds: 2)),
      );
      expect(item.state, equals(SyncState.failed));
      expect(item.retryCount, equals(1));
      expect(item.isRetryable, isTrue);
      expect(item.errorStage, equals('media'));

      // Transition to completed / synced
      item = item.copyWith(
        state: SyncState.completed,
        errorMessage: null,
        errorStage: null,
        errorCode: null,
        lastAttemptAt: now.add(const Duration(seconds: 10)),
      );
      expect(item.state, equals(SyncState.completed));
    });

    test('Queue item accurately tracks non-retryable permission denial', () {
      final now = DateTime.utc(2026, 9, 6, 12, 0, 0);
      final item = SyncQueueItem(
        id: '5',
        clientUuid: 'SAF-2026-001',
        recordType: SyncRecordType.inspection,
        payloadJson: '{}',
        state: SyncState.failed,
        retryCount: 1,
        errorMessage: 'Missing or insufficient permissions [PERMISSION_DENIED]',
        errorStage: 'firestore',
        errorCode: 'PERMISSION_DENIED',
        isRetryable: false,
        queuedAt: now,
      );

      expect(item.isRetryable, isFalse);
      expect(item.errorCode, equals('PERMISSION_DENIED'));
      expect(item.errorStage, equals('firestore'));
    });
  });
}
