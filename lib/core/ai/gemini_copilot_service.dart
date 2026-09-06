import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../models/inspection_model.dart';
import '../../models/observation_model.dart';

/// Result of Gemini AI Copilot analyzing an observation / field hazard.
class GeminiObservationAnalysis {
  final String headline;
  final String refinedDescription;
  final ViolationSeverity suggestedSeverity;
  final ObservationCategory suggestedCategory;
  final String? statutoryRegulationHint;
  final String? recommendedImmediateAction;
  final bool isAiGenerated;

  const GeminiObservationAnalysis({
    this.headline = 'Statutory Field Observation',
    required this.refinedDescription,
    required this.suggestedSeverity,
    required this.suggestedCategory,
    this.statutoryRegulationHint,
    this.recommendedImmediateAction,
    this.isAiGenerated = true,
  });
}

/// Result of Gemini AI Copilot analyzing an emergency incident.
class GeminiIncidentAnalysis {
  final String headline;
  final String refinedDescription;
  final ViolationSeverity suggestedSeverity;
  final String suggestedImmediateAction;
  final bool medicalAttentionRecommended;
  final bool notifyAuthorityImmediately;
  final String? statutoryRegulation;
  final bool isAiGenerated;

  const GeminiIncidentAnalysis({
    this.headline = 'Statutory Emergency Incident',
    required this.refinedDescription,
    required this.suggestedSeverity,
    required this.suggestedImmediateAction,
    required this.medicalAttentionRecommended,
    required this.notifyAuthorityImmediately,
    this.statutoryRegulation,
    this.isAiGenerated = true,
  });
}

/// Zero-Billing / Free-Tier AI Copilot for Mining Inspectors.
/// Powered by Google Gemini 1.5 Flash (via Google AI Studio Free Tier)
/// with an intelligent offline statutory rule fallback when offline or without API key.
class GeminiCopilotService {
  final String _apiKey;

  GeminiCopilotService({
    String? apiKey,
  }) : _apiKey = apiKey ??
            const String.fromEnvironment(
              'GEMINI_API_KEY',
              defaultValue: '',
            );

