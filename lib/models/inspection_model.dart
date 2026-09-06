import 'dart:convert';
import 'evidence_model.dart';

enum InspectionType {
  safety,
  strata,
  ventilation,
  electrical,
  machinery,
  environmental,
  production,
  labour,
}

extension InspectionTypeExtension on InspectionType {
  String get value {
    switch (this) {
      case InspectionType.safety:
        return 'safety';
      case InspectionType.strata:
        return 'strata';
      case InspectionType.ventilation:
        return 'ventilation';
      case InspectionType.electrical:
        return 'electrical';
      case InspectionType.machinery:
        return 'machinery';
      case InspectionType.environmental:
        return 'environmental';
      case InspectionType.production:
        return 'production';
      case InspectionType.labour:
        return 'labour';
    }
  }

  static InspectionType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'strata':
        return InspectionType.strata;
      case 'ventilation':
        return InspectionType.ventilation;
      case 'electrical':
        return InspectionType.electrical;
      case 'machinery':
        return InspectionType.machinery;
      case 'environmental':
        return InspectionType.environmental;
      case 'production':
        return InspectionType.production;
      case 'labour':
        return InspectionType.labour;
      case 'safety':
      default:
        return InspectionType.safety;
    }
  }

  String get displayName {
    switch (this) {
      case InspectionType.safety:
        return 'Safety Inspection';
      case InspectionType.strata:
        return 'Strata & Roof Support';
      case InspectionType.ventilation:
        return 'Ventilation & Gas Audit';
      case InspectionType.electrical:
        return 'Electrical & FLP Audit';
      case InspectionType.machinery:
        return 'HEMM & Machinery Safety';
      case InspectionType.environmental:
        return 'Environmental Compliance';
      case InspectionType.production:
        return 'Production Audit';
      case InspectionType.labour:
        return 'Labour & Welfare Compliance';
    }
  }

  String get hindiDisplayName {
    switch (this) {
      case InspectionType.safety:
        return 'सुरक्षा निरीक्षण';
      case InspectionType.strata:
        return 'छत एवं साइड सपोर्ट';
      case InspectionType.ventilation:
        return 'वेंटिलेशन एवं गैस जांच';
      case InspectionType.electrical:
        return 'विद्युत एवं FLP ऑडिट';
      case InspectionType.machinery:
        return 'मशीनरी एवं डंपर सुरक्षा';
      case InspectionType.environmental:
        return 'पर्यावरण अनुपालन';
      case InspectionType.production:
        return 'उत्पादन ऑडिट';
      case InspectionType.labour:
        return 'श्रम एवं कल्याण';
    }
  }
}

enum RecordStatus {
  draft,
  pendingSync,
  syncing,
  synced,
  syncFailed,
  underReview,
  resolved,
}

extension RecordStatusExtension on RecordStatus {
  String get value {
    switch (this) {
      case RecordStatus.draft:
        return 'draft';
      case RecordStatus.pendingSync:
        return 'pending_sync';
      case RecordStatus.syncing:
        return 'syncing';
      case RecordStatus.synced:
        return 'synced';
      case RecordStatus.syncFailed:
        return 'sync_failed';
      case RecordStatus.underReview:
        return 'under_review';
      case RecordStatus.resolved:
        return 'resolved';
    }
  }

  static RecordStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'pending_sync':
        return RecordStatus.pendingSync;
      case 'syncing':
        return RecordStatus.syncing;
      case 'synced':
        return RecordStatus.synced;
      case 'sync_failed':
        return RecordStatus.syncFailed;
      case 'under_review':
        return RecordStatus.underReview;
      case 'resolved':
        return RecordStatus.resolved;
      case 'draft':
      default:
        return RecordStatus.draft;
    }
  }

  String get displayName {
    switch (this) {
      case RecordStatus.draft:
        return 'Draft';
      case RecordStatus.pendingSync:
        return 'Waiting for internet';
      case RecordStatus.syncing:
        return 'Syncing...';
      case RecordStatus.synced:
        return 'Sent';
      case RecordStatus.syncFailed:
        return 'Sync Failed';
      case RecordStatus.underReview:
        return 'Under Review';
      case RecordStatus.resolved:
        return 'Resolved';
    }
  }

  bool get isLocked => this != RecordStatus.draft;
}

