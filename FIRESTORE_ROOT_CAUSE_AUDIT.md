# FIRESTORE ROOT CAUSE AUDIT: PERMISSION_DENIED

## 1. Forensic Summary
- **Observed Behavior**:
  - Live logs showed `users/{firebaseUid} → PERMISSION_DENIED` and `attendance/{submission_id} → PERMISSION_DENIED`, `incidents/{submission_id} → PERMISSION_DENIED`.
  - Cloudinary image uploads succeeded consistently.
- **Root Cause**:
  1. **Unauthorized Profile Mutation**:
     The mobile app's `SyncEngine` was attempting to execute `usersCol.doc(uid).set(data, SetOptions(merge: true))` with `assignedMineIds`, `role`, and `accountStatus` fields during normal report sync. Firestore security rules on `users/{uid}` explicitly disallow non-manager mobile clients from modifying their own roles or mine assignments (`allow update: if request.resource.data.diff(resource.data).affectedKeys().hasOnly(['email', ...])`), resulting in `PERMISSION_DENIED`.
  2. **Rule Schema & Identity Mismatch**:
     `canCreateReport()` in `firestore.rules` required exact equality between author fields and `request.auth.uid`. Certain DTO payloads (such as Attendance) did not supply `inspector_id` or used `worker_id` (the checked-in worker's ID), causing `canCreateReport()` to evaluate to false.
  3. **Lack of Pre-Flight Authorization Gate**:
     The sync engine did not validate that the user had an active, authenticated session with a verified active profile document and authorized mine before queueing Firestore writes.

## 2. Component Audits

| Component | Audit Result | Action Taken |
|---|---|---|
| **`firestore.rules`** | Users collection write rules blocked mobile sync. Report creation rules had overly restrictive field dependencies. | Hardened `users/{uid}` to read-only for inspectors (`allow create, update, delete: if false;`). Made `mineAssigned()` check array/string variants and `accountStatus == 'active'`. |
| **`SyncEngine`** | Attempted profile provisioning during report synchronization. | Completely removed all `users/{uid}` write/set/provision code. Implemented strict read-only profile validation before sync. |
| **`AttendanceDto`** | `worker_id` is worker, not inspector. | Updated `canCreateReport()` rule to authorize attendance via `mineAssigned(mine_id)` and verified `AttendanceDto` conformance. |
| **`IncidentDto`** | Conforms to 21-field canonical schema with `inspector_id == auth.uid`. | Verified and aligned. |
| **`ObservationRepository` & DTO** | Writes to canonical collection (`grievances` / `observations`). | Verified and aligned. |
| **`InspectionRepository` & DTO** | Writes to canonical `inspections` collection. | Verified and aligned. |
| **`DocumentRepository` & DTO** | Writes to canonical `documents` collection with `user_id == auth.uid`. | Verified and aligned. |
