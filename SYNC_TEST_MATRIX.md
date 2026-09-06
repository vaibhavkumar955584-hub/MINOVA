# MinSafe Synchronization Test Matrix

## 1. Automated Test Suites

| Test File | Focus Area | Key Assertions |
|---|---|---|
| `test/universal_sync_test.dart` | Universal Serialization & Lifecycle | - Canonical collections (`attendance`, `incidents`, `grievances`, `inspections`, `documents`)<br>- DTO mapping across all 5 report types<br>- In-flight concurrency lock preventing duplicate syncs<br>- Queue isolation preventing cross-record failure cascades |
| `test/sync_queue_test.dart` | Sync Queue Model & Lifecycle | - Canonical enum representation (`attendance`, `incident`, `observation`, `inspection`, `document`)<br>- State transitions: `draft` -> `submitted_local` -> `waiting_sync` -> `syncing` -> `synced` / `failed`<br>- Non-retryable classification tracking (`is_retryable = 0`) |
| `test/sync_retry_test.dart` | Retry Policy & Exponential Backoff | - Bounded exponential delay math (5s, 10s, 20s, 40s, 80s)<br>- `SyncQueueItem` serialization roundtrip with `error_stage`, `error_code`, `is_retryable`, `next_retry_at`<br>- Permission-denied non-retryable classification |
| `test/evidence_sync_test.dart` | Granular Media & Evidence Recovery | - Stable `evidence_id` and SHA-256 integrity<br>- Partial upload skipping of already-uploaded media items<br>- DTO hydration with remote Cloudinary URLs without binary data |
| `test/backend_dto_test.dart` | Backend DTO Contract Compliance | - Strict JSON field mapping for Attendance, Incident (21 statutory fields), Observation, Inspection, Document |
| `test/report_contract_verification_test.dart` | End-to-End Contract Verification | - Statutory validation rules, conditional violation fields, OCR mapping |

---

## 2. Manual & Device Test Scenarios

| Scenario | Target Entity | Action | Expected Result |
|---|---|---|---|
| **Manual Sync Trigger** | Incident Report | Tap "SYNC NOW" on Record Detail | UI enters `syncing` state with spinner, calls `syncReport(force: true)`, updates to `synced` (or displays specific error). |
| **Duplicate Sync Attempt** | Attendance Record | Rapid double tap "SYNC NOW" | In-flight lock rejects second call; only one network pipeline execution occurs. |
| **Offline Queue Recovery** | Observation / Grievance | Submit in airplane mode -> Reconnect WiFi | Connectivity listener detects network restored -> triggers `processQueue()` -> syncs pending items. |
| **App Restart Recovery** | Safety Inspection | Submit in airplane mode -> Kill app -> Launch app | SQLite persists `sync_queue` table with status `pending`; engine resumes queue processing upon initialization. |
| **Permission Denied Handling** | Compliance Document | Sync document for unauthorized mine ID | Firestore returns `permission-denied` -> engine classifies as non-retryable -> UI displays "Mine authorization mismatch or Firestore permission denied." without looping. |
