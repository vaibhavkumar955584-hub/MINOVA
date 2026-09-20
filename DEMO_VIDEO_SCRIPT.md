# 🎬 MINOVA Demo Video Script (5-Person Team Presentation)

**Theme**: *Smart Indian Hackathon (SIH) — Next-Gen Mining Safety & Emergency Response Ecosystem*  
**Duration**: 4 to 5 Minutes  
**Characters & Roles**:
1. **Speaker 1 (Lead Presenter / Problem Context & Architecture)**: Sets the stage, introduces MINOVA, core challenges in underground mining, and the dual-role architecture.
2. **Speaker 2 (Statutory Inspector / Form-D & Inspection Workflows)**: Walks through statutory compliance, Form-D muster, AI voice reporting, and offline draft auto-save.
3. **Speaker 3 (Security & Tamper Proofing Lead)**: Demonstrates the tamper-evident SHA-256 evidence hashing, cryptographic signatures, and subterranean GPS fallbacks.
4. **Speaker 4 (Field Responder / Specialist Coal Mine Worker)**: Onboards as an Employee, selects Specialist category (e.g. Fire & Safety / Electrical), receives real-time emergency broadcast, and reviews map details.
5. **Speaker 5 (Offline-First Sync Engine & Closing Presenter)**: Shows offline incident reporting, background sync queue with exponential backoff, Firestore integration, and closing impact pitch.

---

## 🕒 Timing & Scene Breakdown

```
[0:00 - 0:45] ── Scene 1: Introduction & Dual-Role Paradigm (Speaker 1)
[0:45 - 1:45] ── Scene 2: Statutory Inspector Experience & Form-D (Speaker 2)
[1:45 - 2:30] ── Scene 3: Forensic Evidence & Subterranean Location (Speaker 3)
[2:30 - 3:30] ── Scene 4: Employee Field Responder & Emergency Broadcast (Speaker 4)
[3:30 - 4:15] ── Scene 5: Offline-First Zero-Loss Sync Engine (Speaker 5)
[4:15 - 4:45] ── Scene 6: Conclusion & Impact Pitch (All / Speaker 1)
```

---

## 🎥 SCENE 1: Introduction, Problem Statement & Dual-Role Entry (0:00 – 0:45)
**Visual on Screen**: 
- High-impact animated title or MINOVA splash screen.
- First app launch showing the **"What is your role?"** selection screen ([ Inspector ] vs [ Employee ]).

**🎙️ Speaker 1 (Lead Presenter)**:
> *"Respected Judges, Indian coal mines operate in some of the harshest and most hazardous environments on earth. Traditional statutory compliance is hindered by slow paperwork, lack of offline reliability 500 meters underground, and disconnected emergency response.*
>
> *Introducing **MINOVA** — a unified, offline-first mobile terminal designed specifically for DGMS statutory compliance and real-time field emergency response.*
>
> *Right at the entrance, MINOVA introduces a role-isolated dual architecture: **Statutory Inspectors** who manage compliance, muster, and safety audits, and **Field Responders** — the specialist miners on the frontline who respond to emergencies. Let's see how our Inspector operates."*

---

## 🎥 SCENE 2: Statutory Inspector Experience & Form-D Attendance (0:45 – 1:45)
**Visual on Screen**:
- Tap **[ Inspector ]** → Quick biometric / MPIN unlock → Home Dashboard opens.
- Show Dashboard widgets: Live Shift Telemetry, Gas Safety indicators, Compliance status.
- Tap **Form-D Attendance**: Show worker muster, shift selection (Shift A, 1st Pit), biometric face/OCR scanning demo, and signing off on the statutory muster.

**🎙️ Speaker 2 (Inspector Role Walkthrough)**:
> *"Logging in as a Statutory Inspector, I am greeted by the high-contrast industrial dashboard, showing real-time atmospheric telemetry and pending compliance audits.*
>
> *Under the Mines Act, daily statutory muster is mandatory. With MINOVA's Form-D module, I can register underground workers, verify shifts, and capture automated muster logs in seconds.*
>
> *When conducting a Safety Inspection in deep coal seams, MINOVA allows structured violation logging across ventilation, strata control, and heavy machinery — complete with multilingual voice assistance in both Hindi and English!"*

---

## 🎥 SCENE 3: Forensic Evidence Tamper-Proofing & Underground GPS (1:45 – 2:30)
**Visual on Screen**:
- Inspector opens an active inspection item and attaches photo evidence of a conveyor belt hazard.
- Show the **SHA-256 Tamper Hash** generated instantly on the image metadata.
- Show the GPS status: When subterranean satellite signal is lost, the app smoothly switches to **"Zone: Subterranean Seam 4 / Panel B"**.
- Inspector applies digital signature on the canvas and submits.

