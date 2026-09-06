# MinSafe Universal Offline-First Synchronization Architecture

## 1. Architectural Overview

MinSafe utilizes a single, generic offline-first synchronization engine across all five statutory and operational report types:
1. **Attendance** (`attendance`)
2. **Incident** (`incidents`)
3. **Observation / Grievance** (`grievances`)
4. **Safety Inspection** (`inspections`)
5. **Compliance Document** (`documents`)

```
               [ User Input / Capture ]
                          │
                          ▼
           [ Local Database (SQLite: minesafe.db) ]
           - Status: DRAFT / SUBMITTED_LOCAL
                          │
                          ▼
             [ Generic Sync Queue ]
             - sync_queue table
             - submission_id, record_type, error_stage, is_retryable
                          │
                          ▼
          [ Universal Sync Orchestrator ]
           (lib/core/sync/sync_engine.dart)
          ┌────────────────────────────────────────┐
          │ 1. Concurrency Lock (by submission_id) │
          │ 2. Local Record & Ownership Validation │
          │ 3. Granular Media Upload (Cloudinary)  │
          │    (Skips already uploaded media)      │
          │ 4. Typed DTO Boundary Serialization    │
          │    (BackendPayloadMapper)              │
          │ 5. Canonical Firestore Write           │
          │ 6. Backend API Ingestion (if active)   │
          │ 7. Final State Mark: SYNCED            │
          └────────────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        ▼                                   ▼
 [ SUCCESS ]                         [ FAILURE ]
 - Mark Local Record SYNCED          - Classify: PERMISSION_DENIED / TIMEOUT
 - Mark SyncQueue SYNCED             - Set: is_retryable, error_stage, error_code
 - Release In-flight Lock            - Calculate Exponential Backoff (if retryable)
                                     - Release In-flight Lock
```

---

## 2. Generic Sync Pipeline Steps

Every report undergoes the uniform 10-step generic synchronization sequence:

1. **Load Local Record**: Query SQLite via `_loadReport(clientUuid, type)`.
2. **Validate Record Exists & Verify Ownership**: Confirm record is present and mine authorization (`mineId`, `inspectorId`) matches authenticated user.
3. **Load Associated Evidence**: Query `evidence` table for all media attached to `clientUuid`.
4. **Upload Pending Evidence**: Granularly upload un-uploaded media items to Cloudinary. Persist `downloadUrl` and `uploadStatus = 'uploaded'` immediately.
5. **Build Typed Report DTO**: Delegate serialization to `BackendPayloadMapper.fromLocalReport(...)` with hydrated evidence URLs.
6. **Validate DTO**: Ensure payload satisfies statutory contract constraints (e.g. 21-field incident contract).
7. **Write Canonical Firestore Representation**: Write document to canonical collection (`attendance`, `incidents`, `grievances`, `inspections`, `documents`) using stable `submission_id`.
8. **Ingest to Central Backend**: POST sanitized JSON payload to central server if API endpoint is configured.
9. **Confirm Required Operations**: Ensure all required stages succeeded without partial unhandled exceptions.
10. **Mark Local Record Synced**: Transition SQLite status to `RecordStatus.synced` and queue status to `SyncStatus.synced`.

---

## 3. Canonical Collection & DTO Mapping

| Report Type | Canonical Collection | DTO Boundary | Evidence Hydration |
|---|---|---|---|
| Attendance | `attendance` | `AttendanceDto` | N/A |
| Incident | `incidents` | `IncidentDto` | Yes (`evidence` array with `url`, `id`, `sha256`) |
| Observation / Grievance | `grievances` | `ObservationDto` | Yes (`evidence_urls`) |
| Safety Inspection | `inspections` | `InspectionDto` | Yes (`checklist` photos & general evidence) |
| Compliance Document | `documents` | `DocumentDto` | Yes (`file_url`, OCR metadata) |

---

## 4. Concurrency Locking & Idempotency

- **In-Flight Lock**: `SyncEngine._inFlightSubmissionIds` retains active `submission_id` tokens. Simultaneous requests (e.g. user pressing "SYNC NOW" while connectivity listener or background worker triggers) are safely deduplicated.
- **Stable Identifiers**: `clientUuid` acts as the single invariant `submission_id` across local database, Cloudinary public ID tags, Firestore document path, and backend payloads. It is never regenerated on retry.
- **Media Idempotency**: Files marked `uploaded` with non-null `downloadUrl` are skipped on subsequent retry cycles.
