# Backend Integration & Cloud Architecture Guide

This document is for backend engineers and integration partners collaborating with the MineSafe (MINOVA) Flutter mobile client.

---

## 1. Integration Matrix

| Entity | DTO Class | Firestore Collection | JSON Contract | Mapped | Tested |
|---|---|---|---|---|---|
| **Inspection** | `InspectionDto` | `inspections/{submission_id}` | `inspections.json` | ✅ | ✅ |
| **Attendance** | `AttendanceDto` | `attendance/{submission_id}` | `attendance.json` | ✅ | ✅ |
| **Incident** | `IncidentDto` | `incidents/{submission_id}` | `incidents.json` | ✅ | ✅ |
| **Observation / Grievance** | `ObservationDto` | `observations/{submission_id}` | `grievances.json` | ✅ | ✅ |
| **Compliance Document** | `DocumentDto` | `documents/{submission_id}` | (Internal Contract) | ✅ | ✅ |
| **Contractor** | `ContractorDto` | `contractors/{contractor_id}` | `contractors.json` | ✅ | ✅ |
| **Mine** | `MineDto` | `mines/{mine_id}` | `mines.json` | ✅ | ✅ |
| **User Profile** | `UserDto` | `users/{user_id}` | `users.json` | ✅ | ✅ |

---

## 2. Authentication & Identity Architecture
- **Provider**: Firebase Authentication (Email/Password).
- **UID Consistency**: The Firebase Auth `uid` is identical to `user_id` in Firestore `users/{uid}`.
- **Role Permissions**: Stored in the `users/{uid}` document under the `role` field (`inspector`, `mine_official`, `contractor`).
- **Data Isolation**: Firestore security rules restrict inspector queries to documents where `user_id == request.auth.uid` or where the inspector's assigned mine matches.

---

## 3. Storage & Evidence Pipeline
1. **Local Capture**: Photos, videos, and signatures are recorded on device, hashed with SHA-256, and stored in the app's encrypted document sandbox.
2. **Cloudinary / Storage Upload**:
   - Media files are uploaded asynchronously via unsigned upload presets (`minova_mobile_demo` / `krccszeo`).
   - Binary data is never embedded directly inside Firestore documents.
3. **DTO Serialization**:
   - The DTO layer extracts public resource identifiers/filenames into the `photos_or_videos` array of the statutory JSON payload.
   - Rich internal metadata (`localPath`, `sha256`, `uploadAttempts`) remains in the client's local SQLite database.

---

## 4. Idempotency & Sync Strategy
- **Document ID**: Submissions use client-generated statutory UUIDs (`submission_id`).
- **Upsert / Idempotent Writes**: All sync uploads use Firestore `.set(payload, SetOptions(merge: true))` on `collection/{submission_id}`.
- **Offline Queue**: When the mobile client is offline or experiencing network latency:
  - Submissions are sealed locally with cryptographic hashes and stored in SQLite.
  - The background sync engine continuously drains the queue as connectivity resumes.
  - Duplicate network requests produce identical idempotent updates with zero state corruption.

---

## 5. Timestamp & Location Standards
- **Timestamps**: Serialized strictly as UTC ISO-8601 strings (e.g. `2026-02-10T14:30:00.000Z`).
- **Location Structure**: Serialized as standard nested coordinate objects:
  ```json
  "location": {
    "latitude": 21.85102,
    "longitude": 84.01234
  }
  ```

---

## 6. AI & Derived Field Rules
- **`priority_flagged_by_ai`**: The mobile app sets this field to `null` upon submission. Cloud Functions or backend AI workers evaluate incoming observations and write back the computed priority.
- **Original Content Integrity**: Inspector text descriptions and checklist answers are immutable once submitted and cannot be overwritten by automated systems.

---

## 7. Error Handling & Status Codes
- **`400 Bad Request`**: DTO mapper validation failure (e.g. missing required GPS on attendance).
- **`403 Forbidden`**: Security rule denial (e.g. attempting to submit report for an unassigned mine).
- **`503 Service Unavailable / Offline`**: Sync engine automatically retries with exponential backoff.
