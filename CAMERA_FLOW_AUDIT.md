# Camera Flow Audit: Incident Report Screen

## 1. Audit Overview & Objectives
This audit investigates the camera capture flow from `IncidentReportScreen`, identifying why capturing media could lead to lost state, orphaned evidence records, or perceived return to the Home/Dashboard instead of remaining on the active Incident Report screen.

---

## 2. Codebase Inspection Findings

### A. Navigation & Lifecycle Handling
- **Route Navigation**:
  - `IncidentReportScreen` is opened via `Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentReportScreen()))` from `HomeDashboardScreen` and `ReportHubScreen`.
  - In `_captureEvidence()`, `_showPhotoSourceDialog()` opens a `showModalBottomSheet`.
  - When the user selects "Live Camera Photo" or "Gallery / Storage", `Navigator.pop(ctx, ImageSource.camera)` is called to close **only** the modal sheet.
  - However, there was no recovery hook for Android `retrieveLostData()` in `IncidentReportScreen.initState()` in case the Android OS destroyed the Flutter activity while the external Camera Activity was in the foreground.

### B. Session & Submission ID Stability
- **Missing Persistent Session ID**:
  - `IncidentReportScreen` did not generate or maintain a stable `_submissionId` on screen initialization (`initState()`).
  - When calling `evidenceService.capturePhoto(...)`, it passed hardcoded `reportClientUuid: 'temp_inc'`.
  - When the user eventually tapped `_submitIncident()`, `repo.createDraft(...)` was called, generating a brand new UUID `INC-EMG-...`.
  - **Issue**: All captured evidence items stored in the SQLite `evidence` table were orphaned or linked to `'temp_inc'`, disconnected from the actual final incident `submission_id`.

### C. Evidence UI & Visual Feedback
- **Missing Preview Widget**:
  - When `_evidenceList` received a new `EvidenceItem`, the UI only updated the button label (`'ADD ANOTHER PHOTO (N ATTACHED)'`).
  - There was **no thumbnail gallery, image preview, delete action, or preview carousel** rendered on the screen.
  - To the inspector, it visually appeared as if the captured image was lost or not attached to the form.

### D. Cancellation & Error Handling
- In `EvidenceService.capturePhoto()`, if `photo == null` (user clicked cancel/back in camera), the fallback was returning simulated dummy evidence instead of `null`.
- Canceling the camera should return `null` and leave existing form state completely unchanged without adding dummy items.

---

## 3. Root Causes Summary

1. **Orphaned Evidence Linkage**: `_captureEvidence` used `reportClientUuid: 'temp_inc'` instead of a stable session `_submissionId`.
2. **Missing In-Form Evidence Preview Widget**: No image thumbnails or evidence cards were displayed in the UI below the capture button.
3. **Draft State Lifecycle**: Draft was not instantiated or keyed with a persistent session ID on screen initialization.
4. **Camera Cancel Behavior**: Camera cancellation returned simulated evidence instead of a clean no-op.

---

## 4. Planned Resolution Architecture

1. **Stable Incident Session**:
   - Initialize `_submissionId = 'INC-${DateTime.now().year}-${const Uuid().v4().substring(0, 8).toUpperCase()}'` in `initState()`.
   - Allow `IncidentRepository.createDraft` to accept an explicit `clientUuid`.
2. **Direct Evidence Association**:
   - Pass `reportClientUuid: _submissionId` to `evidenceService.capturePhoto`.
   - Store evidence items in SQLite linked directly to the active incident draft.
3. **Rich Evidence Preview UI**:
   - Display a thumbnail preview row/grid showing the captured image (`Image.file`), photo index, timestamp, and delete action.
   - Maintain the "[ + Add Another Photo ]" button.
4. **Android Lifecycle Recovery**:
   - Call `evidenceService.retrieveLostPhoto(reportClientUuid: _submissionId)` in `initState()` to recover any image if the Android activity was briefly killed by OS memory pressure.
5. **Preserve Navigation & Form State**:
   - Ensure camera flow remains purely a child modal/picker flow with zero parent navigation or route pops until explicit user submission.
