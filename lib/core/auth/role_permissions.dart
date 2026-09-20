import '../../models/user_model.dart';

class RolePermissions {
  final bool canPerformInspection;
  final bool canReportIncident;
  final bool canManageAttendance;
  final bool canSubmitObservation;
  final bool canUploadDocument;
  final bool canDirectlyApproveCorrections;
  final bool canRequestCorrection;

  const RolePermissions({
    required this.canPerformInspection,
    required this.canReportIncident,
    required this.canManageAttendance,
    required this.canSubmitObservation,
    required this.canUploadDocument,
    required this.canDirectlyApproveCorrections,
    required this.canRequestCorrection,
  });

  factory RolePermissions.forUser(UserModel user) {
    final role = user.role;
    final designation = user.designation.toLowerCase();

    // 0. Employee / Field Responder
    if (role == UserRole.employee) {
      return const RolePermissions(
        canPerformInspection: false,
        canReportIncident: true,
        canManageAttendance: false,
        canSubmitObservation: false,
        canUploadDocument: false,
        canDirectlyApproveCorrections: false,
        canRequestCorrection: false,
      );
    }

    // 1. Inspector
    if (role == UserRole.inspector) {
      return const RolePermissions(
        canPerformInspection: true,
        canReportIncident: true,
        canManageAttendance: false,
        canSubmitObservation: true,
        canUploadDocument: true,
        canDirectlyApproveCorrections: false,
        canRequestCorrection: true,
      );
    }

    // 2. Contractor
    if (role == UserRole.contractor) {
      final isSupervisor = designation.contains('supervisor') ||
          designation.contains('manager') ||
          designation.contains('engineer');
      return RolePermissions(
        canPerformInspection: false,
        canReportIncident: true,
        canManageAttendance: isSupervisor,
        canSubmitObservation: true,
        canUploadDocument: isSupervisor,
        canDirectlyApproveCorrections: false,
        canRequestCorrection: true,
      );
    }

    // 3. Mine Official
    final isSafetyOfficer = designation.contains('safety') ||
        designation.contains('officer') ||
        designation.contains('manager') ||
        designation.contains('agent') ||
        designation.contains('director');

    final isSupervisor = designation.contains('supervisor') ||
        designation.contains('overman') ||
        designation.contains('sirdar');

    return RolePermissions(
      canPerformInspection: isSafetyOfficer || isSupervisor,
      canReportIncident: true,
      canManageAttendance: true,
      canSubmitObservation: true,
      canUploadDocument: true,
      canDirectlyApproveCorrections: isSafetyOfficer,
      canRequestCorrection: true,
    );
  }
}
