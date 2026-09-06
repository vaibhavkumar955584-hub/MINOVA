# MINOVA Mobile Architecture

## Runtime layers

`Flutter UI -> Riverpod providers -> repositories/services -> local SQLite and Firebase data sources`

The local database is the offline working layer. Firebase Authentication is the
account identity layer. Firestore is the cloud report source of truth, and
Firebase Storage holds binary evidence. Widgets do not call Firestore or
Storage directly.

## Authentication and local security

Firebase Email/Password, Google, and Phone providers authenticate the account.
The Firebase session is restored first when available, with the cached SQLite
profile as the offline fallback. After account authentication, the local
security gate requires a six-digit MPIN. MPIN is salted and hashed in secure
storage. Fingerprint/biometric authentication is attempted when available and
falls back to MPIN. Passwords and fingerprint data are never stored or uploaded.
Forgot-MPIN requires Firebase email/password re-authentication before replacing
the local MPIN.

## Offline evidence and reports

Camera/gallery media is copied into application documents before metadata is
written to SQLite. SQLite stores the file path, type, size, SHA-256, location,
and upload state; it never stores binary content. Submitted reports become
locked and enter the durable sync queue. Sync uploads evidence to stable
Storage paths, writes Firestore metadata with timestamps, and marks the local
report synced only after both operations succeed.

Storage paths:

- `evidence/{mineId}/{userId}/{reportType}/{reportId}/{evidenceId}.{extension}`
- `documents/{mineId}/{documentId}/{evidenceId}.{extension}`
- `signatures/{mineId}/{reportId}/signature.png`

Report document IDs are the permanent client UUID. Retries reuse the same
report ID and evidence ID. If Storage succeeds and Firestore fails, the next
retry skips the already-uploaded object and retries the report write.

## Background work and notifications

Connectivity changes trigger immediate foreground queue processing. Android
WorkManager schedules a connected periodic attempt with bounded exponential
backoff. Firebase Cloud Messaging is initialized by `NotificationService` and
provides a message stream for future backend incident alerts. A notification
must not be described as authority-confirmed unless a backend confirmation is
received.

## Current versus staged technology migrations

The current production code uses Riverpod, `sqflite`, `image_picker`, Firebase
SDKs, and imperative `Navigator` routes. GoRouter, Drift, and Dio are not yet
migrated. They should be introduced one boundary at a time with tests after
each migration; the current persistence and navigation must remain intact until
those replacements are proven compatible.

## Security assumptions

Firestore and Storage rules require authentication, mine assignment, ownership,
and immutable submitted-report behavior. A trusted administrator/backend must
provision `users/{uid}` with authoritative `role` and `assignedMineIds`; the
client cannot self-assign a mine or change its role. Physical device camera,
biometric, GPS, Firebase Console, and emulator validation remain environment
checks rather than source-only guarantees.
