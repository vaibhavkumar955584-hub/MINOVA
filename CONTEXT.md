# PROJECT CONTEXT: MINOVA (SIH 26024)

## Architecture Overview
MineSafe is an offline-first, role-aware, integrity-protected field operations mobile application engineered for coal mine compliance reporting under hazardous, low-connectivity subterranean conditions.

### Core 3-Layer Architecture
1. **Experience Layer**: Home Dashboard, Report Hub (Safety/Environmental/Production/Labour Inspection, Incident, Attendance, Observation, Document), Records with filters, Profile & Settings.
2. **Field Data Layer**: Location capture (GPS timeout with low-accuracy & manual underground zone fallback), Evidence capture (in-app camera, timestamp watermark, SHA-256 integrity hash), Digital signature canvas with draft stroke restoration & lock modes, Local auto-save draft manager.
3. **Offline & Sync Layer**: Local SQLite database with strict `userId` scoping, Idempotent Client UUIDs, FIFO Sync Queue with exponential backoff & bounded retries, Tamper detection, Submission locking (immutable records), Supervisor-approved correction requests.

## Technology Stack & Conventions
- **Framework**: Flutter 3.41.7 / Dart 3.11.5
- **State Management**: Flutter Riverpod (`flutter_riverpod: ^2.6.1`)
- **Local Database**: SQLite (`sqflite`, `sqflite_common_ffi`, `path_provider`)
- **Secure Storage**: `flutter_secure_storage` for session auth tokens
- **Integrity**: `crypto` for SHA-256 evidence and record hash computation
- **Design System**: Subterranean Industrial Safety System
  - Base Background: Deep Charcoal `#121417`
  - Layer 1 Container: `#1A1D23` with `#323846` stroke
  - Layer 2 Controls: `#222630`
  - Safety Amber (Primary Action): `#F59E0B`
  - Hazard Red (Emergency / Violation): `#EF4444`
  - Compliance Green (Safe / Sent): `#10B981`
  - Informational Blue (Sync / Telemetry): `#3B82F6`
  - Typography: Space Grotesk (headings, tabular telemetry) & Noto Sans (body copy + bilingual Hindi micro-prompts)
  - Ergonomics: Large 52px+ touch targets, glove-friendly controls, responsive text truncation/wrapping preventing all RenderFlex overflows.

## Roles & Permissions
- **Roles**: `inspector`, `contractor`, `mine_official`
- **Designations**: `Safety Officer`, `Site Supervisor`, `Manager`, `Worker`
- Centralized permission engine mapping `(role, designation, mine_assignment) -> allowed_features`.

## CURRENT STATE
- **Current implementation stage**: Forensic Resolution of Firestore `PERMISSION_DENIED` & Profile Access Architecture. Removed unauthorized profile provisioning from mobile sync, enforced read-only profile validation, hardened `firestore.rules` for all 5 collections, and conformed diagnostic logging. 0 analyzer issues found.
- **Last completed task**: Forensic Root Cause Investigation & Audit (`FIRESTORE_ROOT_CAUSE_AUDIT.md`, `FIRESTORE_ROOT_CAUSE_FINAL.md`, `FIREBASE_AUTHORIZATION_MODEL.md`, `SYNC_FAILURE_MATRIX.md`).
- **Next task**: Deploy updated `firestore.rules` to Firebase project `minova-ef69c` and execute real authenticated Android field trial for all 5 report types (Attendance, Incident, Observation, Inspection, Document).
- **Known limitations**: Cloudinary media upload requires runtime `--dart-define` parameters (`CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_UNSIGNED_UPLOAD_PRESET`).
- **Authentication model**: Firebase Email/Password identifies the inspector; Firestore validates role, account status, manager, and mine assignment; local MPIN/biometrics unlock the device session.
- **Media boundary**: `lib/data/storage/StorageService` isolates Cloudinary from UI and domain models. Binary evidence is local-first and synchronizes through Cloudinary; Firestore stores metadata only. Configuration is supplied by `--dart-define`; secrets are prohibited in source and APKs.
- **Backend DTO boundary**: `lib/data/dto` serializes supported external report contracts after evidence upload; SQLite maps are not sent directly. Contract details are maintained in `BACKEND_CONTRACTS.md`.
- **Inspection status**: Draft UUIDs, type-aware checklists, autosave, canonical signature validation, SHA-256 submission locking, and sync queue insertion are strictly enforced and 100% test-covered.