**🎙️ Speaker 3 (Security & Tamper Proofing Lead)**:
> *"Underground evidence integrity is critical for legal inquiries. Notice what happened when an image was captured:*
>
> *MINOVA immediately computes a client-side **SHA-256 cryptographic hash** embedded with timestamps and device coordinates. If anyone tries to manipulate the image or database later, the integrity hash fails instantly.*
>
> *Furthermore, deep underground where GPS signals cannot reach, MINOVA's subterranean positioning engine seamlessly falls back to pre-configured manual mine zones with zero crash or lag. Once signed, the report is cryptographically sealed and immutable."*

---

## 🎥 SCENE 4: Employee Field Responder, Specialist Setup & Emergency Broadcast (2:30 – 3:30)
**Visual on Screen**:
- App switches to **Employee Flow** (or second phone screen).
- Onboarding: Enter Name (*"Ramesh Kumar"*), select Mine (*"Raniganj Deep Coal Seam"*), select Specialist Category (*"Fire & Safety"* with red flame badge).
- Employee Home Dashboard loads: High-contrast Emergency Responder theme.
- **Push Notification Arrives**: `🚨 CRITICAL EMERGENCY: Underground Fire / Heating in Workshop Panel 4`.
- Tap Notification → Opens **Emergency Detail Screen** showing exact underground location, safety instructions, and action buttons (`[ OPEN LOCATION ]`, `[ REPORT INCIDENT ]`).

**🎙️ Speaker 4 (Field Responder & Emergency Lead)**:
> *"Now, let’s look at the miner on the frontline. When an employee opens MINOVA for the first time, they enter their name and select their **Specialist Category** — for example, Fire & Safety or Electrical Maintenance.*
>
> *The Employee UI is clean, bold, and strictly isolated: no complicated inspection forms, strictly focused on alerts and incidents.*
>
> *Suddenly, an emergency alert is broadcast from mine management! The notification pops up with full priority. Tapping the alert opens the dedicated Emergency Terminal, giving the exact sector location, severity level, and critical evacuation instructions. From here, the responder can immediately launch into an Incident Report with pre-filled hazard context."*

---

## 🎥 SCENE 5: Offline-First Zero-Loss Sync Engine (3:30 – 4:15)
**Visual on Screen**:
- Turn phone to **Airplane Mode (No Internet)**.
- Tap **[ REPORT INCIDENT ]** → Fill out casualty/equipment fields → Tap **Submit Incident**.
- Show toast: *"Saved locally to offline sync queue"*.
- Turn Airplane Mode **OFF (Internet Restored)**.
- App sync indicator spins → Green checkmark: *"Synced to Cloud Firestore & Cloudinary"*. Show Cloud Firestore dashboard update if possible.

**🎙️ Speaker 5 (Sync Engine & Cloud Architecture Lead)**:
> *"In a coal mine, internet connectivity is non-existent underground. Watch this: we completely disconnect the network.*
>
> *The responder fills out the incident report and submits. MINOVA's offline-first architecture writes directly to local SQLite with unique client UUIDs and queues the payload.*
>
> *The moment the responder reaches the shaft elevator and regains Wi-Fi or 4G, our Universal Sync Engine automatically wakes up, executes idempotent uploads with bounded exponential backoff, uploads media evidence to Cloudinary, and updates Cloud Firestore in real time. Zero data loss. Zero duplicates."*

---

## 🎥 SCENE 6: Impact & Conclusion (4:15 – 4:45)
**Visual on Screen**:
- Split screen showing both Inspector and Employee devices working in harmony, or team members holding the devices.
- Summary slide: Full DGMS Statutory Compliance • 100% Offline-First • Tamper-Proof Cryptography • Rapid Emergency Response.

**🎙️ Speaker 1 / All Team Members Together**:
> **Speaker 1**: *"MINOVA bridges the critical gap between top-down statutory compliance and ground-level emergency safety."*
>
> **Speaker 2**: *"Empowering inspectors with legally sound, tamper-proof reporting."*
>
> **Speaker 4**: *"Protecting frontline miners with instant emergency broadcasts."*
>
> **Speaker 5**: *"And guaranteeing zero data loss through industrial-grade offline sync."*
>
> **All together**: *"MINOVA — Safeguarding Indian Mines, One Seam at a Time. Thank you!"*

---

## 🛠️ Recording Tips for Maximum Impact:
1. **Screen Recording**: Use Android’s native 1080p 60fps screen recorder. Enable *Show Taps / Visual Touches* in Developer Options so judges see every click.
2. **Audio Setup**: Record each person's audio cleanly with a lapel mic or headset with background noise cancellation.
3. **Pacing**: Speak with crisp confidence, emphasizing statutory terms like *DGMS*, *Form-D*, *SHA-256*, and *Offline-First*.
4. **Dark Mode UI**: MINOVA's industrial dark theme looks stunning on screen — ensure your screen brightness is at 100% for high contrast.
