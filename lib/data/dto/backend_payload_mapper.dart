import '../../models/attendance_model.dart';
import '../../models/document_model.dart';
import '../../models/evidence_model.dart';
import '../../models/incident_model.dart';
import '../../models/inspection_model.dart';
import '../../models/observation_model.dart';
import '../../models/sync_item_model.dart';
import 'attendance_dto.dart';
import 'contract_helpers.dart';
import 'document_dto.dart';
import 'incident_dto.dart';
import 'inspection_dto.dart';
import 'observation_dto.dart';

/// The single report-to-contract boundary used by sync. SQLite rows never go
/// directly to Firestore/the backend contract.
class BackendPayloadMapper {
  const BackendPayloadMapper._();

  static Map<String, dynamic> fromLocalReport({
    required SyncRecordType type,
    required Map<String, dynamic> report,
    required List<EvidenceItem> uploadedEvidence,
  }) {
    switch (type) {
      case SyncRecordType.inspection:
        final value = InspectionReport.fromDbMap(report);
        value.globalEvidence = _hydrate(value.globalEvidence, uploadedEvidence);
        for (final item in value.checklist) {
          item.evidence = _hydrate(item.evidence, uploadedEvidence);
        }
        return InspectionDto.fromDomain(value).toJson();
      case SyncRecordType.incident:
        final value = IncidentReport.fromDbMap(report);
        value.evidence = _hydrate(value.evidence, uploadedEvidence);
        return IncidentDto.fromDomain(value).toJson();
      case SyncRecordType.observation:
        final value = ObservationRecord.fromDbMap(report);
        value.evidence = _hydrate(value.evidence, uploadedEvidence);
        return ObservationDto.fromDomain(value).toJson();
      case SyncRecordType.attendance:
        final value = AttendanceReport.fromDbMap(report);
        final firstEntry = value.entries.isNotEmpty
            ? value.entries.first
            : WorkerAttendanceEntry(
                workerId: value.userId,
                workerName: value.userName,
                category: 'permanent',
                contractorName: '',
                checkInTime: value.createdAt,
              );
        return AttendanceDto(
          submissionId: value.clientUuid,
          mineId: value.mineId,
          shift: value.shiftName,
          workerId: firstEntry.workerId,
          workerName: firstEntry.workerName,
          workerType: firstEntry.category,
          contractorId: firstEntry.contractorName.isNotEmpty ? firstEntry.contractorName : null,
          checkInTime: firstEntry.checkInTime,
          checkInLocation: const {'latitude': 23.7912, 'longitude': 86.4319},
          checkOutTime: firstEntry.checkOutTime,
          checkOutLocation: null,
          expectedHeadcount: value.expectedHeadcount,
          actualHeadcount: value.actualHeadcount,
          dateTime: value.submittedAt ?? value.createdAt,
          syncStatus: backendSyncStatus(value.status),
        ).toJson();
      case SyncRecordType.document:
        final value = ComplianceDocument.fromDbMap(report);
        final hydrated = ComplianceDocument(
          clientUuid: value.clientUuid,
          serverId: value.serverId,
          mineId: value.mineId,
          mineName: value.mineName,
          userId: value.userId,
          userName: value.userName,
          category: value.category,
          title: value.title,
          documentNumber: value.documentNumber,
          associatedContractor: value.associatedContractor,
          expiryDate: value.expiryDate,
          remarks: value.remarks,
          status: value.status,
          createdAt: value.createdAt,
          submittedAt: value.submittedAt,
          updatedAt: value.updatedAt,
          files: _hydrate(value.files, uploadedEvidence),
          integrityHash: value.integrityHash,
          syncError: value.syncError,
        );
        return DocumentDto.fromDomain(hydrated).toJson();
      case SyncRecordType.correctionRequest:
        // Internal correction request record.
        return _legacyFirestorePayload(report, uploadedEvidence);
    }
  }

  static List<EvidenceItem> _hydrate(
    List<EvidenceItem> recordEvidence,
    List<EvidenceItem> uploadedEvidence,
  ) {
    final byId = {for (final item in uploadedEvidence) item.id: item};
    return recordEvidence.map((item) => byId[item.id] ?? item).toList();
  }

  static Map<String, dynamic> _legacyFirestorePayload(
    Map<String, dynamic> report,
    List<EvidenceItem> evidence,
  ) {
    final payload = Map<String, dynamic>.from(report)
      ..remove('files_json')
      ..remove('evidence_json')
      ..remove('global_evidence_json')
      ..remove('signature_base64')
      ..remove('signature_hash')
      ..remove('integrity_hash')
      ..remove('sync_error');
    payload['evidence'] = evidence.map((item) => item.toFirestoreMap()).toList();
    return payload;
  }
}
