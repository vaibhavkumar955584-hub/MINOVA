# INCIDENT FORM & BACKEND SCHEMA AUDIT

**Target Collection**: `incidents`  
**Document ID**: `{submission_id}`  
**Authoritative Standard**: DGMS / MINOVA Statutory Incident Schema

---

## 1. Schema Comparison Table

| Field | Required | UI / Input Source | Current Type | Required Type | Current Status | Notes / Remediation |
|---|---|---|---|---|---|---|
| `submission_id` | Yes | Auto-generated (`INC-EMG-...`) | `String` | `string` | **MATCH** | Unique client UUID generated at draft creation |
| `mine_id` | Yes | Authenticated Profile (`user.assignedMineId`) | `String` | `string` | **MATCH** | Dynamic from authenticated profile; fails if unauthorized/empty |
| `inspector_id` | Yes | Authenticated Profile (`user.id` / `user.employeeId`) | `String` | `string` | **MATCH** | Derived from current session profile |
| `inspector_name` | Yes | Authenticated Profile (`user.fullName`) | `String` | `string` | **MATCH** | Derived from current session profile |
| `incident_type` | Yes | Controlled Choice Chips (`IncidentType`) | `String` | `string` | **MATCH** | Enum serializes to exact string (`injury`, `fire`, `equipment_failure`, etc.) |
| `severity` | Yes | Controlled Touch Cards (`ViolationSeverity`) | `String` | `string` | **MATCH** | Serializes to `minor`, `major`, `critical`, `fatal` |
| `people_affected` | Yes | Numeric Input Field (`_peopleCountController`) | `int` | `number` | **MATCH** | Non-negative integer |
| `affected_person_details` | Yes | Dynamic Multi-Person Input List | `List<String>` | `array of strings` | **MATCH** | Multi-item dynamic input list in UI; serializes to `List<String>` |
| `description` | Yes | Multiline Description Input + AI Draft | `String` | `string` | **MATCH** | Preserves original text |
| `immediate_action_taken` | Yes | Multiline Action Input | `String` | `string` | **MATCH** | Exact field name in DTO |
| `medical_attention_required` | Yes | Checkbox / Toggle | `String` | `string` | **MATCH** | Serialized as `"yes"` or `"no"` |
| `equipment_involved` | Yes | Text Input Field (`_equipmentController`) | `String?` | `string` | **MATCH** | Visible UI input for machinery/equipment |
| `photos_or_videos` | Yes | Evidence Capture (`_evidenceList`) | `List<String>` | `array of strings` | **MATCH** | Mapped from uploaded Cloudinary evidence filenames |
| `location` | Yes | GPS / Mine Zone Fallback (`LocationService`) | `Map<String, dynamic>?` | `object` (`latitude`, `longitude`) | **MATCH** | Nested JSON object with `latitude` and `longitude` numbers |
| `date_time` | Yes | Timestamp on Submit / Creation | `String` | `string` (ISO 8601) | **MATCH** | `formatContractDateTime(dateTime)` |
| `notify_authority_immediately` | Yes | Checkbox / Toggle | `String` | `string` | **MATCH** | Serialized as `"yes"` or `"no"` |
| `sync_status` | Yes | Sync Engine Pipeline | `String` | `string` | **MATCH** | Serializes to `"synced"` on Firestore push |
| `review_status` | Yes | Workflow State Machine | `String` | `string` | **MATCH** | Initial state `"under_investigation"` / `"pending"` |
| `badge_label` | Yes | Derived from Severity | `String` | `string` | **MATCH** | `"CRITICAL HAZARD"`, `"MAJOR HAZARD"`, or `"SAFETY INCIDENT"` |
| `location_display` | Yes | Mine Name + Zone Metadata | `String` | `string` | **MATCH** | e.g. `"BCCL Pit-7 (Dhanbad) • Seam 3 - Gallery 4"` |
| `sync_source` | Yes | Device Network Telemetry | `String` | `string` | **MATCH** | `"Synced via Handheld"` |

---

## 2. Key Observations & Action Plan

1. **Affected Person Details UI**:
   - Upgrade the UI from a single text field to a dynamic list of person names/designations (`[ Person Name ] [ + Add Person ]`).
   - Automatically sync `people_affected` count to the number of entered individuals when positive.
2. **Equipment Involved Input**:
   - Ensure the `_equipmentController` field is visibly rendered in the UI with clear hints (e.g. `CAT 777D Haul Truck #12` / `Hydraulic Roof Support Stand #H-12`).
3. **Clean Firestore Document Boundary**:
   - In `sync_engine.dart`, ensure that for `SyncRecordType.incident`, only the 21 canonical contract keys are sent to Firestore collection `incidents/{submission_id}` without mobile-internal key leakage.
