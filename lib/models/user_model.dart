enum UserRole { inspector, contractor, mineOfficial }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.inspector:
        return 'inspector';
      case UserRole.contractor:
        return 'contractor';
      case UserRole.mineOfficial:
        return 'mine_official';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'inspector':
        return UserRole.inspector;
      case 'contractor':
        return UserRole.contractor;
      case 'mine_official':
      default:
        return UserRole.mineOfficial;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.inspector:
        return 'Inspector';
      case UserRole.contractor:
        return 'Contractor';
      case UserRole.mineOfficial:
        return 'Mine Official';
    }
  }
}

class UserModel {
  final String id; // Firebase UID when authenticated via Firebase
  final String employeeId;
  final String fullName;
  final UserRole role;
  final String designation; // e.g. Safety Officer, Site Supervisor, Manager
  final String assignedMineId; // Primary mine (for backward compat with SQLite)
  final String assignedMineName;
  final List<String> assignedMineIds; // All assigned mines (Firestore)
  final String? phone;
  final String? email;
  final String? profilePhotoUrl;
  final String? contractorId;
  final String? managerId;
  final String accountStatus; // 'active' | 'suspended' | 'pending'
  final String preferredLanguage; // 'en' | 'hi'

  UserModel({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.role,
    required this.designation,
    required this.assignedMineId,
    required this.assignedMineName,
    List<String>? assignedMineIds,
    this.phone,
    this.email,
    this.profilePhotoUrl,
    this.contractorId,
    this.managerId,
    this.accountStatus = 'active',
    this.preferredLanguage = 'en',
  }) : assignedMineIds = assignedMineIds ?? [assignedMineId];

  // ── SQLite serialization (existing schema unchanged) ─────────
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'full_name': fullName,
      'role': role.value,
      'designation': designation,
      'assigned_mine_id': assignedMineId,
      'assigned_mine_name': assignedMineName,
      'phone': phone,
      'email': email,
      'preferred_language': preferredLanguage,
      'manager_id': managerId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      employeeId: map['employee_id'] as String,
      fullName: map['full_name'] as String,
      role: UserRoleExtension.fromString(map['role'] as String),
      designation: map['designation'] as String,
      assignedMineId: map['assigned_mine_id'] as String,
      assignedMineName: map['assigned_mine_name'] as String? ?? '',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      managerId: map['manager_id'] as String?,
      preferredLanguage: (map['preferred_language'] as String?) ?? 'en',
    );
  }

  // ── Firestore deserialization ────────────────────────────────
  factory UserModel.fromFirestore(String uid, Map<String, dynamic> data) {
    final fullName = (data['full_name'] ?? data['fullName'] ?? 'Unknown').toString();

    final mineAssignedVal = data['mine_assigned'] ?? data['mine_id'] ?? data['assignedMineId'];
    final mineIds = (data['assignedMineIds'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        (mineAssignedVal != null && mineAssignedVal.toString().isNotEmpty
            ? [mineAssignedVal.toString()]
            : []);

    final primaryMineId = (data['assignedMineId']?.toString().isNotEmpty == true)
        ? data['assignedMineId'].toString()
        : (mineIds.isNotEmpty
            ? mineIds.first
            : (mineAssignedVal?.toString() ?? ''));
    final mineName = (data['assignedMineName'] ?? data['mine_name'] ?? '') as String;

    return UserModel(
      id: uid,
      employeeId: (data['employee_id_or_contractor_id'] ?? data['employeeId'] ?? uid) as String,
      fullName: fullName,
      role: UserRoleExtension.fromString((data['role'] ?? '').toString()),
      designation: (data['designation'] ?? '') as String,
      assignedMineId: primaryMineId,
      assignedMineName: mineName,
      assignedMineIds: mineIds,
      phone: (data['phoneNumber'] ?? data['phone']) as String?,
      email: data['email'] as String?,
      profilePhotoUrl: (data['profilePhotoUrl'] ?? data['profile_photo_url']) as String?,
      contractorId: (data['contractor_id'] ?? data['contractorId']) as String?,
      managerId: (data['manager_id'] ?? data['managerId']) as String?,
      accountStatus: (data['accountStatus'] ?? data['account_status'] ?? 'active') as String,
      preferredLanguage: (data['preferred_language'] ?? data['preferredLanguage'] ?? 'en') as String,
    );
  }

  /// Serialize to Firestore document format.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'employeeId': employeeId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phone,
      'role': role.value,
      'designation': designation,
      'assignedMineId': assignedMineId,
      'assignedMineName': assignedMineName,
      'assignedMineIds': assignedMineIds,
      'profilePhotoUrl': profilePhotoUrl,
      'contractorId': contractorId,
      'managerId': managerId,
      'accountStatus': accountStatus,
      'preferredLanguage': preferredLanguage,
      'uid': id,
    };
  }

  UserModel copyWith({
    String? id,
    String? employeeId,
    String? fullName,
    UserRole? role,
    String? designation,
    String? assignedMineId,
    String? assignedMineName,
    String? phone,
    String? email,
    String? preferredLanguage,
    String? managerId,
  }) {
    return UserModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      designation: designation ?? this.designation,
      assignedMineId: assignedMineId ?? this.assignedMineId,
      assignedMineName: assignedMineName ?? this.assignedMineName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      managerId: managerId ?? this.managerId,
    );
  }
}
