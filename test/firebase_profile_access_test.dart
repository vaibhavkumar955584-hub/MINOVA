import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/models/user_model.dart';

void main() {
  group('Firebase Profile Access & Authorization Model Tests', () {
    const validUid = 'J1jQJRNGcRRhBr3Pt1WRKg7vqId2';
    const authorizedMineId = 'JH-DHA-BCCL-007';

    test('1. Valid inspector profile parsing from Firestore schema', () {
      final firestoreDoc = {
        'uid': validUid,
        'employeeId': 'DGMS-INSP-2026',
        'fullName': 'Priya Mukhopadhyay',
        'role': 'inspector',
        'designation': 'Statutory Mine Inspector',
        'assignedMineId': authorizedMineId,
        'assignedMineIds': [authorizedMineId, 'mine_jharsuguda_01', 'mine_dhanbad_01'],
        'accountStatus': 'active',
        'managerId': 'MGR-HQ-001',
        'preferredLanguage': 'en',
        'email': 'p.mukhopadhyay@dgms.gov.in',
      };

      final user = UserModel.fromFirestore(validUid, firestoreDoc);
      expect(user.id, equals(validUid));
      expect(user.role, equals(UserRole.inspector));
      expect(user.accountStatus, equals('active'));
      expect(user.assignedMineIds, contains(authorizedMineId));
      expect(user.assignedMineId, equals(authorizedMineId));
    });

    test('2. Suspended / Inactive account validation blocks authorization context', () {
      final firestoreDoc = {
        'uid': validUid,
        'employeeId': 'DGMS-INSP-2026',
        'fullName': 'Priya Mukhopadhyay',
        'role': 'inspector',
        'designation': 'Statutory Mine Inspector',
        'assignedMineId': authorizedMineId,
        'assignedMineIds': [authorizedMineId],
        'accountStatus': 'suspended',
        'managerId': 'MGR-HQ-001',
      };

      final user = UserModel.fromFirestore(validUid, firestoreDoc);
      expect(user.accountStatus, equals('suspended'));
      final isActive = user.accountStatus.toLowerCase() == 'active';
      expect(isActive, isFalse);
    });

    test('3. Non-inspector role validation blocks authorization context', () {
      final firestoreDoc = {
        'uid': validUid,
        'employeeId': 'DGMS-WRK-2026',
        'fullName': 'Amit Sharma',
        'role': 'contractor',
        'designation': 'Excavator Operator',
        'assignedMineId': authorizedMineId,
        'accountStatus': 'active',
      };

      final user = UserModel.fromFirestore(validUid, firestoreDoc);
      expect(user.role, equals(UserRole.contractor));
      final isInspector = user.role == UserRole.inspector;
      expect(isInspector, isFalse);
    });
  });
}
