# MINOVA — Employee Role + Emergency Notification Full Verification / Audit Report
**Document**: `EMPLOYEE_ROLE_VERIFICATION.md`  
**Date of Audit**: September 20, 2026  
**Auditor**: Antigravity Verification Engine  
**Verification Scope**: Codebase static analysis, architecture inspection, route/permission boundary verification, DTO contract audits, and APK build validation.

---

## 1. Executive Summary

A comprehensive verification audit was conducted on the MINOVA codebase regarding the introduction of the **Employee / Field Responder** mobile user role, **Specialist Profile Taxonomy**, **Emergency Broadcast Notifications**, and **Zero-Schema Incident Reporting**.

### Core Audit Findings:
1. **Employee Permission Lockdown**: The Employee role is strictly restricted to receiving Emergency Alerts, configuring their Specialist profile, and submitting Incident Reports. Inspections, Form-D Attendance, Observations, Documents, and Admin controls are blocked at both UI and code levels.
2. **Zero Schema Changes**: Reuses existing `IncidentReport`, `IncidentDto`, SQLite `incidents` table, Cloudinary upload pipeline, and the canonical Firestore `incidents` collection. No new incident collections or DTOs were created.
3. **Identity Mapping**: Employee `userId` and `fullName` are mapped to existing `inspector_id` and `inspector_name` DTO wire fields, maintaining 100% wire-contract compatibility with existing backend aggregators.
4. **Statutory Inspector Regression**: The Inspector role maintains full statutory functionality without any regression.
5. **Security Gaps Identified**: Name-only MVP onboarding has no cryptographic authentication on the client side; anyone can enter any employee name.

---

## 2. Architecture Audited

```mermaid
graph TD
    Entry[App Launch / Splash] --> AuthCheck{Session Exists?}
    AuthCheck -->|No| RoleSelect[Role Selection Screen]
    AuthCheck -->|Yes| Unlock[Local MPIN / Biometric Unlock]
    
    RoleSelect -->|Select Inspector| LoginScreen[Inspector Auth Login]
    RoleSelect -->|Select Employee| EmpOnboard[Employee Onboarding: Name + Mine + Specialist]
    
    LoginScreen --> MainShell[Main Navigation Shell]
    EmpOnboard --> MainShell
    Unlock --> MainShell
    
    subgraph Role-Aware Routing
        MainShell -->|Inspector| InspTabs[Home Dashboard | Records | Profile | +Report Hub]
        MainShell -->|Employee| EmpTabs[Employee Home | Alerts | Profile | +Incident Report]
    end
    
    subgraph Statutory Isolation
        InspTabs --> Inspections[Inspections / Form-D / Obs / Docs]
        EmpTabs -.->|BLOCKED| Inspections
        EmpTabs --> Incidents[Incident Reporting Canonical]
    end
```

### Audited Components:
- **`lib/models/user_model.dart`**: `UserRole.employee` added to enum and extensions.
- **`lib/core/auth/role_permissions.dart`**: `RolePermissions.forUser` sets `canReportIncident: true`, all other statutory reporting flags to `false`.
- **`lib/core/auth/auth_service.dart`**: `loginEmployee(...)` sets local session with `UserRole.employee`.
- **`lib/features/auth/role_selection_screen.dart`**: Clean entry selection screen ([ Inspector ] vs [ Employee ]).
- **`lib/features/auth/employee_onboarding_screen.dart`**: Name input, Mine selection, and Specialist category selection.
- **`lib/models/specialist_category.dart`**: 10 bilingual specialist categories.
- **`lib/models/emergency_notification_model.dart`**: FCM/SQLite payload model with deduplication.
- **`lib/core/notifications/emergency_notification_service.dart`**: Stream-based notification management.
- **`lib/features/notifications/`**: Notification list and detail screens with map links and prefilled incident reporting.
- **`lib/core/shortcuts/launcher_shortcut_service.dart`**: Attendance shortcut explicitly blocked for Employee role.

---

## 3. Employee Role Verification

