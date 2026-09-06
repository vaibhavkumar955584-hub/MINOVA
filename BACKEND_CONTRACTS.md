# Backend Data Contracts & DTO Mapping Specification

This document defines the exact transport integration contract between the MineSafe (MINOVA) Flutter mobile application and the cloud/backend services.

---

## 1. Architectural Boundary

```
MOBILE DOMAIN MODEL
        ↓
LOCAL DATABASE (SQLite)
        ↓
DTO / SERIALIZATION LAYER (lib/data/dto/)
        ↓
EXACT BACKEND JSON CONTRACT
        ↓
FIREBASE / REST BACKEND
```

- **Domain Models** (`lib/models/`): Clean Dart models with type-safe enums and mobile-specific metadata.
- **Local DB** (`AppDatabase`): Local persistence tables with statutory locks, hashes, and sync flags.
- **DTO Layer** (`lib/data/dto/`): Explicit boundary supporting `fromJson()`, `toJson()`, `fromDomain()`, and `toDomain()`.
- **Backend JSON**: Strict adherence to backend naming (`snake_case`), string booleans (`"yes"`/`"no"`), ISO-8601 UTC timestamps, and nested location objects.

---

## 2. Entity Contracts & Field Specifications

### 2.1 Inspection (`InspectionDto` / `inspections.json`)
| Field | Type | Required | Nullable | Source Classification | Description |
|---|---|---|---|---|---|
| `submission_id` | String | Yes | No | Mobile-Generated | Unique statutory submission ID (`clientUuid`) |
| `mine_id` | String | Yes | No | Master Reference | Assigned mine ID (e.g., `mine_jharsuguda_01`) |
| `inspector_id` | String | Yes | No | Mobile-Captured | Authenticated Inspector User ID |
| `inspector_name` | String | Yes | No | Mobile-Captured | Inspector Full Name |
| `inspection_type` | String | Yes | No | User-Entered | `safety`, `environmental`, `production`, `labour` |
| `checklist` | Array<Object> | Yes | No | User-Entered | List of checklist questions, answers (`pass`/`fail`/`not_applicable`), and remarks |
| `violation_found` | String | Yes | No | Mobile-Computed | `"yes"` if any item failed; otherwise `"no"` |
| `violation_severity` | String? | Conditional | Yes | Mobile-Computed | `minor`, `major`, `critical` (null if no violation) |
| `violation_description` | String? | Conditional | Yes | User-Entered | Description of failures (null if no violation) |
| `corrective_action` | String? | Conditional | Yes | User-Entered | Corrective order issued (null if no violation) |
| `photos_or_videos` | Array<String> | Yes | No | Mobile-Captured | Array of media filenames/Cloudinary IDs |
| `location` | Object? | Yes | Yes | Auto-Captured (GPS) | `{ "latitude": double, "longitude": double }` |
| `date_time` | String (ISO-8601) | Yes | No | Mobile-Generated | Statutory timestamp of submission |
| `sync_status` | String | Yes | No | Mobile-Generated | `synced`, `pending_sync`, `failed` |
| `review_status` | String | Yes | No | Mobile/Backend | `submitted`, `under_review`, `approved` |

---

### 2.2 Attendance (`AttendanceDto` / `attendance.json`)
| Field | Type | Required | Nullable | Source Classification | Description |
|---|---|---|---|---|---|
| `submission_id` | String | Yes | No | Mobile-Generated | Statutory roster UUID |
| `mine_id` | String | Yes | No | Master Reference | Assigned mine ID |
| `shift` | String | Yes | No | User-Entered | `Morning Shift A`, `General Shift`, etc. |
| `worker_id` | String | Yes | No | Master Reference | Worker Employee/Biometric ID |
| `worker_name` | String | Yes | No | Master Reference | Worker Full Name |
| `worker_type` | String | Yes | No | Master Reference | `contractor`, `permanent`, etc. |
| `contractor_id` | String? | Optional | Yes | Master Reference | Contractor ID if contractor worker |
| `check_in_time` | String (ISO-8601) | Yes | No | Auto-Captured | Timestamp of check-in |
| `check_in_location` | Object | Yes | No | Auto-Captured (GPS) | `{ "latitude": double, "longitude": double }` |
| `check_out_time` | String? (ISO-8601) | Optional | Yes | Auto-Captured | Timestamp of check-out (null on check-in) |
| `check_out_location` | Object? | Optional | Yes | Auto-Captured (GPS) | Location at check-out (null on check-in) |
| `expected_headcount` | Integer | Yes | No | Master Reference | Scheduled muster count |
| `actual_headcount` | Integer | Yes | No | Mobile-Computed | Count of physically present workers |
| `date_time` | String (ISO-8601) | Yes | No | Mobile-Generated | Roster submission timestamp |
| `sync_status` | String | Yes | No | Mobile-Generated | `synced`, `pending_sync` |

