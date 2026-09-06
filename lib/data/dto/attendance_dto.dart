import '../../models/attendance_model.dart';
import '../../models/inspection_model.dart';
import 'contract_helpers.dart';

/// Exact row contract supplied in attendance.json.
class AttendanceDto {
  final String submissionId;
  final String mineId;
  final String shift;
  final String workerId;
  final String workerName;
  final String workerType;
  final String? contractorId;
  final DateTime checkInTime;
  final Map<String, dynamic> checkInLocation;
  final DateTime? checkOutTime;
  final Map<String, dynamic>? checkOutLocation;
  final int expectedHeadcount;
  final int actualHeadcount;
  final DateTime dateTime;
  final String syncStatus;

  const AttendanceDto({
    required this.submissionId,
    required this.mineId,
    required this.shift,
    required this.workerId,
    required this.workerName,
    required this.workerType,
    required this.contractorId,
    required this.checkInTime,
    required this.checkInLocation,
    required this.checkOutTime,
    required this.checkOutLocation,
    required this.expectedHeadcount,
    required this.actualHeadcount,
    required this.dateTime,
    required this.syncStatus,
  });

  factory AttendanceDto.fromJson(Map<String, dynamic> json) {
    return AttendanceDto(
      submissionId: json['submission_id'] as String,
      mineId: json['mine_id'] as String,
      shift: json['shift'] as String,
      workerId: json['worker_id'] as String,
      workerName: json['worker_name'] as String,
      workerType: json['worker_type'] as String,
      contractorId: json['contractor_id'] as String?,
      checkInTime: DateTime.parse(json['check_in_time'] as String),
      checkInLocation: Map<String, dynamic>.from(
        json['check_in_location'] as Map,
      ),
      checkOutTime: parseDateTime(json['check_out_time']),
      checkOutLocation: json['check_out_location'] == null
          ? null
          : Map<String, dynamic>.from(json['check_out_location'] as Map),
      expectedHeadcount: (json['expected_headcount'] as num).toInt(),
      actualHeadcount: (json['actual_headcount'] as num).toInt(),
      dateTime: DateTime.parse(json['date_time'] as String),
      syncStatus: json['sync_status'] as String,
    );
  }

  /// One backend attendance row is produced for one local roster entry.
  factory AttendanceDto.fromDomain(
    AttendanceReport report,
    WorkerAttendanceEntry entry, {
    String? contractorId,
    double? latitude,
    double? longitude,
  }) {
    final checkInLocation = locationJson(latitude, longitude);
    if (checkInLocation == null) {
      throw const FormatException(
        'Attendance contract requires check_in_location.',
      );
    }
    return AttendanceDto(
      submissionId: report.clientUuid,
      mineId: report.mineId,
      shift: report.shiftName,
      workerId: entry.workerId,
      workerName: entry.workerName,
      workerType: entry.category,
      contractorId: contractorId,
      checkInTime: entry.checkInTime,
      checkInLocation: checkInLocation,
      checkOutTime: entry.checkOutTime,
      checkOutLocation: null,
      expectedHeadcount: report.expectedHeadcount,
      actualHeadcount: report.actualHeadcount,
      dateTime: report.submittedAt ?? report.createdAt,
      syncStatus: backendSyncStatus(report.status),
    );
  }

  WorkerAttendanceEntry toEntryDomain() => WorkerAttendanceEntry(
        workerId: workerId,
        workerName: workerName,
        category: workerType,
        contractorName: contractorId ?? '',
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
      );

  AttendanceReport toDomain({
    String mineName = '',
    String userId = '',
    String userName = '',
    String musterLocation = '',
  }) =>
      AttendanceReport(
        clientUuid: submissionId,
        mineId: mineId,
        mineName: mineName,
        userId: userId,
        userName: userName,
        shiftName: shift,
        musterLocation: musterLocation,
        expectedHeadcount: expectedHeadcount,
        actualHeadcount: actualHeadcount,
        entries: [toEntryDomain()],
        status: RecordStatus.synced,
        createdAt: dateTime,
        submittedAt: dateTime,
        updatedAt: dateTime,
      );

  Map<String, dynamic> toJson() => {
        'submission_id': submissionId,
        'mine_id': mineId,
        'shift': shift,
        'worker_id': workerId,
        'worker_name': workerName,
        'worker_type': workerType,
        'contractor_id': contractorId,
        'check_in_time': formatContractDateTime(checkInTime),
        'check_in_location': checkInLocation,
        'check_out_time': checkOutTime != null ? formatContractDateTime(checkOutTime!) : null,
        'check_out_location': checkOutLocation,
        'expected_headcount': expectedHeadcount,
        'actual_headcount': actualHeadcount,
        'date_time': formatContractDateTime(dateTime),
        'sync_status': syncStatus,
      };
}
