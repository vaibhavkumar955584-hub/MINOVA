# MINOVA — CAMERA FORENSIC AUDIT REPORT
**Target Subsystem**: Incident Reporting Camera Flow & Session State Restoration
**Date**: September 6, 2026

---

## 1. Executive Summary & Forensic Findings

A comprehensive audit was performed across the navigation stack, state lifecycle, repository draft persistence, and Android Activity lifecycle during image capture.

### Key Discoveries:
1. **Unpersisted Ephemeral Draft State**:
   `IncidentReportScreen` initialized `_submissionId` locally in `initState()` and held all field values (`description`, `immediateAction`, `peopleAffected`, `affectedPersonDetails`, `severity`, `type`, `equipment`) only in memory in widget controllers (`TextEditingController`). No draft was saved to SQLite (`incidents` table) prior to opening the camera.
2. **Android Camera Intent Lifecycle Interruption**:
   When `ImagePicker.pickImage(source: ImageSource.camera)` is called on Android, the operating system launches the external Camera Activity (`MediaStore.ACTION_IMAGE_CAPTURE`). On memory-constrained physical devices and emulators, the Android OS kills background Activities (`MainActivity`).
3. **App Reboot Lands on Home / Shell**:
   Upon completing the camera capture or upon cancellation, the Android Activity is recreated. Flutter boots from `main()`, which navigates to `MaterialApp(home: MainNavigationShell())`. The ephemeral in-memory state of `IncidentReportScreen` is lost, and the user appears on the Home Dashboard.
4. **Session Recovery Disconnection**:
   Although `_recoverLostEvidence()` called `retrieveLostPhoto(reportClientUuid: _submissionId)` in `initState()`, it was useless because `IncidentReportScreen` was not mounted after Activity recreation. Even when manually reopened, a new UUID was generated, severing the link to the captured photo.
5. **Missing Draft Methods in `IncidentRepository`**:
   Unlike `InspectionRepository` (which has `autoSaveDraft`, `getReportByUuid`, `discardDraft`), `IncidentRepository` only had `createDraft` (which was only invoked on submit) and `submitAndLockIncident`.

---

## 2. Navigation Trace & Stack Analysis

| Step | Action | Route / Stack Before | Navigation Event | Route / Stack After | Session / Submission ID |
|---|---|---|---|---|---|
| 1 | Open App | `[]` | `MaterialApp(home: MainNavigationShell)` | `[MainNavigationShell]` | - |
| 2 | Open Report Hub | `[MainNavigationShell]` | `Navigator.push(ReportHubScreen)` | `[MainNavigationShell, ReportHubScreen]` | - |
| 3 | Open Incident Report | `[MainNavigationShell, ReportHubScreen]` | `Navigator.push(IncidentReportScreen)` | `[MainNavigationShell, ReportHubScreen, IncidentReportScreen]` | `INC-EMG-XXXXXXXX` (Generated) |
| 4 | Enter Form Data | `... IncidentReportScreen` | User inputs text in controllers | Same stack | `INC-EMG-XXXXXXXX` (In-memory only) |
| 5 | Tap Camera Button | `... IncidentReportScreen` | `showModalBottomSheet(ImageSource)` | Modal Sheet on top of Incident | `INC-EMG-XXXXXXXX` |
| 6 | Select "Live Camera Photo" | Modal on Incident | `Navigator.pop(ctx, ImageSource.camera)` (Pops bottom sheet) | `... IncidentReportScreen` | `INC-EMG-XXXXXXXX` |
| 7 | Launch Native Camera | `... IncidentReportScreen` | Android Intent `MediaStore.ACTION_IMAGE_CAPTURE` | Backgrounded / Activity potentially killed by OS | Active ID lost if killed |
| 8 | Return from Camera (Without Fix) | Native Camera | OS restores `MainActivity` -> Flutter `main()` -> `MainNavigationShell` | `[MainNavigationShell]` (HOME) | LOST (New session required) |
| 8* | Return from Camera (With Fix) | Native Camera | Active draft restored from SQLite + `retrieveLostPhoto` + Persistent Session | `[MainNavigationShell, IncidentReportScreen]` | `INC-EMG-XXXXXXXX` (RESTORED) |

---

## 3. Camera Return Contract Verification

`EvidenceService.capturePhoto` contract:
```dart
Future<EvidenceItem?> capturePhoto({
  required String reportClientUuid,
  LocationResult? location,
  String? caption,
  String? userId,
  ImageSource source = ImageSource.camera,
  bool fallbackToSimulated = false,
});
```

- **Output Contract**: Returns an `EvidenceItem` containing `id`, `reportClientUuid`, `localFilePath`, `fileSize`, `sha256Hash`, and `capturedAt`.
- **Database Entry**: Inserts into `evidence` SQLite table immediately.
- **Local SHA-256 Calculation**: Calculated over raw image bytes before returning.
- **Cloudinary Upload**: NOT performed synchronously. Sync engine uploads asynchronously during background sync.
- **Navigation Contract**: No navigation or routing is performed within `EvidenceService`.

---

## 4. Root Cause Determination

| Hypothesis | Investigated | Cause of Bug? | Details |
|---|---|---|---|
| Explicit `context.go('/home')` or `Navigator.popUntil` in camera code | Yes | No | Code correctly pops only the modal bottom sheet (`Navigator.pop(ctx, ImageSource.camera)`). |
| Auth state reset on resume | Yes | No | `SecureTokenStorage` retains valid 12-hour session. |
| Android Activity lifecycle destruction on camera launch | Yes | **YES (Primary Root Cause)** | Camera intent causes Android OS to destroy/recreate `MainActivity`. Flutter restarts at `home: MainNavigationShell()`. |
| Unpersisted draft in `IncidentReportScreen` | Yes | **YES (Secondary Root Cause)** | No SQLite draft saved prior to opening camera; form state and `_submissionId` were strictly in-memory. |
| Nested Shell bottom navigation reset | Yes | Contributing | Shell default tab is 0 (Home), so when app restarts, tab 0 is shown. |
| Global error handler redirecting to Home | Yes | No | No global error handler is redirecting to home. |

---

## 5. Architectural Fix Strategy

1. **`IncidentRepository` Enhancements**:
   - Add `autoSaveDraft(IncidentReport report)`
   - Add `getDraftByClientUuid(String clientUuid)`
   - Add `getLatestDraft({String? userId})`
   - Add `discardDraft(String clientUuid)`
2. **`IncidentReportScreen` Auto-Draft & Pre-Camera Persistence**:
   - Initialize draft in SQLite upon first entry or restore existing active draft.
   - Synchronize all controllers (`description`, `action`, `peopleCount`, `persons`, `equipment`, `severity`, `type`) with the SQLite draft.
   - Persist active draft ID to `SharedPreferences` (`active_incident_draft_uuid`).
   - Before launching camera, execute `await _saveCurrentDraft()`.
   - On camera return, append evidence to both state and SQLite draft.
   - In `initState()`, execute `_recoverLostEvidence()` to recover any `LostDataResponse` from `ImagePicker`.
3. **`MainNavigationShell` Interruption Recovery**:
   - In `MainNavigationShell.initState()`, check if `active_incident_draft_uuid` exists.
   - If present, restore `IncidentReportScreen(initialClientUuid: activeUuid)` so the user is immediately returned to their active draft.
   - Clear `active_incident_draft_uuid` only on successful submission or explicit user discard.
4. **Signature & Schema Integrity**:
   - Digital signature enforcement remains mandatory prior to `submitAndLockIncident`.
   - Backend Incident schema and SQLite table structure remain untouched.
