import 'dart:convert';
import 'inspection_model.dart';

class WorkerAttendanceEntry {
  final String workerId;
  final String workerName;
  final String category; // 'General Miner' | 'Machinery Operator' | 'Electrician' | 'Timber/Support'
  final String contractorName;
  final bool isPresent;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? checkInZone;

  WorkerAttendanceEntry({
    required this.workerId,
    required this.workerName,
    required this.category,
    required this.contractorName,
    this.isPresent = true,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInZone,
  });

  Map<String, dynamic> toMap() {
    return {
      'worker_id': workerId,
      'worker_name': workerName,
      'category': category,
      'contractor_name': contractorName,
      'is_present': isPresent ? 1 : 0,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'check_in_zone': checkInZone,
    };
  }

  factory WorkerAttendanceEntry.fromMap(Map<String, dynamic> map) {
    return WorkerAttendanceEntry(
      workerId: map['worker_id'] as String,
      workerName: map['worker_name'] as String,
      category: map['category'] as String,
      contractorName: map['contractor_name'] as String,
      isPresent: (map['is_present'] as int?) == 1,
      checkInTime: DateTime.parse(map['check_in_time'] as String),
      checkOutTime: map['check_out_time'] != null
          ? DateTime.tryParse(map['check_out_time'] as String)
          : null,
      checkInZone: map['check_in_zone'] as String?,
    );
  }
}

class AttendanceReport {
  final String clientUuid;
  final String? serverId;
  final String mineId;
  final String mineName;
  final String userId;
  final String userName;
  final String shiftName; // 'Shift A (06:00 - 14:00)' | 'Shift B (14:00 - 22:00)' | 'Shift C (22:00 - 06:00)'
  final String musterLocation; // e.g., 'Pit-4 Muster Gate'
  final int expectedHeadcount;
  final int actualHeadcount;
  final List<WorkerAttendanceEntry> entries;
  RecordStatus status;
  final DateTime createdAt;
  DateTime? submittedAt;
  DateTime updatedAt;
  String? signatureBase64;
  String? signatureHash;
  String? integrityHash;
  String? syncError;

  AttendanceReport({
    required this.clientUuid,
    this.serverId,
    required this.mineId,
    required this.mineName,
    required this.userId,
    required this.userName,
    required this.shiftName,
    required this.musterLocation,
    required this.expectedHeadcount,
    required this.actualHeadcount,
    required this.entries,
    this.status = RecordStatus.draft,
    required this.createdAt,
    this.submittedAt,
    required this.updatedAt,
    this.signatureBase64,
    this.signatureHash,
    this.integrityHash,
    this.syncError,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'client_uuid': clientUuid,
      'server_id': serverId,
      'mine_id': mineId,
      'mine_name': mineName,
      'user_id': userId,
      'user_name': userName,
      'shift_name': shiftName,
      'muster_location': musterLocation,
      'expected_headcount': expectedHeadcount,
      'actual_headcount': actualHeadcount,
      'entries_json': jsonEncode(entries.map((e) => e.toMap()).toList()),
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'signature_base64': signatureBase64,
      'signature_hash': signatureHash,
      'integrity_hash': integrityHash,
      'sync_error': syncError,
    };
  }

