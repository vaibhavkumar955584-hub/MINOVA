# MINOVA — Firestore Data Model Specification

This document defines the exact Firestore data model, collections, document IDs, field types, nullability, and authoritative sources conforming to the backend JSON contracts.

---

## 1. Collections & Document IDs Overview

| Report / Master Type | Firestore Collection | Document ID Format | Canonical Source |
|---|---|---|---|
| **Shift Attendance** | `attendance` | `ATT-...` (Client UUID) | `attendance.json` |
| **Observation / Grievance** | `grievances` | `OBS-...` / `GRV-...` | `grievances.json` |
| **Emergency Incident** | `incidents` | `INC-...` (Client UUID) | `incidents.json` |
| **Safety Inspection** | `inspections` | `SAF-INSP-...` | `inspections.json` |
| **Compliance Document** | `documents` | `DOC-CMP-...` | `documents` schema |
| **Master Users** | `users` | Firebase Auth `uid` | `users.json` |
| **Master Mines** | `mines` | `mine_id` (e.g. `JH-DHA-BCCL-007`) | `mines.json` |
| **Master Contractors** | `contractors` | `contractor_id` (e.g. `CONT-001`) | `contractors.json` |

---

## 2. Field Specifications by Entity

### 2.1 Attendance (`attendance/{submission_id}`)

| Field Name | Type | Required | Nullable | Source | Notes |
|---|---|---|---|---|---|
| `submission_id` | `string` | Yes | No | Client UUID (`clientUuid`) | Stable UUID; never regenerated on retry |
| `mine_id` | `string` | Yes | No | Logged-in Inspector (`user.assignedMineId`) | Dynamic from authenticated profile |
| `shift` | `string` | Yes | No | User-Selected | e.g. `'morning'`, `'Shift A (06:00 - 14:00)'` |
| `worker_id` | `string` | Yes | No | Roster Entry / Crew Lead | e.g. `'WRK-MUSTER-2'` or authenticated ID |
| `worker_name` | `string` | Yes | No | Roster Entry / Crew Lead | Full Name |
| `worker_type` | `string` | Yes | No | Roster Entry | `'permanent'`, `'contractor'` |
| `contractor_id` | `string?` | No | Yes | Roster Entry | Null for permanent workers |
| `check_in_time` | `string` | Yes | No | Auto-Captured | ISO-8601 with offset (`2024-10-24T06:30:00+05:30`) |
| `check_in_location` | `map` | Yes | No | GPS Telemetry | `{"latitude": double, "longitude": double}` |
| `check_out_time` | `string?` | No | Yes | Check-Out Event | Null at check-in time |
| `check_out_location` | `map?` | No | Yes | GPS Telemetry | Null at check-in time |
| `expected_headcount` | `number` | Yes | No | Roster Schedule | Integer headcount |
| `actual_headcount` | `number` | Yes | No | Present Count | Integer headcount |
| `date_time` | `string` | Yes | No | Submission Timestamp | ISO-8601 with offset |
| `sync_status` | `string` | Yes | No | Sync Engine | `'pending'`, `'synced'`, `'failed'` |

---

### 2.2 Grievance / Observation (`grievances/{submission_id}`)

| Field Name | Type | Required | Nullable | Source | Notes |
|---|---|---|---|---|---|
| `submission_id` | `string` | Yes | No | Client UUID | Stable client UUID (`OBS-LOG-...` / `GRV-...`) |
| `mine_id` | `string` | Yes | No | Logged-in Inspector | Dynamic from authenticated session |
| `inspector_id` | `string` | Yes | No | Authenticated User UID | Dynamic from `users/{uid}` |
| `inspector_name` | `string` | Yes | No | Authenticated Profile | Dynamic from `users/{uid}` |
| `entry_type` | `string` | Yes | No | User-Selected | `'observation'` or `'grievance'` |
| `category` | `string` | Yes | No | User-Selected | `'safety'`, `'environmental'`, `'labour'`, etc. |
| `text_content` | `string` | Yes | No | User-Entered | Unaltered description / voice transcript |
| `photos_or_videos` | `array<string>` | Yes | No | Cloudinary / Evidence | Array of media filenames/identifiers |
| `location` | `map?` | Yes | Yes | GPS Telemetry | `{"latitude": double, "longitude": double}` |
| `date_time` | `string` | Yes | No | Statutory Timestamp | ISO-8601 with offset |
| `priority_flagged_by_ai` | `object?` | No | Yes | Backend / AI worker | Initialized as `null` by mobile client |
| `sync_status` | `string` | Yes | No | Sync Engine | `'pending'`, `'synced'`, `'failed'` |
| `review_status` | `string` | Yes | No | Workflow State | `'pending'`, `'under_review'`, `'resolved'` |

