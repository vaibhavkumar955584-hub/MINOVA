# Firebase Integration Handoff

MINOVA is connected to the Firebase project `MINOVA` (`minova-6329d`). The
generated FlutterFire options live in `lib/core/firebase/firebase_options.dart`,
and Firebase is initialized during app startup.

## Configure a project

1. Authenticate the Firebase CLI with the project owner account.
2. From the repository root, run `flutterfire configure --project=minova-6329d`.
3. Keep the generated options file and native configuration files in the
   platform projects.
4. Enable Email/Password sign-in, Firestore, and Storage in the Firebase
   console before exercising the corresponding features.

`FirebaseBootstrap.initialize()` returns `false` only when placeholder options
are present, which keeps local tests usable before project setup.

## Current implementation boundary

- `FirebaseAuthService` wraps email/password registration and sign-in, Google
   sign-in, phone OTP verification, password reset, re-authentication, and
   sign-out.
- `AuthNotifier` maps Firebase users to the existing `UserModel`, loads profiles
   from `users/{uid}`, and caches them in SQLite for offline-first startup.
- `MpinService` stores only a salted SHA-256 hash in secure storage.
- `BiometricService` delegates biometric prompts to the operating system.
- `EvidenceService` copies camera and gallery files into application documents,
   hashes them, and stores metadata only in SQLite. Binary content never enters
   SQLite.
- `SyncEngine` uploads pending evidence to Storage, writes the report document
   to Firestore, and marks the local report `synced` only after both operations
   succeed. It reuses the report `clientUuid` and evidence IDs on retry.

## Firestore schema

Reports use the client UUID as the document ID:

- `inspections/{clientUuid}`
- `incidents/{clientUuid}`
- `attendance/{clientUuid}`
- `observations/{clientUuid}`
- `documents/{clientUuid}`

Each report contains an `evidence` array with `id`, `type`, `fileName`,
`mimeType`, `fileSize`, `sha256`, `capturedAt` (Firestore `Timestamp`),
coordinates, `storagePath`, and `downloadUrl`. Evidence never contains binary
data.

## Storage paths and lifecycle

- `evidence/{mineId}/{userId}/{reportType}/{reportId}/{evidenceId}.{extension}`
- `documents/{mineId}/{documentId}/{evidenceId}.{extension}`
- `signatures/{mineId}/{reportId}/signature.png`

Capture writes a persistent local file and a `pending` metadata row. Queue
processing changes it to `uploading`, then `uploaded` after Storage confirms the
stable path. If Firestore fails afterward, the evidence remains `uploaded` and
the next retry writes Firestore without uploading the same object again.

## Offline and security assumptions

Submission changes the local report to `pending_sync`, which is locked. Offline
capture, restart, and later connectivity recovery are supported by SQLite and
the durable sync queue. User-facing failures remain generic (`Upload failed` or
`Waiting to upload`).

Firestore and Storage rules require Firebase Authentication and a user profile
at `users/{uid}` containing an authoritative `assignedMineIds` array and role.
That assignment must be provisioned by a trusted administrator/backend; the
client cannot grant itself mine access or change its role. The client bootstrap
profile has no mine assignment and must be provisioned before report sync can
succeed.

Before testing provider flows, enable Email/Password, Google, and Phone under
Firebase Console > Authentication > Sign-in method. Create Firestore and
Storage databases and deploy rules that permit the intended authenticated user
access. Google Sign-In also requires the Android SHA-1/SHA-256 fingerprints in
the Firebase Android app settings.