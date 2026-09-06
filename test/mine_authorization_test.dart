import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/models/user_model.dart';

void main() {
  group('Mine Authorization & Multi-Mine Access Tests', () {
    const validUid = 'J1jQJRNGcRRhBr3Pt1WRKg7vqId2';
    const authorizedMineA = 'JH-DHA-BCCL-007';
    const authorizedMineB = 'mine_jharsuguda_01';
    const unauthorizedMine = 'MINE-UNAUTH-999';

    final inspector = UserModel(
      id: validUid,
      employeeId: 'DGMS-INSP-2026',
      fullName: 'Priya Mukhopadhyay',
      role: UserRole.inspector,
      designation: 'Statutory Mine Inspector',
      assignedMineId: authorizedMineA,
      assignedMineName: 'BCCL Pit-7 (Dhanbad)',
      assignedMineIds: [authorizedMineA, authorizedMineB],
      accountStatus: 'active',
      managerId: 'MGR-HQ-001',
    );

    test('1. Primary authorized mine access is allowed', () {
      final isAuthorized = inspector.assignedMineIds.contains(authorizedMineA) ||
          inspector.assignedMineId == authorizedMineA;
      expect(isAuthorized, isTrue);
    });

    test('2. Secondary authorized mine access is allowed', () {
      final isAuthorized = inspector.assignedMineIds.contains(authorizedMineB) ||
          inspector.assignedMineId == authorizedMineB;
      expect(isAuthorized, isTrue);
    });

    test('3. Unauthorized mine access is rejected', () {
      final isAuthorized = inspector.assignedMineIds.contains(unauthorizedMine) ||
          inspector.assignedMineId == unauthorizedMine;
      expect(isAuthorized, isFalse);
    });
  });
}
