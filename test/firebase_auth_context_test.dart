import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/models/user_model.dart';

void main() {
  group('Firebase Auth Context & Mine Authorization Tests', () {
    test('User profile contains assignedMineIds list matching Firestore security rules', () {
      final user = UserModel(
        id: 'usr_priya_02',
        employeeId: 'DGMS-INSP-404',
        fullName: 'Priya Mukhopadhyay',
        role: UserRole.inspector,
        designation: 'Statutory Mine Inspector',
        assignedMineId: 'JH-DHA-BCCL-007',
        assignedMineName: 'BCCL Pit-7 (Dhanbad)',
        assignedMineIds: ['JH-DHA-BCCL-007', 'mine_jharsuguda_01', 'mine_dhanbad_01'],
        email: 'p.mukhopadhyay@dgms.gov.in',
        accountStatus: 'active',
        managerId: 'MGR-HQ-001',
      );

      final map = user.toFirestoreMap();
      expect(map['uid'], equals('usr_priya_02'));
      expect(map['role'], equals('inspector'));
      expect(map['accountStatus'], equals('active'));
      expect(map['assignedMineIds'], contains('JH-DHA-BCCL-007'));
      expect(map['assignedMineIds'], contains('mine_jharsuguda_01'));
      expect(map['assignedMineIds'], contains('mine_dhanbad_01'));
    });

    test('mineAssigned rule simulation: authorized mine succeeds, unauthorized mine is denied', () {
      final authorizedMines = ['JH-DHA-BCCL-007', 'mine_jharsuguda_01', 'mine_dhanbad_01'];

      bool checkMineAssigned(String mineId) {
        return authorizedMines.contains(mineId);
      }

      // Valid mine writes
      expect(checkMineAssigned('JH-DHA-BCCL-007'), isTrue);
      expect(checkMineAssigned('mine_jharsuguda_01'), isTrue);
      expect(checkMineAssigned('mine_dhanbad_01'), isTrue);

      // Unauthorized mine write
      expect(checkMineAssigned('UNAUTHORIZED_MINE_999'), isFalse);
    });

    test('canCreateReport rule simulation: inspector_id matching auth UID succeeds, mismatch is denied', () {
      const authUid = 'firebase_auth_uid_123';
      final authorizedMines = ['JH-DHA-BCCL-007'];

      bool canCreateReport({
        required String? requestAuthUid,
        required String? reportInspectorId,
        required String reportMineId,
        required String syncStatus,
      }) {
        if (requestAuthUid == null) return false;
        if (reportInspectorId != requestAuthUid) return false;
        if (!authorizedMines.contains(reportMineId)) return false;
        if (!['pending_sync', 'synced', 'failed'].contains(syncStatus)) return false;
        return true;
      }

      // Valid report write with matching auth UID
      expect(
        canCreateReport(
          requestAuthUid: authUid,
          reportInspectorId: authUid,
          reportMineId: 'JH-DHA-BCCL-007',
          syncStatus: 'synced',
        ),
        isTrue,
      );

      // Mismatched inspector_id (e.g. local sample ID vs Firebase UID)
      expect(
        canCreateReport(
          requestAuthUid: authUid,
          reportInspectorId: 'usr_different_inspector',
          reportMineId: 'JH-DHA-BCCL-007',
          syncStatus: 'synced',
        ),
        isFalse,
      );

      // Unauthenticated request
      expect(
        canCreateReport(
          requestAuthUid: null,
          reportInspectorId: authUid,
          reportMineId: 'JH-DHA-BCCL-007',
          syncStatus: 'synced',
        ),
        isFalse,
      );
    });
  });
}
