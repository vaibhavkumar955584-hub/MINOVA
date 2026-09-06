# MINE SAFE (MINOVA) — BUG AUDIT & RESOLUTION MATRIX

## Overview
This document records all identified issues, root cause analyses, remediation strategies, test strategies, and verified implementation statuses for MineSafe (MINOVA) Flutter.

---

### ISSUE 1: Home Screen Metrics Row RenderFlex Overflow (5.3px)
- **Current Behavior**: On standard/narrow mobile screens (e.g. 360px width or when translated into Hindi/bilingual strings), the Home dashboard metrics card row ("Queue for Sync / सिंक") overflowed on the right edge by 5.3 pixels.
- **Root Cause**: In `lib/features/home/home_dashboard_screen.dart`, `_CountBlock` used a `Row` containing an unconstrained `Column` alongside a 24px icon. When the bilingual string `"Queue for Sync / सिंक"` rendered, its intrinsic text width exceeded the card's available width.
- **Affected Files**:
  - `lib/features/home/home_dashboard_screen.dart`
- **Fix Strategy**: Wrapped the inner `Column` inside `_CountBlock` in an `Expanded` widget and applied `TextOverflow.ellipsis` with `maxLines: 1`. Also wrapped brand header in `Wrap` and shift/activity feed titles in `Expanded`.
- **Test Strategy**: Tested with `test/phase_fixes_test.dart` and `test/widget_test.dart` on narrow screen bounds (320px width).
- **Status**: VERIFIED

---

### ISSUE 2: Report Wizard Action Button RenderFlex Overflow (22px)
- **Current Behavior**: In `InspectionWizardScreen` (Review & Sign / Step 1), the bottom action button row overflowed by 22 pixels on small devices or localized states.
- **Root Cause**: `inspection_wizard_screen.dart` used `Row` with buttons containing static uppercase labels like `'ADD LOCATION & EVIDENCE'` or `'PROCEED TO REVIEW'` inside fixed/unconstrained children without text wrapping/overflow handling.
- **Affected Files**:
  - `lib/features/report/inspection/inspection_wizard_screen.dart`
- **Fix Strategy**: Wrapped action button label texts with `Flexible(child: Text(..., overflow: TextOverflow.ellipsis, maxLines: 1))`.
- **Test Strategy**: Unit & widget test verifying Step 1, 2, and 3 layouts render within bounds.
- **Status**: VERIFIED

---

### ISSUE 3 & 4: Statutory Signature Enforcement & Capture Robustness
- **Current Behavior**: A report could previously be submitted without an enforced signature check in all submission paths, and blank signatures could bypass integrity seals.
- **Root Cause**: UI button disabling was the primary barrier in some paths, but repository submission methods (`submitAndLockReport`, `submitAndLockIncident`) did not share a single canonical validation method throwing `"Please add your signature before submitting."`.
- **Affected Files**:
  - `lib/repositories/inspection_repository.dart`
  - `lib/repositories/incident_repository.dart`
  - `lib/features/report/inspection/inspection_wizard_screen.dart`
  - `lib/features/report/incident/incident_report_screen.dart`
  - `lib/shared/widgets/signature_pad.dart`
- **Fix Strategy**:
  1. Implemented canonical `validateBeforeSubmit(report)` in `InspectionRepository` and `IncidentRepository` that rejects null, empty, or blank signatures with `"Please add your signature before submitting."`.
  2. Enhanced `SignaturePadWidget` to support `initialSignature` stroke restoration from drafts and `isReadOnly` lock mode.
  3. Ensured submitted reports lock signatures permanently with SHA-256 integrity seal.
- **Test Strategy**: Tests in `test/phase_fixes_test.dart` covering null signature, blank signature, valid signature, draft persistence, and submission locking.
- **Status**: VERIFIED

---

### ISSUE 5: Inspector Data Isolation (Security & Privacy)
- **Current Behavior**: An inspector could theoretically query or receive cached reports belonging to other inspectors if Firestore queries or local database reads were not scoped to active user ID.
- **Root Cause**: Local repository `getAll*` methods and Firestore queries lacked parameterised `userId` scoping.
- **Affected Files**:
  - `firestore.rules`
  - `lib/repositories/inspection_repository.dart`
  - `lib/repositories/incident_repository.dart`
  - `lib/repositories/attendance_repository.dart`
  - `lib/repositories/observation_repository.dart`
  - `lib/repositories/document_repository.dart`
  - `lib/features/home/home_dashboard_screen.dart`
  - `lib/features/records/records_screen.dart`
- **Fix Strategy**:
  1. Added `userId` parameter and `user_id = ?` filtering across all SQLite repository queries.
  2. Scoped Home and Records screen queries to `authStateProvider` active user ID.
  3. Validated `firestore.rules` enforcing `resource.data.user_id == request.auth.uid`.
- **Test Strategy**: Tested in `test/phase_fixes_test.dart` asserting Inspector A queries never return Inspector B records.
- **Status**: VERIFIED

---

### ISSUE 6 & 7: Language Selector Experience & Instant UI Rebuild
- **Current Behavior**: Language selection took noticeable time before UI updated; user had to navigate back and forth, and the Continue button in `LanguageSelectionScreen` was an empty callback.
- **Root Cause**: `LanguageSelectionScreen` did not trigger navigation/pop or reflect selection state dynamically upon user interaction, and `LanguageController` had unlinked SharedPreferences in default provider construction.
- **Affected Files**:
  - `lib/features/auth/language_selection_screen.dart`
  - `lib/core/localization/language_controller.dart`
- **Fix Strategy**:
  1. Updated `LanguageController.select(code)` to update Riverpod state synchronously, and persist preference asynchronously without blocking the UI.
  2. Redesigned `LanguageSelectionScreen` with high-contrast active state, dual native/English typography, instant feedback, and functional Continue button.
- **Test Strategy**: Tested in `test/phase_fixes_test.dart` and `test/localization_test.dart`.
- **Status**: VERIFIED

---

### ISSUE 8: App Startup Performance & Initialization
- **Current Behavior**: Cold startup sequentially awaited background sync and notifications before rendering the first frame.
- **Root Cause**: `lib/main.dart` awaited `NotificationService().initialize()` and `BackgroundSyncService.initialize()` sequentially in `main()` before `runApp()`.
- **Affected Files**:
  - `lib/main.dart`
- **Fix Strategy**:
  1. Maintained critical initialization (Flutter bindings, Firebase, Local DB) before `runApp()`.
  2. Deferred non-critical background services to initialize asynchronously in parallel without blocking first frame.
  3. Added debug stopwatch startup timing instrumentation.
- **Test Strategy**: Tested startup smoke test (`test/widget_test.dart`) and build verification.
- **Status**: VERIFIED

---

### ISSUE 9: Regressions in Cloudinary, Offline Sync, and Backend DTOs
- **Current Behavior**: Need absolute assurance that unsigned Cloudinary uploads, offline queuing, SHA-256 integrity hashing, and JSON DTO contracts remain pristine.
- **Fix Strategy**: Verified contract tests, golden JSON checks, and unsigned Cloudinary upload services without introducing Firebase Storage or secrets.
- **Test Strategy**: Ran 31 automated tests (`flutter test`) and static analysis (`flutter analyze`).
- **Status**: VERIFIED
