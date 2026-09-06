import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/ai/gemini_copilot_service.dart';
import 'package:minesafe/models/inspection_model.dart';
import 'package:minesafe/models/observation_model.dart';

void main() {
  group('GeminiCopilotService Offline Heuristics & Rules Tests', () {
    late GeminiCopilotService service;

    setUp(() {
      service = GeminiCopilotService();
    });

    test('Analyze methane gas hazard offline returns Critical severity and CMR Reg 153', () async {
      final analysis = await service.analyzeObservation(
        rawNotes: 'High gas detected near coal face, ventilation stopped',
        ch4: 1.6,
        co: 45,
        o2: 18.2,
      );

      expect(analysis.suggestedSeverity, equals(ViolationSeverity.critical));
      expect(analysis.suggestedCategory, equals(ObservationCategory.gasReading));
      expect(analysis.statutoryRegulationHint, contains('CMR 2017 Reg 153'));
      expect(analysis.recommendedImmediateAction?.toLowerCase(), contains('ventilation'));
    });

    test('Analyze roof fall/strata hazard returns CMR Reg 123 & Timbering/Strata advisory', () async {
      final analysis = await service.analyzeObservation(
        rawNotes: 'Loose rock hanging from roof, strata crack visible near junction',
      );

      expect(analysis.suggestedSeverity, equals(ViolationSeverity.major));
      expect(analysis.suggestedCategory, equals(ObservationCategory.safety));
      expect(analysis.statutoryRegulationHint, contains('CMR 2017 Reg 123'));
      expect(analysis.recommendedImmediateAction?.toLowerCase(), contains('roof'));
    });

    test('Analyze environmental dust and sump drainage', () async {
      final analysis = await service.analyzeObservation(
        rawNotes: 'Heavy airborne coal dust and smoke, sump water overflow',
      );

      expect(analysis.suggestedCategory, equals(ObservationCategory.environmental));
      expect(analysis.statutoryRegulationHint, contains('CMR 2017 Reg 143'));
    });

    test('Analyze emergency incident offline returns critical severity and statutory action', () async {
      final incidentAnalysis = await service.analyzeIncident(
        incidentType: 'Explosion / Methane Fire',
        roughDescription: 'Spark from faulty flameproof box ignited methane pocket',
      );

      expect(incidentAnalysis.suggestedSeverity, equals(ViolationSeverity.critical));
      expect(incidentAnalysis.medicalAttentionRecommended, isTrue);
      expect(incidentAnalysis.notifyAuthorityImmediately, isTrue);
      expect(incidentAnalysis.suggestedImmediateAction.toLowerCase(), contains('evacuation'));
    });
  });
}