  factory AttendanceReport.fromDbMap(Map<String, dynamic> map) {
    List<WorkerAttendanceEntry> entries = [];
    if (map['entries_json'] != null) {
      final decoded = jsonDecode(map['entries_json'] as String) as List;
      entries = decoded
          .map((e) => WorkerAttendanceEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return AttendanceReport(
      clientUuid: map['client_uuid'] as String,
      serverId: map['server_id'] as String?,
      mineId: map['mine_id'] as String,
      mineName: map['mine_name'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      shiftName: map['shift_name'] as String,
      musterLocation: map['muster_location'] as String,
      expectedHeadcount: (map['expected_headcount'] as int?) ?? 0,
      actualHeadcount: (map['actual_headcount'] as int?) ?? 0,
      entries: entries,
      status: RecordStatusExtension.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'] as String)
          : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      signatureBase64: map['signature_base64'] as String?,
      signatureHash: map['signature_hash'] as String?,
      integrityHash: map['integrity_hash'] as String?,
      syncError: map['sync_error'] as String?,
    );
  }

  static List<WorkerAttendanceEntry> getRosterForShift(String shift) {
    final normalized = shift.toLowerCase();
    if (normalized.contains('afternoon') || normalized == 'afternoon') {
      return getAfternoonWorkerRoster();
    } else if (normalized.contains('night') || normalized == 'night') {
      return getNightWorkerRoster();
    }
    return getMorningWorkerRoster();
  }

  static List<WorkerAttendanceEntry> getDefaultWorkerRoster([String shift = 'morning']) {
    return getRosterForShift(shift);
  }

  static List<WorkerAttendanceEntry> getMorningWorkerRoster() {
    return [
      WorkerAttendanceEntry(
        workerId: 'WRK-MORN-001',
        workerName: 'Rameshwar Mahato',
        category: 'Continuous Miner Operator',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 3)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-MORN-002',
        workerName: 'Sunil Soren',
        category: 'Shift Crew Leader',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 5)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-MORN-003',
        workerName: 'Bikram Hembram',
        category: 'Timber/Roof Bolting Crew',
        contractorName: 'Bharat Infra Works',
        checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 12)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-MORN-004',
        workerName: 'Dharmendra Yadav',
        category: 'Electrician (Flameproof)',
        contractorName: 'Bharat Infra Works',
        checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 18)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-MORN-005',
        workerName: 'Amitava Banerjee',
        category: 'Haulage & Conveyor Driver',
        contractorName: 'Coalfield Allied Labour',
        checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 22)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-MORN-006',
        workerName: 'Rajesh Kumar Singh',
        category: 'Face Driller & Shotfirer',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 28)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-MORN-007',
        workerName: 'Md. Aslam Ansari',
        category: 'Ventilation Attendant',
        contractorName: 'Coalfield Allied Labour',
        checkInTime: DateTime.now().subtract(const Duration(hours: 3, minutes: 35)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
    ];
  }

  static List<WorkerAttendanceEntry> getAfternoonWorkerRoster() {
    return [
      WorkerAttendanceEntry(
        workerId: 'WRK-AFTN-001',
        workerName: 'Suresh Mohapatra',
        category: 'Heavy Shovel Operator',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 2)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-AFTN-002',
        workerName: 'Gopal Chandra Majhi',
        category: 'Dumper Operator',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 8)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-AFTN-003',
        workerName: 'Pradeep Kumar Nayak',
        category: 'Blasting / Magazine Helper',
        contractorName: 'Bharat Infra Works',
        checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-AFTN-004',
        workerName: 'Manoj Murmu',
        category: 'Support Prop Erector',
        contractorName: 'Coalfield Allied Labour',
        checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-AFTN-005',
        workerName: 'Subhashis Ghosh',
        category: 'Substation Pump Operator',
        contractorName: 'Bharat Infra Works',
        checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-AFTN-006',
        workerName: 'Kaleshwar Besra',
        category: 'Belt Conveyor Inspector',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 35)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
    ];
  }

  static List<WorkerAttendanceEntry> getNightWorkerRoster() {
    return [
      WorkerAttendanceEntry(
        workerId: 'WRK-NGHT-001',
        workerName: 'Dilip Kumar Tudu',
        category: 'Main Ventilation Supervisor',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 1)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-NGHT-002',
        workerName: 'Alok Ranjan Dutta',
        category: 'Night Safety Sirdar',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-NGHT-003',
        workerName: 'Madan Mohan Hansda',
        category: 'Dewatering Pump Attendant',
        contractorName: 'Bharat Infra Works',
        checkInTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 12)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-NGHT-004',
        workerName: 'Ranjit Karmakar',
        category: 'Mechanical Fitter',
        contractorName: 'Coalfield Allied Labour',
        checkInTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
      WorkerAttendanceEntry(
        workerId: 'WRK-NGHT-005',
        workerName: 'Jiten Chandra Mahali',
        category: 'Gas & Fire Sump Patroller',
        contractorName: 'Eastern Mining Services',
        checkInTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
        checkInZone: 'Pit-4 Main Shaft Muster Gate',
      ),
    ];
  }
}