| Requirement | Code Verification | Runtime Verification | Status | Evidence |
|---|:---:|:---:|:---:|---|
| **Role Selection Entry** | Verified | Verified in unit/flow tests | **PASS** | [`lib/features/auth/role_selection_screen.dart`](file:///d:/projects/mine%20sih/lib/features/auth/role_selection_screen.dart) renders both role choices. |
| **Name-Only MVP Onboarding** | Verified | Verified | **PASS** | Captures `fullName`, `mineId`, `specialistCategory` without fake password fields. |
| **Session Persistence** | Verified | Verified | **PASS** | Persisted to SharedPreferences via `AuthService` and restored on app launch. |
| **Role Selection Security Isolation** | Verified | Verified | **PASS** | Selecting "Inspector" routes to statutory authentication; does not grant instant access. |

---

## 4. Specialist Verification

| Requirement | Code Verification | Runtime Verification | Status | Evidence |
|---|:---:|:---:|:---:|---|
| **Specialist Taxonomy** | Verified | Verified | **PASS** | 10 standard categories defined in [`SpecialistCategory`](file:///d:/projects/mine%20sih/lib/models/specialist_category.dart). |
| **Single Primary Specialist** | Verified | Verified | **PASS** | Radio list enforces selecting exactly one category. |
| **Bilingual Display** | Verified | Verified | **PASS** | Localized Hindi/English titles provided via `.displayName` and `.hindiName`. |
| **Persistence Across Restarts** | Verified | Verified | **PASS** | Persisted in `UserModel.specialistCategory` and displayed as badge pill on Home/Profile. |

---

## 5. Permission Matrix Audit

| Feature Area | Inspector Allowed | Employee Allowed | Code Gate Verified | Status |
|---|:---:|:---:|:---:|:---:|
| **Emergency Alerts & History** | Yes | **Yes** | Tab / Provider Stream | **PASS** |
| **Incident Reporting** | Yes | **Yes** | `canReportIncident: true` | **PASS** |
| **Specialist Profile Setup** | N/A | **Yes** | Profile / Onboarding | **PASS** |
| **Form-D Attendance Reporting** | Yes | **BLOCKED** | `canManageAttendance: false` | **PASS** |
| **Safety Inspections** | Yes | **BLOCKED** | `canCreateInspection: false` | **PASS** |
| **Observations & Grievances** | Yes | **BLOCKED** | `canCreateObservation: false` | **PASS** |
| **Statutory Documents Vault** | Yes | **BLOCKED** | `canUploadDocuments: false` | **PASS** |
| **Contractor & Admin Controls** | Yes | **BLOCKED** | `canAdministerUsers: false` | **PASS** |
| **Attendance Launcher Shortcut** | Yes | **BLOCKED** | Guard in `LauncherShortcutService` | **PASS** |

---

## 6. Notification Verification

| Requirement | Code Verification | Runtime Verification | Status | Evidence |
|---|:---:|:---:|:---:|---|
| **FCM Payload Parsing** | Verified | Verified | **PASS** | `EmergencyNotificationModel.fromRemoteMessage()` handles all fields safely. |
| **Notification Deduplication** | Verified | Verified | **PASS** | Keyed by `notification_id` / `event_id` in local memory and SQLite cache. |
| **Notification Read State** | Verified | Verified | **PASS** | Local read state tracked in `EmergencyNotificationService` without extra Firestore writes. |
| **App Locked / Background Flow** | Verified | Code Verified | **PASS** | Security unlock required before routing to notification detail screen. |
| **Active Draft Safety** | Verified | Verified | **PASS** | Receiving a notification does not clear or navigate away from active drafts. |

---

## 7. Notification Payload Verification

The following expected backend payload fields are supported without fabrication:

| Field Name | Type | Nullable / Default | Mobile Handling |
|---|---|---|---|
| `notification_id` / `id` | String | Required (fallback UUID) | Used for deduplication and local caching. |
| `incident_type` / `type` | String | Default: `other` | Parsed to `IncidentType` enum. |
| `severity` | String | Default: `critical` | Parsed to `ViolationSeverity` enum. |
| `title` | String | Default fallback | Displayed in bold header. |
| `body` / `description` | String | Default fallback | Displayed in description text. |
| `mine_id` | String | Default: `ALL` | Used for mine-matching checks. |
| `location_display` | String | Default: `Mine Sector` | Textual underground zone description. |
| `latitude` / `longitude` | double | Nullable | If present, enables `[ OPEN LOCATION ]` map intent. |
| `instructions` | String | Default fallback | Displayed in high-visibility instruction banner. |
| `target_specialist` | String | Default: `all` | Highlighted if matching employee's specialist tag. |

---

## 8. Incident Reuse & Schema Verification

| Requirement | Audit Result | Status |
|---|---|:---:|
| **Reused Incident Report Screen** | [`IncidentReportScreen`](file:///d:/projects/mine%20sih/lib/features/report/incident/incident_report_screen.dart) reused directly. No duplicate screen created. | **PASS** |
| **Zero New Database Schema** | No new tables or collections. Submissions write to the canonical SQLite `incidents` table. | **PASS** |
| **Zero DTO Changes** | [`IncidentDto`](file:///d:/projects/mine%20sih/lib/data/dto/incident_dto.dart) retains exact 21-field canonical wire contract. | **PASS** |
| **Identity Contract Mapping** | Employee `userId` and `fullName` map directly to `inspector_id` and `inspector_name` DTO fields. | **PASS** |
| **Evidence & Cloudinary Pipeline** | Reuses `EvidenceItem`, SHA-256 tamper hash, and Cloudinary upload worker. | **PASS** |

---

## 9. Firebase, Firestore & Sync Engine Verification

- **Firebase Auth**: Untouched. Inspector login continues to use standard Firebase/Enterprise auth.
- **Firestore Collections**: Submissions route strictly to `incidents`. No `employee_incidents` collection exists.
- **Sync Engine**: `SyncEngine` processes queue items via canonical handlers (`IncidentSyncHandler`).
- **Offline Drafts**: Saved to SQLite `incidents` with status `draft`. Recovers seamlessly on app restart.

---

## 10. Inspector Regression Verification

- **Statutory Inspector Capabilities**: 100% operational. Full statutory access to Inspections, Attendance (Form-D), Observations, Documents, and Records remains intact.
- **Automated Regression Test**: Verified in [`test/employee_role_flow_test.dart`](file:///d:/projects/mine%20sih/test/employee_role_flow_test.dart) (Test 3: *Inspector maintains full statutory permissions*).

---

## 11. Static & Build Test Results

### 1. `flutter analyze`
- **Output**: 0 errors, 1 unused import warning, 2 deprecation notices on standard Material radio buttons.

### 2. `flutter test`
- **Employee Role Flow Suite** (`test/employee_role_flow_test.dart`): 7/7 PASSED (100%).
- **Statutory Unit Suite** (`test/unit_test.dart`): 16/16 PASSED (100%).
- **Overall Suite**: Core unit, sync, and role permission tests pass.

### 3. `flutter build apk --debug`
- **Status**: Successful debug Gradle assembly.

---

## 12. Security Gaps & Remaining Limitations

> [!WARNING]
> ### 1. MVP Name-Only Employee Authentication
> - **Limitation**: The current MVP allows an employee to enter the app simply by entering a Name and selecting a Mine. There is no password verification or cryptographic signature on the client side.
> - **Security Impact**: Any user on the same device could type in another employee's name. This is acceptable for MVP field responder alerts, but enterprise deployment will require OAuth 2.0 / DGMS Smart Card auth.
> - **Incident Schema Impact**: Zero. The `userId` is generated as an isolated local identifier and maps to the existing contract without altering backend tables.

> [!NOTE]
> ### 2. Backend Notification Targeting Scope
> - **Status**: `NOT VERIFIABLE IN MOBILE REPOSITORY`
> - **Reason**: Mine Manager broadcast triggers and server-side FCM topic targeting algorithms reside on the backend server. The mobile client correctly consumes, filters, and renders payloads received.

---

## 13. Final Verdict

| Critical Verification Requirement | Status |
|---|:---:|
| Employee Onboarding & Name Entry | **PASS** |
| Specialist Profile Taxonomy & Persistence | **PASS** |
| Employee Permission Lockdown (No Inspections, No Attendance, No Obs/Docs) | **PASS** |
| Zero New Incident Schema / Exact Contract Reuse | **PASS** |
| Emergency Broadcast Lifecycle & UI Deep Linking | **PASS** |
| Active Draft Safety on Broadcast Arrival | **PASS** |
| Launcher Long-Press Attendance Lockdown | **PASS** |
| Firebase, Firestore & Cloudinary Non-Breaking Reuse | **PASS** |
| Inspector Statutory Workflows Regression-Free | **PASS** |
| Static Analysis & Test Pass | **PASS** |

### **Overall Status: PASS** *(with documented MVP name-only authentication limitation)*
