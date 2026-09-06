# IMPLEMENTATION PLAN: MINOVA Mobile App

## Progress Tracking

### Phase 1: Foundation & Inspection
- [x] Inspect workspace and determine versions (Flutter 3.41.7, Dart 3.11.5).
- [x] Add required packages to `pubspec.yaml`.
- [x] Setup Context Handoff files (`/CONTEXT.md`, `/IMPLEMENTATION_PLAN.md`, `/CHANGELOG.md`, `/NEXT_TASK.md`).

### Phase 2: Core Design System, Auth & Navigation Shell
- [x] Implement `AppTheme` with Subterranean Industrial Safety System color tokens & Google Fonts (`Space Grotesk` & `Noto Sans`).
- [x] Implement `Role` & `Designation` permission matrix model (`RolePermissions`).
- [x] Implement `SecureTokenStorage` and `AuthService` with Firebase-aware offline session restore.
- [x] Build inspector-only email/password `LoginScreen` and `MainNavigationShell` with bottom navigation bar (Home, Report, Records, Profile).

### Phase 3: Offline Persistence & Sync Infrastructure
- [x] Implement `AppDatabase` (SQLite) with tables: Users, Mines, Inspections, Incidents, Attendances, Observations, Documents, Evidence, SyncQueue, CorrectionRequests, AuditEvents.
- [x] Implement `DraftManager` pattern with instant client UUID generation and debounced auto-save.
- [x] Implement `ConnectivityService` and `SyncEngine` with bounded retries, exponential backoff, and idempotent client UUID handling.

### Phase 4: Field Data Layer Services & Inspection Module
- [x] Implement `LocationService` with GPS timeout and manual underground mine zone fallback (`Main Shaft`, `Seam 3 - Gallery 4`, `Section B Face`, etc.).
- [x] Implement `EvidenceService` with camera capture, timestamp watermarking, and SHA-256 integrity hashing.
- [x] Implement `SignaturePadWidget` digital signing component.
- [x] Build and validate Step-by-Step `InspectionWizardScreen` (type-aware checklist, Pass/Fail/NA, conditional violation severity/description/corrective action/deadline, evidence, location fallback, signature, review, submission lock).

### Phase 5: Incident, Attendance, Observation & Document Modules
- [x] Build `IncidentReportScreen` with high-severity emergency SOS path & immediate authority alert queue.
- [x] Build `AttendanceScreen` (fast muster-roll check-in/check-out with headcount summary).
- [x] Build `ObservationScreen` (quick-capture safety/environmental observation with voice/gas reading).
- [x] Build `DocumentUploadScreen` (compliance certificates, licenses with scan/file picker).

### Phase 6: Records, Immutability, Audit & Correction Workflow
- [x] Build `RecordsScreen` matching design mockup with filter tabs (`All`, `Waiting`, `Sent`), waiting sync banner, and record cards.
- [x] Build `RecordDetailScreen` with immutable locked state view.
- [x] Build `CorrectionRequestModal` and audit logging workflow (`AuditEvent`).
- [x] Build `ProfileScreen` with user, mine, designation, underground simulation toggle, and logout.

### Phase 7: Verification, Automated Tests & Walkthrough
- [x] Write unit & integration tests covering Auth, Drafts, SQLite persistence, Location fallback, Evidence hashing, Submission lock, and Sync queue.
- [x] Run `flutter analyze` — Verified 0 warnings and 0 errors.
- [x] Verify complete 35-step acceptance scenario.

### Phase 8: Firebase Backend and Offline Evidence Sync
- [x] Add compile-safe Firebase options placeholder and guarded bootstrap helper.
- [x] Add Firebase email/password service wrapper.
- [x] Add salted device-local MPIN service.
- [x] Add operating-system biometric service wrapper.
- [x] Expose security services through Riverpod providers.
- [x] Run `flutterfire configure` with the real project.
- [x] Add Firestore and Storage datasource adapters.
- [x] Replace simulated sync success with authenticated backend writes.
- [x] Persist photo/video evidence metadata and upload state in SQLite.
- [x] Add stable Storage paths and Firestore report references.
- [x] Add bounded retry and partial-upload recovery behavior.
- [x] Add authenticated Firestore and Storage rules.

