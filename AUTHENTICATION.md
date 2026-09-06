# MINOVA Authentication Architecture

## Identity and authorization

Firebase Authentication with Email/Password is the only mobile account login. Inspector accounts are provisioned by a manager or trusted backend; the mobile app has no public registration, phone login, Google login, or manager account creation.

After Firebase authentication, the app loads `users/{uid}` from Firestore and validates:

- `role == inspector`
- `accountStatus == active`
- `assignedMineIds` contains at least one mine
- `managerId` is present

Invalid, inactive, unassigned, or non-inspector accounts are signed out and shown a field-user error. The Firebase password is never stored locally.

## First device login

1. Inspector enters email and password.
2. Firebase Authentication returns the UID.
3. Firestore loads and validates the inspector profile.
4. The profile is cached in SQLite for offline session restoration.
5. The inspector creates and confirms a six-digit local MPIN.
6. Device biometrics may be enabled when supported.
7. The local security gate opens the field app.

## Subsequent opens

When Firebase has an existing authenticated user and a valid cached profile, the app restores the session without asking for the Firebase password. The local security gate then requires MPIN or enabled device biometrics. Temporary network loss does not force a new Firebase login when the local session is valid.

A missing Firebase session, explicit logout, account revocation, or invalid profile returns the user to login.

## Local security

The MPIN is device-local. A salted SHA-256 hash and device salt are stored with `flutter_secure_storage`; plaintext MPIN values are never stored or sent to Firebase. Biometric authentication uses `local_auth` and stays inside the operating system. Fingerprint and face support are detected dynamically, and MPIN remains the fallback.

First setup requires matching MPIN and confirmation. Biometric use is optional. Logout clears the MPIN hash, biometric preference, and local session metadata.

## Recovery

- **Forgot password:** Firebase sends the password reset email. The inspector logs in again with the new password.
- **Forgot MPIN:** the current Firebase user reauthenticates with email/password before a new local MPIN is created.
- **New device or reinstall:** Firebase login is required and a new device-local MPIN is created.

## Offline and lifecycle behavior

The app may use a cached, previously validated inspector profile while offline. Drafts, evidence, and sync queue data remain local and are processed when connectivity returns. Backgrounding and auto-lock policy remain staged for a later lifecycle controller; the current startup gate handles app restart and explicit local unlock.

## Mobile scope

The inspector app exposes Home, Report, Records, and Profile. Manager, mine administration, user provisioning, approval, corporate, and regulator workflows belong to backend or web applications.

## External provisioning

A trusted administrator must create the Firebase Auth account and Firestore profile. The profile should include `uid`, `fullName`, `email`, `employeeId`, `role`, `designation`, `managerId`, `mineId`, `assignedMineIds`, `preferredLanguage`, `accountStatus`, `createdAt`, and `updatedAt`.
