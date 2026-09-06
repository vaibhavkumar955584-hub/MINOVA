# SYNC FAILURE & VERIFICATION MATRIX

## 1. Initial Failure Matrix (Before Root Cause Fix)

| Report Type | Target Collection | Write Attempt | Initial Result | Error Code | Error Stage | Root Cause |
|---|---|---|---|---|---|---|
| **Attendance** | `attendance/{id}` | Direct Firestore set | FAILED | `PERMISSION_DENIED` | Firestore Security Rule Check | `inspector_id` was `'usr_priya_02'` != `auth.uid` AND `/users/{uid}` missing |
| **Incident** | `incidents/{id}` | Direct Firestore set | FAILED | `PERMISSION_DENIED` | Firestore Security Rule Check | `inspector_id` mismatch + unseeded `assignedMineIds` |
| **Observation** | `grievances/{id}` | Direct Firestore set | FAILED | `PERMISSION_DENIED` | Firestore Security Rule Check | `inspector_id` mismatch + unseeded `assignedMineIds` |
| **Inspection** | `inspections/{id}` | Direct Firestore set | FAILED | `PERMISSION_DENIED` | Firestore Security Rule Check | `inspector_id` mismatch + unseeded `assignedMineIds` |
| **Document** | `documents/{id}` | Direct Firestore set | FAILED | `PERMISSION_DENIED` | Firestore Security Rule Check | `user_id` mismatch + unseeded `assignedMineIds` |

---

## 2. Post-Fix Verification Matrix (Universal Auth Context & Rule Matching)

| Report Type | Target Collection | Write Attempt | Resolved Result | Error Code | Error Stage | Verification Mechanism |
|---|---|---|---|---|---|---|
| **Attendance** | `attendance/{id}` | Universal `SyncEngine` Sync | **SUCCESS** | None | Firestore Commit | Unit test + Runtime alignment |
| **Incident** | `incidents/{id}` | Universal `SyncEngine` Sync | **SUCCESS** | None | Firestore Commit | Unit test + Schema compliance |
| **Observation** | `grievances/{id}` | Universal `SyncEngine` Sync | **SUCCESS** | None | Firestore Commit | Unit test + Rule matching |
| **Inspection** | `inspections/{id}` | Universal `SyncEngine` Sync | **SUCCESS** | None | Firestore Commit | Unit test + Rule matching |
| **Document** | `documents/{id}` | Universal `SyncEngine` Sync | **SUCCESS** | None | Firestore Commit | Unit test + Rule matching |
| **Wrong Mine** | `incidents/{id}` | Mine ID not in `assignedMineIds` | **DENIED** | `PERMISSION_DENIED` | Firestore Security Rule Check | Security test verified |
| **Wrong Inspector** | `incidents/{id}` | `inspector_id` != `auth.uid` | **DENIED** | `PERMISSION_DENIED` | Firestore Security Rule Check | Security test verified |
| **Unauthenticated** | `incidents/{id}` | `request.auth == null` | **DENIED** | `PERMISSION_DENIED` | Firestore Security Rule Check | Security test verified |
