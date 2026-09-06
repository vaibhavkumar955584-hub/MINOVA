import 'package:flutter_test/flutter_test.dart';
import 'package:minesafe/core/ai/document_ocr_service.dart';
import 'package:minesafe/models/document_model.dart';
import 'package:minesafe/models/evidence_model.dart';

void main() {
  group('Statutory Document Vault & OCR Suite', () {
    test('MINOVA OCR Test Document Extraction Verification', () {
      const rawPdfText = '''
MINOVA
Mining Safety & Compliance - OCR TEST DOCUMENT
FLAMEPROOF EQUIPMENT FITNESS CERTIFICATE

Certificate No.: DGMS/2026/FLP-881
Registration No.: LIC-FLP-2026-11842
Document Category: Flameproof Equipment Fitness Certificate
Issued To: Eastern Mining Services Pvt Ltd
Contractor Name: Eastern Mining Services Pvt Ltd
Equipment: Flameproof Portable Gas Detector
Mine: JH-DHA-BCCL-007
Issue Date: 15/08/2026
Valid Upto: 14/08/2027
Issuing Authority: Directorate General of Mines Safety (DGMS)
Compliance Statement
This certificate confirms that the flameproof equipment listed above has been examined and is suitable
for use in the designated mining environment, subject to applicable DGMS requirements and statutory safety conditions.
''';

      final ocrService = DocumentOcrService();
      final result = ocrService.extractEntitiesFromText(rawPdfText);

      expect(result.certificateNumber, contains('DGMS/2026/FLP-881'));
      expect(result.contractorName, equals('Eastern Mining Services Pvt Ltd'));
      expect(
        result.suggestedCategory,
        equals(DocumentCategory.equipmentFitnessCertificate),
      );
      expect(result.issueDate, equals(DateTime(2026, 8, 15)));
      expect(result.expiryDate, equals(DateTime(2027, 8, 14)));
      expect(result.hasAnyExtractedField, isTrue);
    });

    test('Same-line date disambiguation test', () {
      const sameLineText = '''
DGMS ELECTRICAL FITNESS PERMIT
Certificate No: DGMS/EL/8821
Contractor: Bharat Coking Coal Limited
Issue: 15/08/2026 | Valid Upto: 14/08/2027
''';
      final ocrService = DocumentOcrService();
      final result = ocrService.extractEntitiesFromText(sameLineText);

      expect(result.certificateNumber, equals('DGMS/EL/8821'));
      expect(result.issueDate, equals(DateTime(2026, 8, 15)));
      expect(result.expiryDate, equals(DateTime(2027, 8, 14)));
      expect(result.issueDate, isNot(equals(result.expiryDate)));
    });

    test('ComplianceDocument model and DB serialization with issueDate', () {
      final doc = ComplianceDocument(
        clientUuid: 'DOC-CMP-TEST01',
        mineId: 'M-001',
        mineName: 'Test Mine Pit-1',
        userId: 'U-001',
        userName: 'Inspector John',
        category: DocumentCategory.equipmentFitnessCertificate,
        title: 'Flameproof Certificate',
        documentNumber: 'DGMS/2026/FLP-881',
        associatedContractor: 'Eastern Mining Services',
        issueDate: DateTime(2026, 8, 15),
        expiryDate: DateTime(2027, 8, 14),
        remarks: 'Statutory verification completed',
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
        files: [
          EvidenceItem(
            id: 'EV-DOC-1',
            reportClientUuid: 'DOC-CMP-TEST01',
            localFilePath: '/path/to/cert.pdf',
            fileType: 'document',
            fileSize: 1024,
            sha256Hash: 'dummyhash',
            capturedAt: DateTime(2026, 9, 1),
          ),
        ],
      );

      final map = doc.toDbMap();
      expect(map['issue_date'], contains('2026-08-15'));
      expect(map['expiry_date'], contains('2027-08-14'));
      expect(map['title'], equals('Flameproof Certificate'));

      final reconstructed = ComplianceDocument.fromDbMap(map);
      expect(reconstructed.issueDate, equals(DateTime(2026, 8, 15)));
      expect(reconstructed.expiryDate, equals(DateTime(2027, 8, 14)));
      expect(reconstructed.files.length, equals(1));
    });
  });
}