  GenerativeModel? _createModel() {
    if (_apiKey.trim().isEmpty) return null;
    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Analyzes observation notes and multi-gas telemetry to suggest clean statutory phrasing,
  /// hazard severity, category, and DGMS / CMR 2017 regulation hints.
  Future<GeminiObservationAnalysis> analyzeObservation({
    required String rawNotes,
    double? ch4,
    int? co,
    double? o2,
  }) async {
    final model = _createModel();

    if (model != null && rawNotes.trim().isNotEmpty) {
      try {
        final prompt = '''
You are a statutory mining safety inspector AI expert in DGMS (Directorate General of Mines Safety) regulations, the Coal Mines Regulations (CMR) 2017, and Mines Rules 1955.
Analyze the following observation/hazard notes and atmospheric gas readings:

Raw Notes: "$rawNotes"
Gas Readings: CH4: ${ch4 ?? 'N/A'}%, CO: ${co ?? 'N/A'} PPM, O2: ${o2 ?? 'N/A'}%

Respond ONLY with a JSON object matching this schema:
{
  "headline": "Short 4-6 word statutory title (e.g. Strata Crack in Gallery 4)",
  "refined_description": "Clear, professional statutory observation narrative in English conforming to DGMS inspection reporting standards",
  "suggested_severity": "minor" | "major" | "critical",
  "suggested_category": "safety" | "environmental" | "labour" | "gasReading" | "other",
  "statutory_regulation_hint": "e.g. CMR 2017 Reg 123 (Strata Control & Support)",
  "recommended_immediate_action": "Concise, actionable statutory containment order"
}
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final jsonText = response.text;
        if (jsonText != null && jsonText.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(jsonText);
          return GeminiObservationAnalysis(
            headline: data['headline'] as String? ?? 'Statutory Observation',
            refinedDescription: data['refined_description'] as String? ?? rawNotes,
            suggestedSeverity: _parseSeverity(data['suggested_severity'] as String?),
            suggestedCategory: _parseCategory(data['suggested_category'] as String?),
            statutoryRegulationHint: data['statutory_regulation_hint'] as String?,
            recommendedImmediateAction: data['recommended_immediate_action'] as String?,
            isAiGenerated: true,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[GeminiCopilotService] Cloud API failed, using statutory offline fallback: $e');
        }
      }
    }

    // Offline Statutory Rule-Based Heuristic Fallback
    return _offlineObservationFallback(
      rawNotes: rawNotes,
      ch4: ch4,
      co: co,
      o2: o2,
    );
  }

  /// Analyzes emergency incident details and drafts statutory containment action.
  Future<GeminiIncidentAnalysis> analyzeIncident({
    required String incidentType,
    required String roughDescription,
  }) async {
    final model = _createModel();

    if (model != null && roughDescription.trim().isNotEmpty) {
      try {
        final prompt = '''
You are an expert statutory mining incident investigator under CMR 2017 and Mines Act 1952 Sec 23.
Analyze this emergency incident:
Type: $incidentType
Description: "$roughDescription"

Respond ONLY with a JSON object:
{
  "headline": "Short 4-6 word incident title",
  "refined_description": "Statutory incident narrative with sequence of events for DGMS Form-IVA",
  "suggested_severity": "minor" | "major" | "critical",
  "suggested_immediate_action": "Emergency containment, isolation, and first-aid response steps",
  "medical_attention_recommended": true | false,
  "notify_authority_immediately": true | false,
  "statutory_regulation": "e.g. Mines Act 1952 Sec 23 / CMR 2017 Reg 116"
}
''';

        final response = await model.generateContent([Content.text(prompt)]);
        final jsonText = response.text;
        if (jsonText != null && jsonText.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(jsonText);
          return GeminiIncidentAnalysis(
            headline: data['headline'] as String? ?? '$incidentType Incident',
            refinedDescription: data['refined_description'] as String? ?? roughDescription,
            suggestedSeverity: _parseSeverity(data['suggested_severity'] as String?),
            suggestedImmediateAction: data['suggested_immediate_action'] as String? ??
                'Evacuate affected district and isolate power supply.',
            medicalAttentionRecommended: data['medical_attention_recommended'] as bool? ?? true,
            notifyAuthorityImmediately: data['notify_authority_immediately'] as bool? ?? true,
            statutoryRegulation: data['statutory_regulation'] as String?,
            isAiGenerated: true,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[GeminiCopilotService] Cloud API failed, using statutory offline fallback: $e');
        }
      }
    }

    return _offlineIncidentFallback(
      incidentType: incidentType,
      roughDescription: roughDescription,
    );
  }

  // ── Comprehensive Offline Statutory Rule Heuristics (100% Free & Works Underground) ───

  GeminiObservationAnalysis _offlineObservationFallback({
    required String rawNotes,
    double? ch4,
    int? co,
    double? o2,
  }) {
    final lower = rawNotes.toLowerCase();
    ViolationSeverity severity = ViolationSeverity.minor;
    ObservationCategory category = ObservationCategory.safety;
    String headline = 'Statutory Inspection Note';
    String? regulationHint;
    String? action;
    String refinedDescription = rawNotes;

    // 1. Gas Threshold statutory checks (CMR 2017 Reg 153 / 159)
    if ((ch4 != null && ch4 >= 0.75) || (co != null && co >= 50) || (o2 != null && o2 < 19.0) ||
        lower.contains('gas') || lower.contains('methane') || lower.contains('ch4') ||
        lower.contains('co level') || lower.contains('suffocation') || lower.contains('dam ghut') ||
        lower.contains('hawa kam') || lower.contains('ventilation')) {
      headline = 'Ventilation & Gas Threshold Alert';
      severity = ViolationSeverity.critical;
      category = ObservationCategory.gasReading;
      regulationHint = 'CMR 2017 Reg 153 & 159: Inflammable & Noxious Gas Limit Exceeded';
      action = 'Immediately de-energize electrical circuits in return district, withdraw all personnel, and boost auxiliary ventilation airflow.';
      refinedDescription = rawNotes.isNotEmpty
          ? 'Atmospheric gas anomaly observed ($rawNotes). Methane/noxious gas concentrations flagged in breach of CMR 2017 Reg 153.'
          : 'Elevated inflammable gas levels detected during underground ventilation audit.';
    }
    // 2. Strata & Roof Safety (CMR 2017 Reg 123)
    else if (lower.contains('roof') || lower.contains('strata') || lower.contains('crack') ||
             lower.contains('fall') || lower.contains('chhat') || lower.contains('darar') ||
             lower.contains('girna') || lower.contains('patthar') || lower.contains('side fall') ||
             lower.contains('spalling') || lower.contains('prop') || lower.contains('bolt') ||
             lower.contains('support') || lower.contains('jharna')) {
      headline = 'Roof Strata & Support Non-Compliance';
      severity = ViolationSeverity.major;
      category = ObservationCategory.safety;
      regulationHint = 'CMR 2017 Reg 123: Strata Control & Systematic Support Rules (SSR)';
      action = 'Erect immediate supplementary resin roof bolts/props, conduct sound-testing of strata, and barricade insecure section.';
      refinedDescription = rawNotes.isNotEmpty
          ? 'Roof strata instability detected ($rawNotes). SSR compliance order issued under CMR 2017 Reg 123.'
          : 'Strata weakness and roof deterioration noted; supplementary support ordered under CMR Reg 123.';
    }
    // 3. Electrical & Flameproof (CEA Mines Regs 2010 / CMR Reg 180)
    else if (lower.contains('spark') || lower.contains('electric') || lower.contains('current') ||
             lower.contains('wire') || lower.contains('cable') || lower.contains('flp') ||
             lower.contains('switchgear') || lower.contains('bijli') || lower.contains('short circuit') ||
             lower.contains('earthing') || lower.contains('gland') || lower.contains('nanga')) {
      headline = 'Electrical Apparatus & FLP Violation';
      severity = ViolationSeverity.major;
      category = ObservationCategory.safety;
      regulationHint = 'CEA (Safety & Electric Supply) Reg 100 / CMR 2017 Reg 180';
      action = 'Isolate power at gate-end box, apply Lock-Out Tag-Out (LOTO), and rectify flameproof enclosure packing.';
      refinedDescription = rawNotes.isNotEmpty
          ? 'Electrical apparatus defect recorded ($rawNotes). Flameproof enclosure integrity breach flagged.'
          : 'Defective electrical cable/switchgear identified in hazardous underground district.';
    }
    // 4. Haulage, Conveyors & Heavy Machinery (CMR 2017 Reg 85-86)
    else if (lower.contains('haulage') || lower.contains('conveyor') || lower.contains('belt') ||
             lower.contains('tub') || lower.contains('rope') || lower.contains('derail') ||
             lower.contains('dumper') || lower.contains('tipper') || lower.contains('roller') ||
             lower.contains('guard') || lower.contains('brake')) {
      headline = 'Haulage & Transport Machinery Defect';
      severity = ViolationSeverity.major;
      category = ObservationCategory.safety;
      regulationHint = 'CMR 2017 Reg 85 & 86: Haulage Roadways & Machinery Safety Standards';
      action = 'Halt haulage line, inspect runaway catches/pull-wire switches, and replace worn drag rollers.';
      refinedDescription = rawNotes.isNotEmpty
          ? 'Haulage/conveyor track defect observed ($rawNotes). Statutory mechanical audit flagged under CMR 2017 Reg 85.'
          : 'Defective haulage system and missing machinery guards recorded during district round.';
    }
    // 5. Airborne Dust & Environmental (CMR 2017 Reg 143)
    else if (lower.contains('dust') || lower.contains('airborne') || lower.contains('smoke') ||
             lower.contains('dhul') || lower.contains('dhuan') || lower.contains('mist') ||
             lower.contains('spraying')) {
      headline = 'Airborne Dust Suppression Defect';
      severity = ViolationSeverity.minor;
      category = ObservationCategory.environmental;
      regulationHint = 'CMR 2017 Reg 143: Airborne Dust Suppression & Water Spraying';
      action = 'Activate high-pressure mist atomizers, clean intake spray nozzles, and wet transfer chutes.';
      refinedDescription = rawNotes.isNotEmpty
          ? 'Dust suppression deficiency recorded ($rawNotes). Water atomizer maintenance ordered under CMR Reg 143.'
          : 'High airborne dust concentration observed along main transport roadway.';
    }
    // 6. Inundation & Water Drainage (CMR 2017 Reg 176)
    else if (lower.contains('water') || lower.contains('sump') || lower.contains('flooding') ||
             lower.contains('seepage') || lower.contains('pani') || lower.contains('jalbhav') ||
             lower.contains('pump') || lower.contains('drainage')) {
      headline = 'Water Drainage & Inundation Hazard';
      severity = ViolationSeverity.minor;
      category = ObservationCategory.environmental;
      regulationHint = 'CMR 2017 Reg 176: Precautions Against Inundation & Water Inrush';
      action = 'Activate backup sludge dewatering pumps, clear silt from drainage channels, and monitor water barrier pillars.';
      refinedDescription = rawNotes.isNotEmpty
          ? 'Drainage inundation observed ($rawNotes). Compliance order under CMR 2017 Reg 176.'
          : 'Excessive water accumulation and drainage blockage noted in bottom roadway.';
    }
    // 7. Labour & Worker Welfare (Mines Rules 1955)
    else if (lower.contains('wage') || lower.contains('salary') || lower.contains('overtime') ||
             lower.contains('drinking water') || lower.contains('canteen') || lower.contains('rest shelter') ||
             lower.contains('toilet') || lower.contains('sanitation') || lower.contains('grievance') ||
             lower.contains('contract') || lower.contains('paani') || lower.contains('vetan') ||
             lower.contains('khana') || lower.contains('helmet') || lower.contains('boot') ||
             lower.contains('ppe')) {
      headline = 'Welfare & Amenity Non-Compliance';
      severity = ViolationSeverity.minor;
      category = ObservationCategory.labour;
      regulationHint = 'Mines Rules 1955 (Rules 30, 40-45: Welfare, Drinking Water & Sanitation)';
      action = 'Forward welfare non-compliance to Welfare Officer and Colliery Manager for statutory resolution within 48 hours.';
      refinedDescription = rawNotes.isNotEmpty
          ? 'Worker welfare grievance recorded ($rawNotes). Non-compliance under Mines Rules 1955.'
          : 'Labour welfare and workplace amenity deficiency logged for statutory rectifications.';
    }

    return GeminiObservationAnalysis(
      headline: headline,
      refinedDescription: refinedDescription.isNotEmpty
          ? refinedDescription
          : 'Field observation logged during routine statutory inspection round.',
      suggestedSeverity: severity,
      suggestedCategory: category,
      statutoryRegulationHint: regulationHint,
      recommendedImmediateAction: action,
      isAiGenerated: false,
    );
  }

  GeminiIncidentAnalysis _offlineIncidentFallback({
    required String incidentType,
    required String roughDescription,
  }) {
    final lower = '$incidentType $roughDescription'.toLowerCase();
    ViolationSeverity severity = ViolationSeverity.major;
    bool medical = false;
    bool notify = true;
    String headline = 'Statutory Incident Report';
    String action = 'Isolate dangerous area, switch off electrical power, and attend to affected personnel.';
    String refined = roughDescription;

    if (lower.contains('fatality') || lower.contains('fatal') || lower.contains('fire') ||
        lower.contains('explosion') || lower.contains('gas') || lower.contains('aag') ||
        lower.contains('dhamaka')) {
      headline = 'Critical Colliery Emergency';
      severity = ViolationSeverity.critical;
      medical = true;
      notify = true;
      action = 'Sound colliery evacuation siren, isolate electric supply, and notify DGMS Regional Inspector & Coalfield HQ immediately.';
      refined = roughDescription.isNotEmpty
          ? 'Critical Emergency: $roughDescription. Immediate emergency evacuation protocol invoked.'
          : 'Critical statutory emergency reported under Mines Act 1952 Sec 23.';
    } else if (lower.contains('injury') || lower.contains('fracture') || lower.contains('cut') ||
               lower.contains('burn') || lower.contains('chot') || lower.contains('ghayal')) {
      headline = 'Workplace Casualty Incident';
      medical = true;
      severity = ViolationSeverity.major;
      action = 'Administer first-aid at Pithead medical dispensary and dispatch emergency ambulance to Central Hospital.';
      refined = roughDescription.isNotEmpty
          ? 'Workplace casualty reported ($roughDescription). Statutory Form-IV logging initiated.'
          : 'Injury requiring first-aid and medical evaluation logged under Mines Rules 1955.';
    } else if (lower.contains('near miss') || lower.contains('equipment') || lower.contains('belt') ||
               lower.contains('conveyor') || lower.contains('machine')) {
      headline = 'Machinery Near-Miss Occurrence';
      severity = ViolationSeverity.minor;
      medical = false;
      action = 'Apply Lock-Out Tag-Out (LOTO) on machinery and conduct root-cause mechanical failure investigation.';
      refined = roughDescription.isNotEmpty
          ? 'Near-miss machinery malfunction recorded ($roughDescription).'
          : 'Equipment near-miss incident logged for mechanical safety review.';
    }

    return GeminiIncidentAnalysis(
      headline: headline,
      refinedDescription: refined.isNotEmpty
          ? refined
          : 'Emergency statutory incident logged under CMR 2017 Reg 116.',
      suggestedSeverity: severity,
      suggestedImmediateAction: action,
      medicalAttentionRecommended: medical,
      notifyAuthorityImmediately: notify,
      statutoryRegulation: 'CMR 2017 Reg 116 / Mines Act 1952 Sec 23',
      isAiGenerated: false,
    );
  }

  static ViolationSeverity _parseSeverity(String? value) {
    switch (value?.toLowerCase()) {
      case 'critical':
        return ViolationSeverity.critical;
      case 'major':
        return ViolationSeverity.major;
      case 'minor':
      default:
        return ViolationSeverity.minor;
    }
  }

  static ObservationCategory _parseCategory(String? value) {
    switch (value?.toLowerCase()) {
      case 'environmental':
        return ObservationCategory.environmental;
      case 'labour':
        return ObservationCategory.labour;
      case 'gasreading':
        return ObservationCategory.gasReading;
      case 'safety':
      case 'other':
      default:
        return ObservationCategory.safety;
    }
  }
}

