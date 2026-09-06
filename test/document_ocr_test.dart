import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/ai/document_ocr_service.dart';
import 'package:minesafe/models/document_model.dart';

void main() {
  group('DocumentOcrService Entity Extraction Tests', () {
    late DocumentOcrService ocrService;

    setUp(() {
      ocrService = DocumentOcrService();
    });

    tearDown(() {
      ocrService.dispose();
    });

    test('extracts Flameproof certificate number, contractor and dates', () {
      const sampleText = '''
DIRECTORATE GENERAL OF MINES SAFETY (DGMS)
CERTIFICATE OF FLAMEPROOF TESTING & STATUTORY FITNESS
Certificate No: DGMS/NZ/2026/FLP-88412
Issued to: Bharat Heavy Engineering Pvt Ltd
Equipment: Flameproof Induction Motor 75kW
Date of Issue: 15/03/2026
Valid Until: 14/03/2028
Remarks: Approved for Degree-III underground gassy coal seams.
''';

      final info = ocrService.extractEntitiesFromText(sampleText);

      expect(info.hasAnyExtractedField, isTrue);
      expect(info.certificateNumber, contains('DGMS/NZ/2026/FLP-88412'));
      expect(info.contractorName, equals('Bharat Heavy Engineering Pvt Ltd'));
      expect(info.suggestedCategory, equals(DocumentCategory.equipmentFitnessCertificate));
      expect(info.issueDate, equals(DateTime(2026, 3, 15)));
      expect(info.expiryDate, equals(DateTime(2028, 3, 14)));
      expect(info.confidenceScore, greaterThanOrEqualTo(0.9));
    });

    test('extracts Contractor Statutory DGMS License correctly', () {
      const sampleText = '''
GOVERNMENT OF INDIA - MINISTRY OF LABOUR
CONTRACTOR STATUTORY LICENCE
Licence Ref: LIC-2026-MINING-0912
Contractor Name: Eastern Coalfield Services Limited
Validity: Valid upto 31/12/2027
Issue Date: 01/01/2026
Conditions: Compliance with CMR 2017 Regulation 116.
''';

      final info = ocrService.extractEntitiesFromText(sampleText);

      expect(info.certificateNumber, contains('LIC-2026-MINING-0912'));
      expect(info.contractorName, equals('Eastern Coalfield Services Limited'));
      expect(info.suggestedCategory, equals(DocumentCategory.contractorLicense));
      expect(info.issueDate, equals(DateTime(2026, 1, 1)));
      expect(info.expiryDate, equals(DateTime(2027, 12, 31)));
    });

    test('gracefully handles empty or noisy text', () {
      final info = ocrService.extractEntitiesFromText('');
      expect(info.hasAnyExtractedField, isFalse);
      expect(info.certificateNumber, isNull);
      expect(info.expiryDate, isNull);
    });
  });
}
