# MINOVA — Backend & Firestore Verification Audit

This document records the exact audit and verification results across all contract files, DTO mappings, Firestore collections, identity sources, null semantics, security isolation, and testing status.

---

## 1. Contract Files Inspected
- `attendance.json` → **PASS**: Mapped via `AttendanceDto` and `BackendPayloadMapper.dart`.
- `grievances.json` → **PASS**: Mapped via `ObservationDto` and `BackendPayloadMapper.dart`.
- `incidents.json` → **PASS**: Mapped via `IncidentDto` and `BackendPayloadMapper.dart`.
- `inspections.json` → **PASS**: Mapped via `InspectionDto` and `BackendPayloadMapper.dart`.
- `users.json` → **PASS**: Mapped via `UserModel.fromFirestore` and `UserDto`.
- `mines.json` → **PASS**: Reference data verified.
- `contractors.json` → **PASS**: Master reference schema verified.

---

## 2. Firestore Collections Verified
- Attendance submissions → `attendance/{submission_id}` (**PASS**)
- Observation & Grievance submissions → `grievances/{submission_id}` (**PASS**)
- Emergency Incident reports → `incidents/{submission_id}` (**PASS**)
- Safety & Statutory Inspections → `inspections/{submission_id}` (**PASS**)
- Compliance Documents → `documents/{submission_id}` (**PASS**)
- User profiles → `users/{uid}` (**PASS**)
- Mines metadata → `mines/{mine_id}` (**PASS**)

---

## 3. DTOs & Serialization Verified
- `AttendanceDto`: Exact field names (`submission_id`, `mine_id`, `shift`, `worker_id`, `worker_name`, `worker_type`, `contractor_id`, `check_in_time`, `check_in_location`, `check_out_time`, `check_out_location`, `expected_headcount`, `actual_headcount`, `date_time`, `sync_status`).
- `ObservationDto`: Exact field names (`submission_id`, `mine_id`, `inspector_id`, `inspector_name`, `entry_type`, `category`, `text_content`, `photos_or_videos`, `location`, `date_time`, `priority_flagged_by_ai`, `sync_status`, `review_status`).
- `IncidentDto`: Exact field names (`submission_id`, `mine_id`, `inspector_id`, `inspector_name`, `incident_type`, `severity`, `people_affected`, `affected_person_details`, `description`, `immediate_action_taken`, `medical_attention_required`, `equipment_involved`, `photos_or_videos`, `location`, `date_time`, `notify_authority_immediately`, `sync_status`, `review_status`).
- `InspectionDto`: Exact field names (`submission_id`, `mine_id`, `inspector_id`, `inspector_name`, `inspection_type`, `checklist`, `violation_found`, `violation_severity`, `violation_description`, `corrective_action`, `photos_or_videos`, `location`, `date_time`, `sync_status`, `review_status`).

---

## 4. `mine_id` Dynamic Source Verified
- **Flow**: `Firebase Auth UID` → `users/{uid}` → `assignedMineId` / `assignedMineIds` → `Current Inspector Session` → `Report.mineId` → `mine_id` in Firestore.
- **Enforcement**: All 5 repositories (`InspectionRepository`, `IncidentRepository`, `ObservationRepository`, `AttendanceRepository`, `DocumentRepository`) validate that `user.assignedMineId.trim().isNotEmpty` on draft creation; otherwise throws `FormatException`.
- **Status**: **PASS**

---

## 5. Inspector Identity Source Verified
- `inspector_id` & `inspector_name` are derived strictly from authenticated `UserModel` (`user.id` and `user.fullName`), preventing hardcoded names or fixture leaks.
- **Status**: **PASS**

---

## 6. Timestamps & Timezones Verified
- ISO-8601 formatting with standard timezone offset (`+05:30` IST) implemented via `formatContractDateTime(DateTime dt)` in `contract_helpers.dart`.
- **Status**: **PASS**

---

## 7. Location Format Verified
- Converted to `{"latitude": double, "longitude": double}` map or `null`. Internal GPS fields (accuracy, provider) are excluded from cloud transport payload.
- **Status**: **PASS**

---

## 8. Evidence & Media Verified
- Binary image and video media are uploaded to Cloudinary via unsigned upload preset.
- Local SQLite stores full file metadata, while the backend payload attaches external identifiers in `photos_or_videos: List<String>`.
- **Status**: **PASS**

---

## 9. Null Handling & Enum Strings Verified
- String booleans `"yes"` / `"no"` preserved for `violation_found`, `medical_attention_required`, `notify_authority_immediately`.
- Non-violation fields in inspections (`violation_severity`, `violation_description`, `corrective_action`) serialize as `null` when no violation is present.
- `priority_flagged_by_ai` is set to `null` from the mobile client.
- **Status**: **PASS**

---

## 10. Security & Firestore Rules Verified
- `firestore.rules` enforces that signed-in users can only create/update documents belonging to their assigned mine (`mineAssigned(mineId)` check against `users/{uid}.assignedMineIds`) and matching their authenticated `uid`.
- Collections protected: `inspections`, `incidents`, `attendance`, `grievances`, `observations`, `documents`, `correctionRequests`, `users`.
- **Status**: **PASS**

---

## 11. Real Firebase Verification Result
- **Status**: **NOT VERIFIED — REAL FIRESTORE TEST REQUIRED** (Requires active emulator or deployed credentials for real runtime console inspection).

---

## 12. Overall Verification Summary
- Contract Conformance: **PASS**
- Repository Validation: **PASS**
- Local DB & UI Unification: **PASS**
- APK Build: **OMITTED (per user instruction)**