---

### 2.3 Incident (`IncidentDto` / `incidents.json`)
| Field | Type | Required | Nullable | Source Classification | Description |
|---|---|---|---|---|---|
| `submission_id` | String | Yes | No | Mobile-Generated | Incident report UUID |
| `mine_id` | String | Yes | No | Master Reference | Assigned mine ID |
| `inspector_id` | String | Yes | No | Mobile-Captured | Reporting official's UID |
| `inspector_name` | String | Yes | No | Mobile-Captured | Reporting official's name |
| `incident_type` | String | Yes | No | User-Entered | `injury`, `equipment_failure`, `near_miss`, `fire`, `gas_leak`, `other` |
| `severity` | String | Yes | No | User-Entered | `minor`, `major`, `critical` |
| `people_affected` | Integer | Yes | No | User-Entered | Number of affected personnel |
| `affected_person_details`| String? | Optional | Yes | User-Entered | Names/IDs of affected workers |
| `description` | String | Yes | No | User-Entered | Detailed narrative of incident |
| `immediate_action_taken`| String | Yes | No | User-Entered | First response & containment action |
| `medical_attention_required` | String | Yes | No | User-Entered | `"yes"` or `"no"` |
| `equipment_involved` | String? | Optional | Yes | User-Entered | Tag/Name of involved machinery |
| `photos_or_videos` | Array<String> | Yes | No | Mobile-Captured | Array of media filenames/Cloudinary IDs |
| `location` | Object? | Yes | Yes | Auto-Captured (GPS) | `{ "latitude": double, "longitude": double }` |
| `date_time` | String (ISO-8601) | Yes | No | Mobile-Generated | Incident logging timestamp |
| `notify_authority_immediately` | String | Yes | No | User-Entered | `"yes"` or `"no"` |
| `sync_status` | String | Yes | No | Mobile-Generated | `synced`, `pending_sync` |
| `review_status` | String | Yes | No | Mobile/Backend | `submitted`, `under_review` |

---

### 2.4 Observation & Grievance (`ObservationDto` / `grievances.json`)
| Field | Type | Required | Nullable | Source Classification | Description |
|---|---|---|---|---|---|
| `submission_id` | String | Yes | No | Mobile-Generated | Observation UUID |
| `mine_id` | String | Yes | No | Master Reference | Assigned mine ID |
| `inspector_id` | String | Yes | No | Mobile-Captured | Submitting user ID |
| `inspector_name` | String | Yes | No | Mobile-Captured | Submitting user name |
| `entry_type` | String | Yes | No | User-Entered | `observation` or `grievance` |
| `category` | String | Yes | No | User-Entered | `safety`, `environmental`, `labour`, `gasReading`, `other` |
| `text_content` | String | Yes | No | User-Entered | Unaltered worker/inspector statement |
| `photos_or_videos` | Array<String> | Yes | No | Mobile-Captured | Evidence media filenames |
| `location` | Object? | Yes | Yes | Auto-Captured (GPS) | `{ "latitude": double, "longitude": double }` |
| `date_time` | String (ISO-8601) | Yes | No | Mobile-Generated | Record timestamp |
| `priority_flagged_by_ai`| Object? | No | Yes | Backend/AI-Derived | Set to `null` by mobile; evaluated on server |
| `sync_status` | String | Yes | No | Mobile-Generated | `synced`, `pending_sync` |
| `review_status` | String | Yes | No | Mobile/Backend | `submitted`, `under_review` |

---