enum CheckItemStatus { pass, fail, na, unanswered }

enum ViolationSeverity { minor, major, critical }

class InspectionChecklistItem {
  final String id;
  final String section;
  final String question;
  final String guidance;
  final String hindiQuestion;
  CheckItemStatus status;
  ViolationSeverity? severity;
  String? violationDescription;
  String? remarks;
  String? correctiveAction;
  DateTime? deadline;
  List<EvidenceItem> evidence;

  InspectionChecklistItem({
    required this.id,
    required this.section,
    required this.question,
    required this.guidance,
    required this.hindiQuestion,
    this.status = CheckItemStatus.unanswered,
    this.severity,
    this.violationDescription,
    this.remarks,
    this.correctiveAction,
    this.deadline,
    List<EvidenceItem>? evidence,
  }) : evidence = evidence ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'section': section,
      'question': question,
      'guidance': guidance,
      'hindi_question': hindiQuestion,
      'status': status.name,
      'severity': severity?.name,
      'violation_description': violationDescription,
      'remarks': remarks,
      'corrective_action': correctiveAction,
      'deadline': deadline?.toIso8601String(),
      'evidence': evidence.map((e) => e.toMap()).toList(),
    };
  }

  factory InspectionChecklistItem.fromMap(Map<String, dynamic> map) {
    return InspectionChecklistItem(
      id: map['id'] as String,
      section: map['section'] as String,
      question: map['question'] as String,
      guidance: (map['guidance'] as String?) ?? '',
      hindiQuestion: (map['hindi_question'] as String?) ?? '',
      status: CheckItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CheckItemStatus.unanswered,
      ),
      severity: map['severity'] != null
          ? ViolationSeverity.values.firstWhere(
              (e) => e.name == map['severity'],
              orElse: () => ViolationSeverity.minor,
            )
          : null,
      violationDescription: map['violation_description'] as String?,
      remarks: map['remarks'] as String?,
      correctiveAction: map['corrective_action'] as String?,
      deadline: map['deadline'] != null
          ? DateTime.tryParse(map['deadline'] as String)
          : null,
      evidence:
          (map['evidence'] as List<dynamic>?)
              ?.map((e) => EvidenceItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class InspectionReport {
  final String clientUuid;
  final String? serverId;
  final String mineId;
  final String mineName;
  final String userId;
  final String userName;
  final String userDesignation;
  final InspectionType type;
  RecordStatus status;
  final DateTime createdAt;
  DateTime? submittedAt;
  DateTime updatedAt;
  int version;

  // Location
  double? latitude;
  double? longitude;
  double? accuracy;
  String locationSource; // 'gps' | 'gps_low' | 'manual'
  String? zoneId;
  String? zoneName;

  // Items
  List<InspectionChecklistItem> checklist;

  // General Evidence & Signatures
  List<EvidenceItem> globalEvidence;
  String? signatureBase64;
  String? signatureHash;
  DateTime? signedAt;

  // Audit / Integrity
  String? integrityHash;
  String? syncError;

  InspectionReport({
    required this.clientUuid,
    this.serverId,
    required this.mineId,
    required this.mineName,
    required this.userId,
    required this.userName,
    required this.userDesignation,
    required this.type,
    this.status = RecordStatus.draft,
    required this.createdAt,
    this.submittedAt,
    required this.updatedAt,
    this.version = 1,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationSource = 'manual',
    this.zoneId,
    this.zoneName,
    required this.checklist,
    List<EvidenceItem>? globalEvidence,
    this.signatureBase64,
    this.signatureHash,
    this.signedAt,
    this.integrityHash,
    this.syncError,
  }) : globalEvidence = globalEvidence ?? [];

  Map<String, dynamic> toDbMap() {
    return {
      'client_uuid': clientUuid,
      'server_id': serverId,
      'mine_id': mineId,
      'mine_name': mineName,
      'user_id': userId,
      'user_name': userName,
      'user_designation': userDesignation,
      'type': type.value,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'location_source': locationSource,
      'zone_id': zoneId,
      'zone_name': zoneName,
      'checklist_json': jsonEncode(checklist.map((e) => e.toMap()).toList()),
      'global_evidence_json': jsonEncode(
        globalEvidence.map((e) => e.toMap()).toList(),
      ),
      'signature_base64': signatureBase64,
      'signature_hash': signatureHash,
      'signed_at': signedAt?.toIso8601String(),
      'integrity_hash': integrityHash,
      'sync_error': syncError,
    };
  }

  factory InspectionReport.fromDbMap(Map<String, dynamic> map) {
    List<InspectionChecklistItem> checklist = [];
    if (map['checklist_json'] != null) {
      final decoded = jsonDecode(map['checklist_json'] as String) as List;
      checklist = decoded
          .map(
            (e) => InspectionChecklistItem.fromMap(e as Map<String, dynamic>),
          )
          .toList();
    }

    List<EvidenceItem> globalEvidence = [];
    if (map['global_evidence_json'] != null) {
      final decoded = jsonDecode(map['global_evidence_json'] as String) as List;
      globalEvidence = decoded
          .map((e) => EvidenceItem.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return InspectionReport(
      clientUuid: map['client_uuid'] as String,
      serverId: map['server_id'] as String?,
      mineId: map['mine_id'] as String,
      mineName: map['mine_name'] as String,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userDesignation: map['user_designation'] as String,
      type: InspectionTypeExtension.fromString(map['type'] as String),
      status: RecordStatusExtension.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      submittedAt: map['submitted_at'] != null
          ? DateTime.tryParse(map['submitted_at'] as String)
          : null,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      version: (map['version'] as int?) ?? 1,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      locationSource: (map['location_source'] as String?) ?? 'manual',
      zoneId: map['zone_id'] as String?,
      zoneName: map['zone_name'] as String?,
      checklist: checklist,
      globalEvidence: globalEvidence,
      signatureBase64: map['signature_base64'] as String?,
      signatureHash: map['signature_hash'] as String?,
      signedAt: map['signed_at'] != null
          ? DateTime.tryParse(map['signed_at'] as String)
          : null,
      integrityHash: map['integrity_hash'] as String?,
      syncError: map['sync_error'] as String?,
    );
  }

  // Pre-configured questions for Statutory Inspections & Audits
  static List<InspectionChecklistItem> getDefaultChecklist(
    InspectionType type,
  ) {
    switch (type) {
      case InspectionType.safety:
        return getDefaultSafetyChecklist();
      case InspectionType.strata:
        return getDefaultStrataChecklist();
      case InspectionType.ventilation:
        return getDefaultVentilationChecklist();
      case InspectionType.electrical:
        return getDefaultElectricalChecklist();
      case InspectionType.machinery:
        return getDefaultMachineryChecklist();
      case InspectionType.environmental:
        return getDefaultEnvironmentalChecklist();
      case InspectionType.labour:
        return getDefaultLabourChecklist();
      case InspectionType.production:
        return [
          InspectionChecklistItem(
            id: 'chk_prod_1',
            section: 'SHIFT EXTRACTION LOG',
            question: 'Is coal/mineral extraction aligning with approved slicing height & face advance?',
            guidance: 'Verify statutory extraction line and bench height limits.',
            hindiQuestion: 'क्या कोयला/खनिज निष्कर्षण अनुमोदित योजना के अनुसार है?',
          ),
          InspectionChecklistItem(
            id: 'chk_prod_2',
            section: 'HAULAGE CAPACITY',
            question: 'Are conveyor transfer points and chutes free of spillage and blockages?',
            guidance: 'Check belt alignment and sequence control trip switches.',
            hindiQuestion: 'क्या कन्वेयर और हॉलेज मार्ग बिना किसी रुकावट के चल रहे हैं?',
          ),
          InspectionChecklistItem(
            id: 'chk_prod_3',
            section: 'STATUTORY SHIFT LOG',
            question: 'Has the Overman/Sirdar verified shift handover logs in statutory Form-IV?',
            guidance: 'Ensure daily production and safety issues are logged and signed.',
            hindiQuestion: 'क्या शिफ्ट हैंडओवर और ओवरमैन लॉगबुक में हस्ताक्षर दर्ज हैं?',
          ),
        ];
    }
  }

  static List<InspectionChecklistItem> getDefaultSafetyChecklist() {
    return [
      InspectionChecklistItem(
        id: 'chk_ppe_1',
        section: 'CMR 2017 REG 180 / PPE',
        question: 'Are workers wearing mandatory safety gear (Hard Hat, Cap Lamp, Boots & Self-Rescuer)?',
        guidance: 'Check for high-visibility reflective vests, chin-straps, and functional cap lamps.',
        hindiQuestion: 'क्या सभी श्रमिक अनिवार्य सुरक्षा उपकरण (PPE, हेलमेट, जूते, सेल्फ-रेस्क्युअर) पहन रहे हैं?',
      ),
      InspectionChecklistItem(
        id: 'chk_vent_2',
        section: 'CMR 2017 REG 153 / VENTILATION',
        question: 'Is auxiliary ventilation operating with continuous air velocity >= 0.5 m/s at the working face?',
        guidance: 'Verify ventilation ducting integrity, overlap distance <= 4.5m and zero air leakage.',
        hindiQuestion: 'क्या वेंटिलेशन नलिकाएं सही स्थिति में हैं और हवा की गति पर्याप्त (>= 0.5 m/s) है?',
      ),
      InspectionChecklistItem(
        id: 'chk_meth_3',
        section: 'CMR 2017 REG 156 / GAS MONITORING',
        question: 'Are methane (CH4) levels below 0.75% and Carbon Monoxide (CO) < 50 ppm in general body?',
        guidance: 'Perform multi-gas detection at active coal face roof cavity and return airways.',
        hindiQuestion: 'क्या मीथेन (<0.75%) और कार्बन मोनोऑक्साइड (<50 ppm) सुरक्षित सीमा में हैं?',
      ),
      InspectionChecklistItem(
        id: 'chk_roof_4',
        section: 'CMR 2017 REG 123 / STRATA CONTROL',
        question: 'Are roof bolts, W-straps, and wire mesh supports structurally sound with zero sag or spalling?',
        guidance: 'Inspect dual-height tell-tales and check for freshly spalled coal ribs or roof fractures.',
        hindiQuestion: 'क्या छत और दीवारों के बोल्ट और वायर मेश मजबूत हैं और कोई झुकना/दरार नहीं है?',
      ),
      InspectionChecklistItem(
        id: 'chk_dust_5',
        section: 'CMR 2017 REG 143 / DUST SUPPRESSION',
        question: 'Are atomizing water sprays active on shearer/continuous miner with water pressure >= 3 bar?',
        guidance: 'Verify dust suppression curtains and adequate stone dusting across haul roads.',
        hindiQuestion: 'क्या धूल दमन के लिए वाटर स्प्रे सिस्टम चालू और पर्याप्त दबाव पर हैं?',
      ),
      InspectionChecklistItem(
        id: 'chk_comm_6',
        section: 'CMR 2017 REG 85 / EMERGENCY COMMS',
        question: 'Is intrinsically-safe communication network operational between face and surface control room?',
        guidance: 'Test clear communication and verify audio-visual alarm beacon functions.',
        hindiQuestion: 'क्या भूमिगत संचार तंत्र (फोन/वायरलेस) और आपातकालीन अलार्म पूरी तरह सक्रिय हैं?',
      ),
    ];
  }

  static List<InspectionChecklistItem> getDefaultStrataChecklist() {
    return [
      InspectionChecklistItem(
        id: 'chk_strata_1',
        section: 'CMR 2017 REG 123 / SCP PLAN',
        question: 'Is the Strata Control and Monitoring Plan (SCMP) strictly enforced with tell-tale readings within green limits?',
        guidance: 'Check optical strata tell-tales (< 5mm movement in anchor A, < 10mm in anchor B).',
        hindiQuestion: 'क्या टेल-टेल संकेतक सामान्य सीमा (<5mm) में हैं और कोई अत्यधिक विस्थापन नहीं है?',
      ),
      InspectionChecklistItem(
        id: 'chk_strata_2',
        section: 'DGMS TECH CIR 03/2020 / BOLTING',
        question: 'Are resin roof bolts installed at specified grid density with anchorage capacity >= 10 tonnes?',
        guidance: 'Verify resin encapsulation length and torquing tightness on torque wrench.',
        hindiQuestion: 'क्या रूफ बोल्ट तय ग्रिड दूरी पर लगाए गए हैं और उनकी ग्रिप क्षमता (10 टन) मजबूत है?',
      ),
      InspectionChecklistItem(
        id: 'chk_strata_3',
        section: 'CMR 2017 REG 124 / SIDE SUPPORTS',
        question: 'Are coal ribs/sides properly dressed, wire-meshed, and lagged to prevent sidewall spalling?',
        guidance: 'Inspect side bolts on junctions and ensure overhangs are barred down immediately.',
        hindiQuestion: 'क्या कोयले की दीवारों पर साइड बोल्टिंग और वायर मेश ठीक से लगा है?',
      ),
      InspectionChecklistItem(
        id: 'chk_strata_4',
        section: 'CMR 2017 REG 127 / JUNCTION SUPPORT',
        question: 'Are all gallery intersections/junctions reinforced with extra cable bolts or steel props?',
        guidance: 'Check junction diagonal cross-strapping and absence of bed separation.',
        hindiQuestion: 'क्या सभी जंक्शनों पर अतिरिक्त केबल बोल्टिंग और सुरक्षा बीम लगाई गई हैं?',
      ),
    ];
  }

  static List<InspectionChecklistItem> getDefaultVentilationChecklist() {
    return [
      InspectionChecklistItem(
        id: 'chk_vent_gas_1',
        section: 'CMR 2017 REG 153 / MAIN FAN',
        question: 'Is main mechanical ventilator running at required water gauge pressure with zero unexpected stoppage?',
        guidance: 'Check recording water gauge charts and air quantity reaching split districts.',
        hindiQuestion: 'क्या मुख्य वेंटिलेशन पंखा सही दबाव और पर्याप्त वायु मात्रा के साथ चल रहा है?',
      ),
      InspectionChecklistItem(
        id: 'chk_vent_gas_2',
        section: 'CMR 2017 REG 154 / AIR QUANTITY',
        question: 'Is minimum air velocity >= 0.5 m/s at working face and air quantity >= 6 m3/min per person?',
        guidance: 'Verify anemometer measurements recorded in statutory ventilation book.',
        hindiQuestion: 'क्या कार्यस्थल पर हवा की गति (>= 0.5 m/s) और प्रति व्यक्ति वायु मात्रा नियम अनुसार है?',
      ),
      InspectionChecklistItem(
        id: 'chk_vent_gas_3',
        section: 'CMR 2017 REG 156 / FLAMMABLE GAS',
        question: 'Are CH4 levels below 0.5% in intake airway and below 0.75% in return airway of the district?',
        guidance: 'Use calibrated methanometer and check automatic methane sensor trip limits.',
        hindiQuestion: 'क्या मीथेन गैस इंटेक में <0.5% और रिटर्न में <0.75% के सुरक्षित स्तर पर है?',
      ),
      InspectionChecklistItem(
        id: 'chk_vent_gas_4',
        section: 'CMR 2017 REG 161 / STOPPINGS & DOORS',
        question: 'Are ventilation stoppings, airlock doors, and brattices airtight without damage or air leakage?',
        guidance: 'Inspect masonry ventilation stoppings for plaster cracks and ensure airlock doors close automatically.',
        hindiQuestion: 'क्या वेंटिलेशन दरवाजे, स्टॉपिंग्स और ब्रैटिस बिना किसी रिसाव के पूरी तरह बंद हैं?',
      ),
    ];
  }

  static List<InspectionChecklistItem> getDefaultElectricalChecklist() {
    return [
      InspectionChecklistItem(
        id: 'chk_elec_1',
        section: 'CEA REG 2010 REG 116 / FLP ENCLOSURE',
        question: 'Are all FLP switchgear, gate end boxes, and junction boxes sealed with certified gap clearance (< 0.5mm)?',
        guidance: 'Use feeler gauge to test flameproof flange gaps and ensure all bolts are present & tight.',
        hindiQuestion: 'क्या सभी फ्लेमप्रूफ (FLP) बॉक्स और स्विच ठीक से सीलबंद हैं और कोई गैप नहीं है?',
      ),
      InspectionChecklistItem(
        id: 'chk_elec_2',
        section: 'CEA REG 2010 REG 118 / EARTH LEAKAGE',
        question: 'Are Earth Leakage Protection relays (ELR) operational and tripping within statutory 100ms / 750mA limits?',
        guidance: 'Perform test push-button trip check on sub-station gate-end box.',
        hindiQuestion: 'क्या अर्थ लीकेज प्रोटेक्शन रिले (ELR) तुरंत ट्रिप होकर विद्युत सप्लाई काट रहा है?',
      ),
      InspectionChecklistItem(
        id: 'chk_elec_3',
        section: 'CEA REG 2010 REG 122 / TRAILING CABLES',
        question: 'Are heavy flexible trailing cables free from kinks, cuts, tape joints, or mechanical pinching?',
        guidance: 'Ensure cables are suspended on insulated porcelain hangers away from moving machinery.',
        hindiQuestion: 'क्या ट्रेलिंग केबल बिना किसी कट या जोड़ के सुरक्षित हैंगर पर लटके हुए हैं?',
      ),
      InspectionChecklistItem(
        id: 'chk_elec_4',
        section: 'CEA REG 2010 REG 124 / INTRINSIC SAFETY',
        question: 'Are underground communication and telemetry circuits intrinsically safe (IS) with certified barriers?',
        guidance: 'Verify Zener barrier integrity in master telemetry distribution panel.',
        hindiQuestion: 'क्या संचार और टेलीमेट्री सर्किट इंट्रिंसिकली सेफ (IS प्रमाणित) हैं?',
      ),
    ];
  }

  static List<InspectionChecklistItem> getDefaultMachineryChecklist() {
    return [
      InspectionChecklistItem(
        id: 'chk_mach_1',
        section: 'DGMS TECH CIR / HEMM BRAKES',
        question: 'Are service and emergency/parking brakes on dumpers, loaders, and haulage haulers 100% effective?',
        guidance: 'Perform ramp hold test at 1-in-10 gradient under full load conditions.',
        hindiQuestion: 'क्या डंपर और लोडरों के सर्विस व इमरजेंसी ब्रेक पूरी तरह कार्यशील हैं?',
      ),
      InspectionChecklistItem(
        id: 'chk_mach_2',
        section: 'DGMS CIR 02/2019 / AUDIO-VISUAL ALARM',
        question: 'Is the Audio-Visual Alarm (AVA) operating automatically upon engaging reverse gear?',
        guidance: 'Verify decibel sound output >= 85 dB and high-intensity strobe flasher visibility.',
        hindiQuestion: 'क्या रिवर्स गियर लगाने पर ऑडियो-विज़ुअल अलार्म (AVA) और फ्लैशर तुरंत बजता है?',
      ),
      InspectionChecklistItem(
        id: 'chk_mach_3',
        section: 'CMR 2017 REG 176 / FIRE SUPPRESSION (AFSDS)',
        question: 'Is Automatic Fire Detection & Suppression System (AFSDS) pressurized and ready in engine compartment?',
        guidance: 'Inspect nitrogen cylinder pressure gauges and linear heat sensing cables.',
        hindiQuestion: 'क्या इंजन में स्वचालित अग्निशमन प्रणाली (AFSDS) का दबाव गेज सही स्थिति में है?',
      ),
      InspectionChecklistItem(
        id: 'chk_mach_4',
        section: 'DGMS CIR 05/2021 / PROXIMITY SENSOR',
        question: 'Are blind spot cameras, operator fatigue monitoring, and proximity warning sensors operational?',
        guidance: 'Check in-cab display monitor for clear camera view of blind zones.',
        hindiQuestion: 'क्या ब्लाइंड-स्पॉट कैमरा और ऑपरेटर चेतावनी सेंसर ठीक से काम कर रहे हैं?',
      ),
    ];
  }

  static List<InspectionChecklistItem> getDefaultEnvironmentalChecklist() {
    return [
      InspectionChecklistItem(
        id: 'chk_environmental_1',
        section: 'CMR 2017 REG 143 / DUST MONITORING',
        question: 'Is ambient respirable dust concentration within permissible threshold (< 2 mg/m3 with < 5% free silica)?',
        guidance: 'Check gravimetric dust sampler records and statutory personal sampling filters.',
        hindiQuestion: 'क्या हवा में धूल का स्तर वैधानिक सीमा (< 2 mg/m3) के भीतर है?',
      ),
      InspectionChecklistItem(
        id: 'chk_environmental_2',
        section: 'WATER POLLUTION ACT / MINE WATER DISCHARGE',
        question: 'Is mine discharge effluent treated with neutral pH (6.5 - 8.5) and suspended solids < 100 mg/L?',
        guidance: 'Verify sediment settling pond discharge point before release to public catchment.',
        hindiQuestion: 'क्या खदान से निकलने वाले पानी का pH और शोधन सही मानकों पर है?',
      ),
      InspectionChecklistItem(
        id: 'chk_environmental_3',
        section: 'HAUL ROAD SPRINKLING',
        question: 'Is high-capacity pressurized water tanker spraying regularly on haul roads to suppress fugitive dust?',
        guidance: 'Inspect haul roads for moisture retention and absence of dust plumes from dumpers.',
        hindiQuestion: 'क्या हॉल रोड पर नियमित रूप से पानी का छिड़काव किया जा रहा है?',
      ),
    ];
  }

  static List<InspectionChecklistItem> getDefaultLabourChecklist() {
    return [
      InspectionChecklistItem(
        id: 'chk_lab_1',
        section: 'MINES RULES 1955 RULE 40 / FIRST AID',
        question: 'Are statutory First-Aid stations fully equipped with stretchers, splints, dressings, and trained personnel on duty?',
        guidance: 'Check expiry dates of medicines, antiseptic solutions, and oxygen resuscitators.',
        hindiQuestion: 'क्या प्राथमिक उपचार स्टेशन (First-Aid) पर सभी आवश्यक दवाएं और प्रशिक्षित कर्मी मौजूद हैं?',
      ),
      InspectionChecklistItem(
        id: 'chk_lab_2',
        section: 'MINES RULES 1955 RULE 30 / DRINKING WATER',
        question: 'Is potable, tested drinking water provided at readily accessible points (>= 2 liters/person/shift)?',
        guidance: 'Verify water filter calibration and laboratory purity certificates.',
        hindiQuestion: 'क्या श्रमिकों के लिए पर्याप्त एवं शुद्ध पेयजल उपलब्ध कराया गया है?',
      ),
      InspectionChecklistItem(
        id: 'chk_lab_3',
        section: 'MINES VOCATIONAL TRAINING RULES',
        question: 'Are contractor workers and miners holding valid Periodic Medical Examination (PME) & VTC safety training cards?',
        guidance: 'Verify Form-B register and statutory safety induction badges.',
        hindiQuestion: 'क्या सभी श्रमिकों का मेडिकल (PME) और सुरक्षा प्रशिक्षण (VTC) पूरा और वैध है?',
      ),
    ];
  }
}
