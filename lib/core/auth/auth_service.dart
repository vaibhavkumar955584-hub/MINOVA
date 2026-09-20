import 'package:sqflite/sqflite.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

import '../../models/user_model.dart';
import '../database/app_database.dart';
import 'role_permissions.dart';
import 'secure_storage.dart';

class AuthService {
  final SecureTokenStorage _secureStorage;
  final AppDatabase _db;

  AuthService({SecureTokenStorage? secureStorage, AppDatabase? db})
    : _secureStorage = secureStorage ?? SecureTokenStorage.instance,
      _db = db ?? AppDatabase.instance;

  UserModel? _currentUser;
  RolePermissions? _currentPermissions;

  UserModel? get currentUser => _currentUser;
  RolePermissions? get permissions => _currentPermissions;
  bool get isAuthenticated => _currentUser != null;

  static final List<UserModel> mockUsers = [
    UserModel(
      id: 'usr_rajesh_01',
      employeeId: 'MS-8821',
      fullName: 'Rajesh Sharma',
      role: UserRole.mineOfficial,
      designation: 'Safety Officer',
      assignedMineId: 'JH-DHA-BCCL-007',
      assignedMineName: 'BCCL Pit-7 (Dhanbad)',
      phone: '+91 98765 43210',
      email: 'rajesh.sharma@coalindia.gov.in',
    ),
    UserModel(
      id: 'usr_priya_02',
      employeeId: 'DGMS-INSP-404',
      fullName: 'Priya Mukhopadhyay',
      role: UserRole.inspector,
      designation: 'Statutory Mine Inspector',
      assignedMineId: 'JH-DHA-BCCL-007',
      assignedMineName: 'BCCL Pit-7 (Dhanbad)',
      phone: '+91 98111 22334',
      email: 'p.mukhopadhyay@dgms.gov.in',
    ),
    UserModel(
      id: 'usr_vikram_03',
      employeeId: 'EMS-SUP-902',
      fullName: 'Vikram Singh',
      role: UserRole.contractor,
      designation: 'Site Supervisor',
      assignedMineId: 'JH-DHA-BCCL-007',
      assignedMineName: 'BCCL Pit-7 (Dhanbad)',
      phone: '+91 94321 56789',
      email: 'vikram.singh@easternmining.com',
    ),
  ];

  Future<UserModel?> restoreSession() async {
    try {
      final firebaseUser = Firebase.apps.isEmpty
          ? null
          : fb.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final localProfile = await _loadLocalUser(firebaseUser.uid);
        if (localProfile != null) {
          _currentUser = localProfile;
          _currentPermissions = RolePermissions.forUser(localProfile);
          return localProfile;
        }
      }
      if (!await _secureStorage.hasValidSession()) return null;
      final userId = await _secureStorage.getUserId();
      if (userId == null) return null;

      final localProfile = await _loadLocalUser(userId);
      _currentUser =
          localProfile ??
          mockUsers.firstWhere(
            (user) => user.id == userId,
            orElse: () => mockUsers.first,
          );
      _currentPermissions = RolePermissions.forUser(_currentUser!);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> _loadLocalUser(String userId) async {
    final db = await _db.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return maps.isEmpty ? null : UserModel.fromMap(maps.first);
  }

  Future<UserModel> login({
    required String employeeId,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final normalizedId = employeeId.trim();
    final upperId = normalizedId.toUpperCase();
    final matchingUsers = mockUsers.where(
      (user) => user.employeeId.toLowerCase() == normalizedId.toLowerCase(),
    );

    final user = matchingUsers.isNotEmpty
        ? matchingUsers.first
        : UserModel(
            id: 'usr_${normalizedId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}',
            employeeId: upperId,
            fullName: upperId.startsWith('INSP')
                ? 'Statutory Inspector'
                : 'Rajesh Sharma',
            role: upperId.startsWith('INSP')
                ? UserRole.inspector
                : upperId.startsWith('CONT')
                ? UserRole.contractor
                : UserRole.mineOfficial,
            designation: upperId.startsWith('INSP')
                ? 'Statutory Mine Inspector'
                : upperId.startsWith('CONT')
                ? 'Site Supervisor'
                : 'Safety Officer',
            assignedMineId: 'JH-DHA-BCCL-007',
            assignedMineName: 'BCCL Pit-7 (Dhanbad)',
          );

    _currentUser = user;
    _currentPermissions = RolePermissions.forUser(user);
    await _secureStorage.saveSession(
      token: 'jwt_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      userRole: user.role.value,
    );

    final db = await _db.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return user;
  }

  Future<void> setAuthenticatedUser({
    required UserModel user,
    required String token,
  }) async {
    _currentUser = user;
    _currentPermissions = RolePermissions.forUser(user);
    await _secureStorage.saveSession(
      token: token,
      userId: user.id,
      userRole: user.role.value,
    );
    final db = await _db.database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    _currentPermissions = null;
    await _secureStorage.clearSession();
  }

  Future<UserModel> loginEmployee({
    required String fullName,
    String? employeeId,
    required String mineId,
    required String mineName,
    required String specialistCategory,
    String preferredLanguage = 'en',
  }) async {
    final cleanName = fullName.trim();
    final cleanId = (employeeId != null && employeeId.trim().isNotEmpty)
        ? employeeId.trim().toUpperCase()
        : 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final uid =
        'usr_emp_${cleanName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch % 10000}';

    final user = UserModel(
      id: uid,
      employeeId: cleanId,
      fullName: cleanName,
      role: UserRole.employee,
      designation: specialistCategory,
      assignedMineId: mineId,
      assignedMineName: mineName,
      assignedMineIds: [mineId],
      preferredLanguage: preferredLanguage,
      accountStatus: 'active',
    );

    await setAuthenticatedUser(
      user: user,
      token: 'employee_mvp_$uid',
    );
    return user;
  }

  void switchUser(UserModel user) {
    _currentUser = user;
    _currentPermissions = RolePermissions.forUser(user);
  }
}