### 2.5 Compliance Document (`DocumentDto`)
| Field | Type | Required | Nullable | Source Classification | Description |
|---|---|---|---|---|---|
| `submission_id` | String | Yes | No | Mobile-Generated | Document record UUID |
| `mine_id` | String | Yes | No | Master Reference | Associated mine ID |
| `user_id` | String | Yes | No | Mobile-Captured | Uploading user ID |
| `user_name` | String | Yes | No | Mobile-Captured | Uploading user name |
| `category` | String | Yes | No | User-Entered | `contractorLicense`, `statutoryCertificate`, etc. |
| `title` | String | Yes | No | User-Entered | Document Title |
| `document_number` | String? | Optional | Yes | User-Entered | Statutory license/certificate number |
| `associated_contractor` | String? | Optional | Yes | User-Entered | Contractor company name |
| `expiry_date` | String? (ISO-8601) | Optional | Yes | User-Entered | Expiration date of certificate |
| `remarks` | String? | Optional | Yes | User-Entered | Notes/Conditions |
| `files` | Array<String> | Yes | No | Mobile-Captured | Attached file names / Cloudinary IDs |
| `date_time` | String (ISO-8601) | Yes | No | Mobile-Generated | Submission timestamp |
| `sync_status` | String | Yes | No | Mobile-Generated | `synced`, `pending_sync` |
| `review_status` | String | Yes | No | Mobile/Backend | `submitted`, `under_review` |

---

### 2.6 Contractor Master Data (`ContractorDto` / `contractors.json`)
| Field | Type | Description |
|---|---|---|
| `contractor_id` | String | Unique contractor ID (`CONT-001`) |
| `company_name` | String | Registered company name |
| `license_validity` | Object? | Expiration date / status |
| `insurance_status` | Object? | Active policy status |
| `compliance_documents` | Object? | Array of uploaded statutory certificate references |
| `document_expiry_dates` | Object? | Key-value mapping of document expiry dates |
| `equipment_inspection_certificates` | Object? | Machinery fitness certificates |

---

### 2.7 Mine Master Data (`MineDto` / `mines.json`)
| Field | Type | Description |
|---|---|---|
| `mine_id` | String | Mine identifier (`mine_jharsuguda_01`) |
| `mine_name` | String | Official mine name (`Jharsuguda Mine (Pit-4)`) |
| `coalfield` | Object? | Coalfield region (e.g., `Ib Valley`) |
| `state` | String | State (e.g., `Odisha`) |
| `district` | Object? | District |
| `operator` | Object? | Mining operator (e.g., `MCL / CIL`) |
| `status` | Object? | `active`, `suspended`, `maintenance` |
| `location` | Object? | Lat/Lng coordinates or textual location |
| `methane_level` | Object? | Atmospheric methane telemetry |
| `gas_breach` | Object? | Gas breach status flag |
| `risk_level` | Object? | Current composite hazard risk level |
| `inspector_in_charge` | Object? | Assigned DGMS Inspector UID |

---

### 2.8 User Master Data (`UserDto` / `users.json`)
| Field | Type | Description |
|---|---|---|
| `user_id` | String | Unique user ID / Firebase Auth UID |
| `full_name` | String | User's full name |
| `designation` | String | Statutory designation |
| `role` | String | `inspector`, `mine_official`, `contractor` |
| `employee_id_or_contractor_id` | String | Statutory Employee ID (e.g. `DGMS-INSP-404`) |
| `mine_assigned` | String | Primary assigned mine ID |
| `preferred_language` | String | `en`, `hi`, `or`, etc. |
| `email` | String? | User email address |
| `date_time_registered` | String? (ISO-8601) | Registration timestamp |

---

## 3. Strict Serialization & Transport Rules

1. **Boolean Normalization**:
   - `violation_found`: `"yes"` / `"no"` (never boolean `true`/`false`).
   - `medical_attention_required`: `"yes"` / `"no"`.
   - `notify_authority_immediately`: `"yes"` / `"no"`.

2. **Null Semantics**:
   - If `violation_found == "no"`, `violation_severity`, `violation_description`, and `corrective_action` are `null`.
   - Optional fields not supplied are serialized as `null` rather than empty strings or zeros.

3. **Timestamps**:
   - Strictly ISO-8601 UTC strings formatted via `DateTime.toIso8601String()`.

4. **Location Format**:
   - Serialized as `{ "latitude": double, "longitude": double }`.

5. **Evidence Filtering**:
   - Mobile-internal metadata (`localPath`, `integrityHash`, `retryCount`, `uploadAttempts`) is filtered out at the DTO boundary.
   - `photos_or_videos` contains only the external media filenames/Cloudinary identifiers. Rich metadata is preserved locally in SQLite.

6. **AI Derived Fields**:
   - `priority_flagged_by_ai` is always sent as `null` from the mobile client and populated by backend inference workers.
