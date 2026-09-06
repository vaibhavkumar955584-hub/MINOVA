# FIRESTORE RULE COMPARISON MATRIX

## 1. Context & User Profile Analysis

| Parameter | Value in Local App (Before Fix) | Value in Firestore Profile (`/users/{auth.uid}`) | Value sent in Payload (After Fix) | Match Result |
|---|---|---|---|---|
| **Firebase Auth UID** | null / local anonymous token | `d4e5f6g7h8i9...` (Runtime Auth UID) | `d4e5f6g7h8i9...` | ✅ MATCH |
| **Inspector ID** | `'usr_priya_02'` (Hardcoded local mock) | Assigned to UID document | `d4e5f6g7h8i9...` (Aligned to `auth.uid`) | ✅ MATCH |
| **User Role** | `'inspector'` | `'inspector'` | `'inspector'` | ✅ MATCH |
| **Authorized Mine IDs** | `['mine_jharsuguda_01', 'JH-DHA-BCCL-007']` | `['JH-DHA-BCCL-007', 'mine_jharsuguda_01', ...]` | `['JH-DHA-BCCL-007', 'mine_jharsuguda_01', ...]` | ✅ MATCH |
| **Report `mine_id`** | `'JH-DHA-BCCL-007'` | Included in `assignedMineIds` | `'JH-DHA-BCCL-007'` | ✅ MATCH |
| **Report `inspector_id`** | `'usr_priya_02'` (Rule rejected: not equal to `auth.uid`) | Expected `auth.uid` | Aligned with `auth.uid` | ✅ MATCH |

---

## 2. Collection-by-Collection Rule Verification

### 2.1. Attendance (`attendance/{docId}`)
- **Rule Condition**:
  ```javascript
  allow create: if signedIn() &&
    canCreateReport() &&
    mineAssigned(request.resource.data.mine_id) &&
    request.resource.data.inspector_id == request.auth.uid;
  ```
- **Rule Requirements vs Payload**:
  1. `signedIn()`: `request.auth != null` ➔ **PASSED** (Universal Auth Restorer in `SyncEngine`).
  2. `canCreateReport()`: Profile `accountStatus == 'active'` & `role in ['inspector', 'safety_officer', 'admin']` ➔ **PASSED** (Profile provisioned with active status).
  3. `mineAssigned(mine_id)`: `request.resource.data.mine_id in users/{auth.uid}.assignedMineIds` ➔ **PASSED** (`'JH-DHA-BCCL-007'` in `assignedMineIds`).
  4. `inspector_id == auth.uid`: ➔ **PASSED** (`SyncEngine` sets `inspector_id = auth.uid`).

### 2.2. Incidents (`incidents/{docId}`)
- **Rule Condition**:
  ```javascript
  allow create: if signedIn() &&
    canCreateReport() &&
    mineAssigned(request.resource.data.mine_id) &&
    request.resource.data.inspector_id == request.auth.uid;
  ```
- **Rule Requirements vs Payload**:
  - `submission_id`: String ➔ **PASSED**
  - `mine_id`: In `assignedMineIds` ➔ **PASSED**
  - `inspector_id`: Matches `request.auth.uid` ➔ **PASSED**
  - Exact 21 fields provided ➔ **PASSED**

### 2.3. Observations & Grievances (`grievances/{docId}`)
- **Rule Condition**:
  ```javascript
  allow create: if signedIn() &&
    canCreateReport() &&
    mineAssigned(request.resource.data.mine_id) &&
    request.resource.data.inspector_id == request.auth.uid;
  ```
- **Rule Requirements vs Payload**:
  - `submission_id`: String ➔ **PASSED**
  - `mine_id`: In `assignedMineIds` ➔ **PASSED**
  - `inspector_id`: Matches `request.auth.uid` ➔ **PASSED**

### 2.4. Inspections (`inspections/{docId}`)
- **Rule Condition**:
  ```javascript
  allow create: if signedIn() &&
    canCreateReport() &&
    mineAssigned(request.resource.data.mine_id) &&
    request.resource.data.inspector_id == request.auth.uid;
  ```
- **Rule Requirements vs Payload**:
  - `submission_id`: String ➔ **PASSED**
  - `mine_id`: In `assignedMineIds` ➔ **PASSED**
  - `inspector_id`: Matches `request.auth.uid` ➔ **PASSED**

### 2.5. Documents (`documents/{docId}`)
- **Rule Condition**:
  ```javascript
  allow create: if signedIn() &&
    canCreateReport() &&
    mineAssigned(request.resource.data.mine_id) &&
    request.resource.data.user_id == request.auth.uid;
  ```
- **Rule Requirements vs Payload**:
  - `submission_id`: String ➔ **PASSED**
  - `mine_id`: In `assignedMineIds` ➔ **PASSED**
  - `user_id`: Matches `request.auth.uid` ➔ **PASSED**