### Phase 8.1: Cloudinary media migration
- [x] Audit Firebase Storage coupling, SQLite evidence lifecycle, Firestore sync, DTO boundary, and tests.
- [x] Replace the binary-media adapter with provider-neutral `StorageService` and Cloudinary implementation.
- [x] Preserve Firebase Auth and Firestore; remove Firebase Storage package and deployment coupling.
- [x] Add Cloudinary metadata fields/indexes, stable `EV-...` evidence IDs, deterministic public IDs, and safe configuration documentation.
- [x] Configure a restricted Cloudinary unsigned preset or backend signed-upload endpoint.

### Phase 9: Multilingual Field UX
- [x] Add bundled ARB resources for English, Hindi, Odia, Telugu, Bengali, Marathi, Chhattisgarhi, and Santali.
- [x] Add persisted language model/controller with offline switching.
- [x] Add first-launch, Login, and Profile language selection.
- [x] Localize navigation, Home, Report Hub, core report actions, and Records offline states.
- [x] Add localization architecture and persistence tests.
- [x] Redesign Language Selection Screen with instant synchronous rebuild and high-contrast accessibility.

### Phase 10: Final Mobile Security and Operations
- [x] Freeze inspector authentication architecture after automated validation.
- [x] Add Firebase-aware session restoration.
- [x] Add first-login MPIN setup and startup MPIN gate.
- [x] Add biometric unlock with MPIN fallback.
- [x] Add re-authenticated forgot-MPIN reset.
- [x] Add FCM notification service boundary.
- [x] Add bounded Android WorkManager sync boundary.

### Phase 11: Backend contract DTO boundary
- [x] Add DTO serializers for inspection, attendance, incident, observation, contractor, mine, and user contracts.
- [x] Route supported report sync through the DTO mapper after evidence upload.
- [x] Document contract ownership, derived fields, evidence filtering, and current contract gaps in `BACKEND_CONTRACTS.md` and `BACKEND_INTEGRATION.md`.

### Phase 12: Final Bug Fix, Security, Localization, UI Stability & Performance Pass
- [x] Fix Home 5.3px RenderFlex overflow in metrics row.
- [x] Fix Report Wizard 22px RenderFlex overflow in navigation action buttons.
- [x] Enforce canonical statutory signature check (`validateBeforeSubmit`) rejecting null/blank submissions with `"Please add your signature before submitting."`.
- [x] Enhance `SignaturePadWidget` with stroke restoration from drafts, read-only mode, and layout safety.
- [x] Enforce inspector data isolation across SQLite repositories and Firestore rules.
- [x] Make language switching instantaneous with async persistence.
- [x] Optimize app startup sequence with non-blocking background initialization and debug instrumentation.
- [x] Pass 31/31 automated tests, 0 analyze issues, and verify debug APK build.

### Phase 13: Full Backend Contract & DTO Serialization Integration
- [x] Implement and audit all 8 DTO models (`InspectionDto`, `AttendanceDto`, `IncidentDto`, `ObservationDto`, `DocumentDto`, `ContractorDto`, `MineDto`, `UserDto`) with bidirectional mapping (`fromJson`, `toJson`, `fromDomain`, `toDomain`).
- [x] Normalize boolean fields to `"yes"`/`"no"` strings for `violation_found`, `medical_attention_required`, `notify_authority_immediately`.
- [x] Preserve exact null semantics for violation details and check-out fields.
- [x] Standardize UTC ISO-8601 timestamps and nested coordinate location objects.
- [x] Route report sync through `BackendPayloadMapper` to ensure SQLite maps are never leaked directly to external APIs.
- [x] Filter mobile-internal metadata (`localPath`, `integrityHash`, `retryCount`) while retaining rich offline SQLite persistence.
- [x] Write comprehensive DTO serialization and roundtrip tests in `test/backend_dto_test.dart` (39/39 total tests passing).
- [x] Update `BACKEND_CONTRACTS.md` and `BACKEND_INTEGRATION.md` with complete field classifications, transport specifications, and integration matrices.
