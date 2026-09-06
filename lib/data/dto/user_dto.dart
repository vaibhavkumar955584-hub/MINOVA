import '../../models/user_model.dart';

class UserDto {
  final String userId;
  final String fullName;
  final String role;
  final String designation;
  final String employeeIdOrContractorId;
  final String mineAssigned;
  final String? email;
  final String preferredLanguage;
  final DateTime? dateTimeRegistered;

  const UserDto({required this.userId, required this.employeeIdOrContractorId, required this.fullName, required this.role, required this.designation, required this.mineAssigned, required this.email, required this.preferredLanguage, required this.dateTimeRegistered});

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        userId: json['user_id'] as String,
        employeeIdOrContractorId: json['employee_id_or_contractor_id'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
        designation: json['designation'] as String,
        mineAssigned: json['mine_assigned'] as String,
        email: json['email'] as String?,
        preferredLanguage: json['preferred_language'] as String,
        dateTimeRegistered: json['date_time_registered'] == null ? null : DateTime.tryParse(json['date_time_registered'] as String),
      );

  factory UserDto.fromDomain(UserModel user, {DateTime? registeredAt}) => UserDto(userId: user.id, employeeIdOrContractorId: user.contractorId ?? user.employeeId, fullName: user.fullName, role: user.role.value, designation: user.designation, mineAssigned: user.assignedMineId, email: user.email, preferredLanguage: user.preferredLanguage, dateTimeRegistered: registeredAt);

  UserModel toDomain({String assignedMineName = ''}) => UserModel(id: userId, employeeId: employeeIdOrContractorId, fullName: fullName, role: UserRoleExtension.fromString(role), designation: designation, assignedMineId: mineAssigned, assignedMineName: assignedMineName, assignedMineIds: [mineAssigned], email: email, preferredLanguage: preferredLanguage);

  Map<String, dynamic> toJson() => {'user_id': userId, 'full_name': fullName, 'designation': designation, 'role': role, 'employee_id_or_contractor_id': employeeIdOrContractorId, 'mine_assigned': mineAssigned, 'preferred_language': preferredLanguage, 'email': email, 'date_time_registered': dateTimeRegistered?.toIso8601String()};
}
