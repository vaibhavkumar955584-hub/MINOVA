# MINOVA (MineSafe) — Developer Project Breakdown & Interview Notes

> **Author / Developer:** Vaibhav Kumar  
> **Repository:** [https://github.com/vaibhavkumar955584-hub/MINOVA](https://github.com/vaibhavkumar955584-hub/MINOVA)  
> **Project Type:** Smart India Hackathon (SIH Problem Statement 26024)  
> **Tech Stack:** Flutter 3.x, Dart, Riverpod, SQLite, Firebase (Auth + Firestore), Cloudinary, Google ML Kit  
> **Status:** Completed & Tested on Android devices

---

## 1. How I Introduce the Project (My Elevator Pitch)

When an interviewer asks: *"Walk me through this project"*, this is how I explain it in plain terms:

> *"I built MINOVA (MineSafe), which is an offline-first mobile app designed for safety inspectors and supervisors working in underground coal mines.*
> 
> *The core challenge we tackled is that underground mines have practically zero internet connectivity, and current compliance work relies on paper logs that are easily forged, damaged, or submitted too late after hazards occur. 
> 
> *I built a system in Flutter where inspectors can fill out complex safety audits, incident reports, and attendance records completely offline. Everything saves locally to SQLite with automated draft recovery, gets cryptographically locked with a SHA-256 hash so it can't be tampered with after submission, and automatically syncs to Firebase and Cloudinary in the background as soon as the worker reaches the surface.*
> 
> *I also added an on-device OCR pipeline using Google ML Kit so inspectors can snap a photo of old physical mining logs and auto-extract the data without needing an internet connection."*

---

## 2. What Exactly I Built (My Role & Contributions)

I handled the full mobile engineering lifecycle and system architecture:

1. **State & Architecture:** Structured the codebase into clean layers (UI Features, Core Services, Repositories, DTOs) managed via Flutter Riverpod for deterministic state flow.
2. **Offline-First Synchronization Engine (`lib/core/sync/sync_engine.dart`):**
   - Built a FIFO queue in SQLite to track all pending submissions across 5 statutory forms (*Incidents, Inspections, Hazards/Observations, Attendance, Documents*).
   - Solved edge-case network dropouts by decoupling photo uploads (Cloudinary) from metadata writes (Firestore) with per-item idempotency.
3. **Hardware & Sensor Integrations:**
   - Built an in-app watermarking camera that bakes GPS coordinates and UTC timestamps into every evidence photo.
   - Built a subterranean location service that prevents location queries from hanging underground by falling back to cached coordinates or manual mine-shaft level selectors.
4. **Security & Data Integrity:**
   - Designed a tamper-proof submission lock: upon form submission, the app computes a SHA-256 checksum across form fields, signatures, and media hashes, making local records immutable.
   - Built a dual-layer authentication flow: Firebase Auth for online credential verification + biometric/6-digit MPIN storage in Android Keystore via `flutter_secure_storage` for offline app access.
5. **On-Device Document AI (`google_mlkit_text_recognition`):**
   - Integrated offline optical character recognition to extract shift logs, equipment numbers, and certificate details from physical paperwork.
6. **Industrial UI/UX (`lib/core/theme`):**
   - Implemented a high-contrast dark industrial theme with large touch targets (52px+) so workers can comfortably tap buttons while wearing safety gloves in dusty, low-light environments.

---

## 3. Tech Stack & Why I Chose Each Tool

| Technology | What I used it for | Why I picked it over alternatives |
|---|---|---|
| **Flutter & Dart** | Cross-platform mobile client | Fast UI rendering, native sensor access, single codebase for Android/iOS. |
| **Flutter Riverpod** | State management & Dependency Injection | Compile-safe, no `BuildContext` dependency in repositories, easily mockable for unit testing. |
| **SQLite (`sqflite`)** | Local relational storage & Sync Queue | Needed strict relational querying, draft autosave, and multi-table atomic transactions that key-value stores like Hive/SharedPreferences can't safely handle. |
| **Firebase Auth & Firestore** | Cloud user identity & canonical database | Fast prototyping, declarative security rules for Role-Based Access Control (RBAC), and reliable real-time listeners. |
| **Cloudinary REST API** | Evidence photo/video storage | Keeps Firestore documents lightweight (metadata only) and allows chunked media uploads with progress tracking. |
| **`crypto` (SHA-256)** | Tamper-evidence hashing | Legal compliance under DGMS regulations requires proof that safety logs weren't altered after an accident. |
| **Google ML Kit** | On-device OCR | Runs completely offline on the phone’s NPU/CPU without incurring cloud API costs or latency. |
| **`flutter_secure_storage`** | MPIN and session security | Encrypts authentication tokens using hardware-backed Android KeyStore / iOS Keychain. |

---

## 4. How the Offline Sync Engine Works Under the Hood

Here is how data flows from the moment an inspector taps "Submit" underground to when it reaches the cloud:

```
[ Inspector Taps Submit Underground ]
                │
                ▼
1. Generate Client UUID (v4)
2. Compute SHA-256 Checksum (Form Fields + Photos + Timestamp)
3. Write to local SQLite (`minesafe.db`) with status = 'SUBMITTED_LOCAL'
4. Enqueue job into `sync_queue` table
                │
    (Worker returns to surface / Wi-Fi connects)
                │
                ▼
[ Universal Sync Orchestrator triggers ]
5. Acquire in-flight mutex lock for this submission_id (prevents duplicate runs)
6. Upload any pending photos to Cloudinary -> get HTTPS URLs back
7. Map SQLite record into a validated, typed DTO (Data Transfer Object)
8. Write canonical document to Firestore using the stable submission_id
9. Mark local record & sync_queue entry as 'SYNCED'
10. Release mutex lock
```

---

## 5. Real Engineering Challenges I Faced & How I Fixed Them

These are great talking points when an interviewer asks: *"Tell me about a difficult bug or challenge you solved."*

### 1. Handling Large Photo Uploads over Flaky 2G Connections at Mine Entrances
* **The Problem:** In deep mines, network signal is unstable. When an inspector walked near the pit entrance, the app would detect internet and try to send the entire form + 4 high-res photos at once. If the upload dropped halfway, the whole transaction failed, resulting in duplicated Firestore documents when retried.
* **How I fixed it:** I separated binary uploads from document creation. The sync engine uploads images one by one to Cloudinary and immediately updates their local status to `uploaded` with the returned URL. Only when all images succeed does it send the final JSON payload to Firestore using an idempotent document ID (`submission_id`). If the signal drops on image #3, the next retry picks up right at image #3 instead of starting over.

### 2. GPS Blocking the App Underground
* **The Problem:** Calling `Geolocator.getCurrentPosition()` underground caused the UI to hang or time out after 30+ seconds because satellites are unreachable through 200 meters of solid rock.
* **How I fixed it:** I wrapped the location service in a 5-second non-blocking timeout. If high-accuracy GPS fails to resolve within 5 seconds, the service automatically falls back to the last known surface coordinate or prompts the inspector to pick their designated underground seam / shaft level from a pre-configured mine map.

### 3. Race Conditions During Background Sync
* **The Problem:** When network reconnected, both the foreground Riverpod listener and a background `Workmanager` task would try to process the sync queue at the exact same millisecond, triggering duplicate network calls.
* **How I fixed it:** I implemented an in-memory lock set combined with a SQLite row status flag (`SYNCING`). If a submission ID is already in-flight, any subsequent sync trigger skips that item immediately.

### 4. Firestore Permission Errors with Custom Roles
* **The Problem:** We support 3 distinct roles (`inspector`, `contractor`, `mine_official`). Early in development, permission errors occurred because client-side code tried to initialize user profiles directly on Firestore.
* **How I fixed it:** I refactored the authorization model so the mobile app only performs read-only profile validation against an admin-provisioned collection, and hardened `firestore.rules` to enforce strict ownership checks (`request.auth.uid == resource.data.inspectorId`).

---

## 6. Common Interview Questions & My Direct Answers

#### Q: "Why didn't you just rely on Firebase's built-in offline persistence?"
> *"Firestore offline persistence is great for simple caching, but it operates as a black box. It doesn't let you inspect pending queue items, show per-item upload progress bars, retry individual failed photo uploads, or calculate SHA-256 hashes on the raw data before queuing. Using SQLite as our single source of truth gave us complete control over queue priority, draft autosave, and local validation."*

#### Q: "How did you ensure the app remains responsive on low-end rugged devices?"
> *"We offloaded heavy tasks like image compression, hashing, and database reads to background isolates using Dart’s `compute()`. We also used Riverpod's `select()` on UI widgets to prevent unnecessary widget rebuilds when only a single field in the state changes."*

#### Q: "How long did it take to build and what was the outcome?"
> *"The project was developed over approximately 4 to 6 weeks of focused sprints for the Smart India Hackathon. The current build is a fully tested MVP with 0 analyzer issues, passing integration tests, and verified end-to-end sync on physical Android devices."*

---

## 7. Project Metrics & Codebase Stats

* **Lines of Dart Code:** ~15,000+ lines across features, core utilities, and models.
* **Statutory Forms Supported:** 5 major categories (Inspection, Incident, Attendance, Observation, Documents).
* **Test Coverage:** Unit tests for submission validation, launcher shortcuts, and launch security flow (`test/`).
* **Linting / Code Health:** 0 warnings / 0 errors on `flutter analyze`.