---

### 2.3 Incident (`incidents/{submission_id}`)

| Field Name | Type | Required | Nullable | Source | Notes |
|---|---|---|---|---|---|
| `submission_id` | `string` | Yes | No | Client UUID (`INC-EMG-...`) | Immutable submission ID |
| `mine_id` | `string` | Yes | No | Logged-in Inspector | Dynamic from authenticated session (`user.assignedMineId`) |
| `inspector_id` | `string` | Yes | No | Authenticated User UID | Dynamic from `users/{uid}` |
| `inspector_name` | `string` | Yes | No | Authenticated Profile | Full name from session |
| `incident_type` | `string` | Yes | No | User-Entered | `'injury'`, `'fire'`, `'equipment_failure'`, `'gas_leak'`, `'near_miss'`, `'other'` |
| `severity` | `string` | Yes | No | User-Entered | `'minor'`, `'major'`, `'critical'`, `'fatal'` |
| `people_affected` | `number` | Yes | No | User-Entered | Integer count |
| `affected_person_details`| `array<string>` | Yes | No | User-Entered | Array of worker names/designations (`[]` if 0) |
| `description` | `string` | Yes | No | User-Entered | Full narrative (preserved from inspector) |
| `immediate_action_taken`| `string` | Yes | No | User-Entered | Containment action taken |
| `medical_attention_required` | `string` | Yes | No | User-Entered | String boolean: `"yes"` or `"no"` |
| `equipment_involved` | `string?` | No | Yes | User-Entered | Machinery tag/name (or null) |
| `photos_or_videos` | `array<string>` | Yes | No | Evidence Service | Cloudinary media filenames |
| `location` | `map?` | Yes | Yes | GPS Telemetry | `{"latitude": double, "longitude": double}` |
| `date_time` | `string` | Yes | No | Statutory Timestamp | ISO-8601 with offset (`2024-10-23T10:15:00+05:30`) |
| `notify_authority_immediately` | `string` | Yes | No | Statutory Alert Flag | String boolean: `"yes"` or `"no"` |
| `sync_status` | `string` | Yes | No | Sync Engine | `'pending'`, `'synced'`, `'failed'` |
| `review_status` | `string` | Yes | No | Workflow State | `'under_investigation'`, `'pending'`, `'approved'` |
| `badge_label` | `string` | Yes | No | Derived | e.g. `'CRITICAL HAZARD'`, `'MAJOR HAZARD'` |
| `location_display` | `string` | Yes | No | Metadata | e.g. `'BCCL Pit-7 (Dhanbad) • Seam 4 Junction'` |
| `sync_source` | `string` | Yes | No | Telemetry | `'Synced via Handheld'`, `'Synced via Satellite Link'` |

---

### 2.4 Inspection (`inspections/{submission_id}`)

| Field Name | Type | Required | Nullable | Source | Notes |
|---|---|---|---|---|---|
| `submission_id` | `string` | Yes | No | Client UUID (`SAF-INSP-...`) | Immutable audit ID |
| `mine_id` | `string` | Yes | No | Logged-in Inspector | Dynamic from authenticated session |
| `inspector_id` | `string` | Yes | No | Authenticated User UID | Dynamic from `users/{uid}` |
| `inspector_name` | `string` | Yes | No | Authenticated Profile | Full name from session |
| `inspection_type` | `string` | Yes | No | User-Selected | `'safety'`, `'environmental'`, `'production'`, `'labour'` |
| `checklist` | `array<map>` | Yes | No | Checklist Items | `[{"question": string, "answer": "pass"\|"fail"\|"not_applicable", "remarks": string?}]` |
| `violation_found` | `string` | Yes | No | Computed | String boolean: `"yes"` if any fail, else `"no"` |
| `violation_severity` | `string?` | No | Yes | Highest Failed Item | `'minor'`, `'major'`, `'critical'` (null if no violation) |
| `violation_description` | `string?` | No | Yes | Failed Item Notes | Joined description (null if no violation) |
| `corrective_action` | `string?` | No | Yes | Corrective Orders | Joined action orders (null if no violation) |
| `photos_or_videos` | `array<string>` | Yes | No | Evidence Service | Media filenames |
| `location` | `map?` | Yes | Yes | GPS Telemetry | `{"latitude": double, "longitude": double}` |
| `date_time` | `string` | Yes | No | Statutory Timestamp | ISO-8601 with offset |
| `sync_status` | `string` | Yes | No | Sync Engine | `'pending'`, `'synced'`, `'failed'` |
| `review_status` | `string` | Yes | No | Workflow State | `'submitted'`, `'under_review'` |
