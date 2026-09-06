import '../../models/evidence_model.dart';
import '../../models/inspection_model.dart';

Map<String, dynamic>? locationJson(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return null;
  return {'latitude': latitude, 'longitude': longitude};
}

String? externalEvidenceValue(EvidenceItem evidence) {
  // Use remote Cloudinary/storage URL when available, falling back to fileName.
  return evidence.downloadUrl ?? evidence.fileName;
}

String backendSyncStatus(RecordStatus status) {
  switch (status) {
    case RecordStatus.synced:
      return 'synced';
    case RecordStatus.syncFailed:
      return 'failed';
    case RecordStatus.draft:
    case RecordStatus.pendingSync:
    case RecordStatus.syncing:
    case RecordStatus.underReview:
    case RecordStatus.resolved:
      return 'pending';
  }
}

DateTime? parseDateTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// Formats date_time with ISO-8601 string and standard timezone offset (+05:30 IST)
/// matching backend desktop and contract requirements.
/// Example output: "2024-10-24T11:20:45+05:30"
String formatContractDateTime(DateTime dt) {
  if (dt.isUtc) {
    return dt.toIso8601String();
  }
  final offset = dt.timeZoneOffset;
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final sign = offset.isNegative ? '-' : '+';
  
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  
  final tzString = (offset.inMinutes == 0) ? '+05:30' : '$sign$hours:$minutes';
  return '$y-$m-${d}T$h:$min:$s$tzString';
}
