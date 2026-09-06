import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../models/document_model.dart';

/// Structured information extracted from a statutory compliance document scan.
class ExtractedDocumentInfo {
  final String? certificateNumber;
  final String? contractorName;
  final String? documentTitle;
  final DocumentCategory? suggestedCategory;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String rawText;
  final double confidenceScore;

  const ExtractedDocumentInfo({
    this.certificateNumber,
    this.contractorName,
    this.documentTitle,
    this.suggestedCategory,
    this.issueDate,
    this.expiryDate,
    required this.rawText,
    this.confidenceScore = 1.0,
  });

  bool get hasAnyExtractedField =>
      certificateNumber != null ||
      contractorName != null ||
      documentTitle != null ||
      suggestedCategory != null ||
      expiryDate != null ||
      issueDate != null;
}

/// Offline, On-Device AI Service for Document OCR & Statutory Entity Extraction.
/// Zero billing, zero internet connection required, 100% private.
class DocumentOcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer =>
      _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  /// Scans an image or PDF file on device and extracts mining statutory certificate fields.
  Future<ExtractedDocumentInfo> scanDocument(String filePath) async {
    try {
      if (filePath.toLowerCase().endsWith('.pdf')) {
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final text = _extractTextFromPdfBytes(bytes);
          if (text.trim().isNotEmpty) {
            return extractEntitiesFromText(text);
          }
        }
      }

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final inputImage = InputImage.fromFilePath(filePath);
        final RecognizedText recognizedText =
            await _recognizer.processImage(inputImage);
        return extractEntitiesFromText(recognizedText.text);
      } else {
        // Fallback for desktop/unit testing environments where ML Kit binary isn't natively bound
        final file = File(filePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final text = _extractTextFromPdfBytes(bytes);
          if (text.trim().isNotEmpty) {
            return extractEntitiesFromText(text);
          }
        }
        return const ExtractedDocumentInfo(
          rawText: '',
          confidenceScore: 0.0,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DocumentOcrService] OCR Error: $e');
      }
      return const ExtractedDocumentInfo(
        rawText: '',
        confidenceScore: 0.0,
      );
    }
  }

  String _extractTextFromPdfBytes(List<int> bytes) {
    try {
      final raw = latin1.decode(bytes);
      final buffer = StringBuffer();

      final tjRegex = RegExp(r'\(([^)]+)\)\s*(?:Tj|' r"'" r'|")');
      for (final m in tjRegex.allMatches(raw)) {
        final str = m.group(1);
        if (str != null && str.trim().isNotEmpty) {
          buffer.writeln(str.replaceAll(r'\(', '(').replaceAll(r'\)', ')'));
        }
      }

      final tjArrayRegex = RegExp(r'\[(.*?)\]\s*TJ', dotAll: true);
      for (final m in tjArrayRegex.allMatches(raw)) {
        final arrayContent = m.group(1) ?? '';
        final innerRegex = RegExp(r'\(([^)]+)\)');
        final lineBuf = StringBuffer();
        for (final innerMatch in innerRegex.allMatches(arrayContent)) {
          lineBuf.write(innerMatch.group(1) ?? '');
        }
        if (lineBuf.isNotEmpty) {
          buffer.writeln(lineBuf.toString());
        }
      }

      if (buffer.isEmpty) {
        final asciiRegex = RegExp(r'[A-Za-z0-9\:\/\.\-\,\s]{4,}');
        for (final m in asciiRegex.allMatches(raw)) {
          final s = m.group(0)?.trim();
          if (s != null && s.length > 3 && !s.startsWith('obj') && !s.startsWith('endobj')) {
            buffer.writeln(s);
          }
        }
      }

      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  /// Parses raw OCR text using mining compliance heuristics and regex rules.
  ExtractedDocumentInfo extractEntitiesFromText(String text) {
    if (text.trim().isEmpty) {
      return const ExtractedDocumentInfo(rawText: '');
    }

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? certNumber;
    String? contractor;
    String? docTitle;
    DocumentCategory? category;
    DateTime? issueDate;
    DateTime? expiryDate;

    // ── 1. Extract Certificate / Registration Number ───────────────────────
    final dgmsPattern = RegExp(
      r'\b(DGMS[\w\/\-\.]{3,30})\b',
      caseSensitive: false,
    );
    final certLinePattern = RegExp(
      r'(?:certificate|registration|licence|license|flp|ref|number|no)\s*(?:no\.?|num\.?|ref\.?|#)?\s*[\:\-]?\s*([A-Z0-9][A-Z0-9\/\-\.]{3,30})',
      caseSensitive: false,
    );

    for (final line in lines) {
      final dgmsMatch = dgmsPattern.firstMatch(line);
      if (dgmsMatch != null) {
        certNumber = dgmsMatch.group(1);
        break;
      }
      final certMatch = certLinePattern.firstMatch(line);
      if (certMatch != null) {
        final candidate = certMatch.group(1)?.trim();
        if (candidate != null &&
            !candidate.toLowerCase().contains('licen') &&
            !candidate.toLowerCase().contains('statut') &&
            !candidate.toLowerCase().contains('cert') &&
            RegExp(r'\d').hasMatch(candidate)) {
          certNumber = candidate;
          break;
        }
      }
    }

    // ── 2. Extract Category & Title Heuristics ─────────────────────────────
    final lowerText = text.toLowerCase();
    if (lowerText.contains('flameproof') ||
        lowerText.contains('flp') ||
        lowerText.contains('machinery fitness') ||
        lowerText.contains('equipment fitness')) {
      category = DocumentCategory.equipmentFitnessCertificate;
      docTitle = 'Flameproof (FLP) Machinery Fitness Certificate';
    } else if ((lowerText.contains('contractor') || lowerText.contains('vendor')) &&
        (lowerText.contains('license') ||
            lowerText.contains('licence') ||
            lowerText.contains('labour') ||
            lowerText.contains('statutory'))) {
      category = DocumentCategory.contractorLicense;
      docTitle = 'Contractor Statutory DGMS License';
    } else if (lowerText.contains('environmental') ||
        lowerText.contains('pollution control') ||
        lowerText.contains('spcb') ||
        lowerText.contains('moef')) {
      category = DocumentCategory.environmentalClearance;
      docTitle = 'State Environmental Clearance & Consent';
    } else if (lowerText.contains('safety management plan') ||
        lowerText.contains('smp') ||
        lowerText.contains('emergency plan')) {
      category = DocumentCategory.mineSafetyPlan;
      docTitle = 'Mine Safety Management Plan (SMP)';
    } else if (lowerText.contains('competency') ||
        lowerText.contains('statutory') ||
        lowerText.contains('dgms') ||
        lowerText.contains('first class') ||
        lowerText.contains('overman') ||
        lowerText.contains('sirdar')) {
      category = DocumentCategory.statutoryCertificate;
      docTitle = 'Statutory Competency Certificate';
    }

    // ── 3. Extract Contractor / Company Name ───────────────────────────────
    for (final line in lines) {
      final prefixMatch = RegExp(
        r'(?:issued\s+to|contractor\s+name|contractor|vendor|company|holder)\s*[\:\-]\s*([A-Za-z0-9\s\,\.\-]+)',
        caseSensitive: false,
      ).firstMatch(line);
      if (prefixMatch != null) {
        final candidate = prefixMatch.group(1)?.trim();
        if (candidate != null && candidate.length > 2) {
          contractor = candidate;
          break;
        }
      }
    }

    if (contractor == null) {
      final companyRegex = RegExp(
        r'([A-Za-z\s\,\.\-]{4,50}(?:Pvt\.?\s*Ltd\.?|Private\s+Limited|Limited|Ltd\.?|Enterprises|Engineering|Corporation))',
        caseSensitive: false,
      );
      for (final line in lines) {
        final match = companyRegex.firstMatch(line);
        if (match != null) {
          contractor = match.group(1)?.trim();
          break;
        }
      }
    }

    // ── 4. Extract Issue and Expiry Dates ──────────────────────────────────
    final allDates = _extractDatesFromText(text);

    // Look for lines with specific issue keywords
    final issueRegex = RegExp(
      r'(?:issue\s*date|date\s*of\s*issue|issued\s*on|dated|date)[\s\:\-]+([0-9]{1,2}[\/\-\.][0-9]{1,2}[\/\-\.][0-9]{2,4}|[0-9]{4}[\/\-\.][0-9]{1,2}[\/\-\.][0-9]{1,2})',
      caseSensitive: false,
    );

    // Look for lines with specific expiry/validity keywords
    final expiryRegex = RegExp(
      r'(?:valid\s*upto|valid\s*until|valid\s*till|valid\s*thru|expiry\s*date|expires\s*on|expiry|expires|validity)[\s\:\-]+([0-9]{1,2}[\/\-\.][0-9]{1,2}[\/\-\.][0-9]{2,4}|[0-9]{4}[\/\-\.][0-9]{1,2}[\/\-\.][0-9]{1,2})',
      caseSensitive: false,
    );

    for (final line in lines) {
      final expMatch = expiryRegex.firstMatch(line);
      if (expMatch != null) {
        final parsed = _tryParseDateString(expMatch.group(1)!);
        if (parsed != null) {
          expiryDate = parsed;
        }
      }

      final issMatch = issueRegex.firstMatch(line);
      if (issMatch != null) {
        final parsed = _tryParseDateString(issMatch.group(1)!);
        if (parsed != null) {
          issueDate = parsed;
        }
      }
    }

    // Fallback: Check lines containing keywords if strict regex didn't capture
    if (expiryDate == null) {
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('expiry') ||
            lowerLine.contains('expires') ||
            lowerLine.contains('valid until') ||
            lowerLine.contains('valid upto') ||
            lowerLine.contains('valid till') ||
            lowerLine.contains('valid thru')) {
          final datesInLine = _extractDatesFromText(line);
          if (datesInLine.isNotEmpty) {
            expiryDate = datesInLine.last;
            break;
          }
        }
      }
    }

    if (issueDate == null) {
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('issue') ||
            lowerLine.contains('dated') ||
            lowerLine.contains('date of issue')) {
          final datesInLine = _extractDatesFromText(line);
          if (datesInLine.isNotEmpty) {
            issueDate = datesInLine.first;
            break;
          }
        }
      }
    }

    // Chronological resolution & deduplication
    if (allDates.isNotEmpty) {
      final uniqueDates = allDates.toSet().toList()..sort();
      if (issueDate == null && expiryDate == null) {
        if (uniqueDates.length >= 2) {
          issueDate = uniqueDates.first;
          expiryDate = uniqueDates.last;
        } else if (uniqueDates.length == 1) {
          issueDate = uniqueDates.first;
        }
      } else if (issueDate != null && expiryDate != null) {
        // If both were set to identical date but distinct dates exist in document
        if (issueDate == expiryDate && uniqueDates.length >= 2) {
          issueDate = uniqueDates.first;
          expiryDate = uniqueDates.last;
        } else if (expiryDate.isBefore(issueDate)) {
          // Swap if expiry is chronologically before issue
          final temp = issueDate;
          issueDate = expiryDate;
          expiryDate = temp;
        }
      } else if (issueDate != null && expiryDate == null) {
        final laterDates = uniqueDates.where((d) => d.isAfter(issueDate!)).toList();
        if (laterDates.isNotEmpty) {
          expiryDate = laterDates.last;
        }
      } else if (issueDate == null && expiryDate != null) {
        final earlierDates = uniqueDates.where((d) => d.isBefore(expiryDate!)).toList();
        if (earlierDates.isNotEmpty) {
          issueDate = earlierDates.first;
        }
      }
    }

    return ExtractedDocumentInfo(
      certificateNumber: certNumber,
      contractorName: contractor,
      documentTitle: docTitle,
      suggestedCategory: category,
      issueDate: issueDate,
      expiryDate: expiryDate,
      rawText: text,
      confidenceScore: (certNumber != null ? 0.4 : 0.0) +
          (contractor != null ? 0.3 : 0.0) +
          (expiryDate != null ? 0.3 : 0.0),
    );
  }

  List<DateTime> _extractDatesFromText(String text) {
    final results = <DateTime>[];
    // dd/mm/yyyy or dd-mm-yyyy or yyyy-mm-dd
    final dateRegex = RegExp(
      r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b|\b(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})\b',
    );

    for (final match in dateRegex.allMatches(text)) {
      final str = match.group(0);
      if (str != null) {
        final dt = _tryParseDateString(str);
        if (dt != null) results.add(dt);
      }
    }
    return results;
  }

  DateTime? _tryParseDateString(String input) {
    try {
      final cleaned = input.replaceAll('.', '/').replaceAll('-', '/');
      final parts = cleaned.split('/');
      if (parts.length != 3) return null;

      int day, month, year;
      if (parts[0].length == 4) {
        // yyyy/mm/dd
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else {
        // dd/mm/yyyy
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
        if (year < 100) year += 2000;
      }

      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
