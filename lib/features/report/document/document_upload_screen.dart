import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/document_model.dart';
import '../../../models/evidence_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/signature_pad.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  DocumentCategory _category = DocumentCategory.statutoryCertificate;
  final _titleController = TextEditingController(text: 'Flameproof Electrical Compliance Cert');
  final _docNumberController = TextEditingController(text: 'DGMS/ER/2026/FLP-881');
  final _contractorController = TextEditingController(text: 'Eastern Mining Services');
  final _remarksController = TextEditingController();
  DateTime _issueDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 335));
  final List<EvidenceItem> _files = [];
  String? _signatureBase64;
  bool _isSubmitting = false;
  bool _isOcrScanning = false;
  String? _aiExtractionStatus;

  @override
  void initState() {
    super.initState();
    _recoverLostEvidence();
  }

  Future<void> _recoverLostEvidence() async {
    final evidenceService = ref.read(evidenceServiceProvider);
    final lost = await evidenceService.retrieveLostPhoto(reportClientUuid: 'temp_doc');
    if (lost != null && mounted) {
      setState(() => _files.add(lost));
      await _processImageWithOcr(lost.localPath);
    }
  }

  Future<void> _processImageWithOcr(String localPath) async {
    setState(() {
      _isOcrScanning = true;
      _aiExtractionStatus = 'Scanning certificate with on-device AI (Offline)...';
    });

    try {
      final ocrService = ref.read(documentOcrServiceProvider);
      final info = await ocrService.scanDocument(localPath);

      if (info.hasAnyExtractedField && mounted) {
        setState(() {
          if (info.certificateNumber != null && info.certificateNumber!.isNotEmpty) {
            _docNumberController.text = info.certificateNumber!;
          }
          if (info.contractorName != null && info.contractorName!.isNotEmpty) {
            _contractorController.text = info.contractorName!;
          }
          if (info.documentTitle != null && info.documentTitle!.isNotEmpty) {
            _titleController.text = info.documentTitle!;
          }
          if (info.suggestedCategory != null) {
            _category = info.suggestedCategory!;
          }
          if (info.issueDate != null) {
            _issueDate = info.issueDate!;
          }
          if (info.expiryDate != null) {
            _expiryDate = info.expiryDate!;
          }
          _aiExtractionStatus = '✨ AI Auto-Filled: Certificate # & Expiry Date extracted from document!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primaryAmber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'On-Device AI: Certificate details & dates extracted!',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.cardLayer2,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _aiExtractionStatus = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isOcrScanning = false);
    }
  }

  Future<void> _pickFile() async {
    final evidenceService = ref.read(evidenceServiceProvider);
    final item = await evidenceService.pickDocumentFile(
      reportClientUuid: 'temp_doc',
      caption: _titleController.text.trim(),
    );
    if (item != null && mounted) {
      setState(() => _files.add(item));
      await _processImageWithOcr(item.localPath);
    }
  }

  Future<void> _scanCamera() async {
    final evidenceService = ref.read(evidenceServiceProvider);
    final locationService = ref.read(locationServiceProvider);
    final loc = await locationService.captureLocation();

    final item = await evidenceService.capturePhoto(
      reportClientUuid: 'temp_doc',
      location: loc,
      caption: 'Document Scan: ${_titleController.text.trim()}',
    );
    if (item != null && mounted) {
      setState(() => _files.add(item));
      await _processImageWithOcr(item.localPath);
    }
  }

  Future<void> _selectIssueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _issueDate = picked);
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) {
      setState(() => _expiryDate = picked);
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Future<void> _submitDocument() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.document),
          backgroundColor: AppColors.hazardRed,
        ),
      );
      return;
    }

    if (_signatureBase64 == null || _signatureBase64!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add your digital signature before submitting.\nसबमिट करने से पहले डिजिटल हस्ताक्षर अनिवार्य है।',
          ),
          backgroundColor: AppColors.hazardRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(documentRepositoryProvider);
      final report = await repo.createDraft(
        user: user,
        category: _category,
        title: _titleController.text.trim(),
        documentNumber: _docNumberController.text.trim(),
        associatedContractor: _contractorController.text.trim(),
        issueDate: _issueDate,
        expiryDate: _expiryDate,
        remarks: _remarksController.text.trim(),
        files: _files,
      );

      await repo.submitAndLockDocument(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.reportSaved),
            backgroundColor: AppColors.complianceGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(context.l10n.document, style: AppTypography.headlineSm),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.complianceGreenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.complianceGreen.withAlpha(100)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.complianceGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUTORY CERTIFICATE VAULT',
                          style: AppTypography.labelSm.copyWith(color: AppColors.complianceGreen),
                        ),
                        Text(
                          'Upload DGMS approvals, FLP electrical certs, and statutory calibration logs with cryptographic timestamping.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.textMediumEmphasis, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // AI OCR Status Banner
            if (_isOcrScanning)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAmber.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryAmber.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAmber),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _aiExtractionStatus ?? 'Scanning document with on-device AI...',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primaryAmber,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_aiExtractionStatus != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.complianceGreenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.complianceGreen.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.complianceGreen, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _aiExtractionStatus!,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.complianceGreen,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isOcrScanning || _aiExtractionStatus != null)
              const SizedBox(height: 16)
            else
              const SizedBox(height: 6),

            Text('DOCUMENT TYPE / प्रकार', style: AppTypography.labelSm),
            const SizedBox(height: 8),
            DropdownButtonFormField<DocumentCategory>(
              initialValue: _category,
              isExpanded: true,
              items: DocumentCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.displayName, style: AppTypography.bodyMd, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),

            Text('DOCUMENT TITLE / नाम', style: AppTypography.labelSm),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. DGMS Clearance Certificate'),
            ),
            const SizedBox(height: 16),

            Text('REGISTRATION / CERTIFICATE NUMBER', style: AppTypography.labelSm),
            const SizedBox(height: 6),
            TextField(
              controller: _docNumberController,
              decoration: const InputDecoration(hintText: 'e.g. DGMS/2026/CERT-401'),
            ),
            const SizedBox(height: 16),

            Text('ASSOCIATED CONTRACTOR / VENDOR', style: AppTypography.labelSm),
            const SizedBox(height: 6),
            TextField(
              controller: _contractorController,
              decoration: const InputDecoration(hintText: 'e.g. Eastern Mining Services Pvt Ltd'),
            ),
            const SizedBox(height: 16),

            // Date Selection Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ISSUE DATE / जारी तिथि', style: AppTypography.labelSm),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _selectIssueDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardLayer1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.strokeLowLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(_issueDate), style: AppTypography.bodyMd),
                              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primaryAmber),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXPIRY DATE / समाप्ति तिथि', style: AppTypography.labelSm),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _selectExpiryDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardLayer1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.strokeLowLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(_expiryDate), style: AppTypography.bodyMd),
                              const Icon(Icons.event_busy_outlined, size: 16, color: AppColors.hazardRed),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text('NOTES / REMARKS / विवरण', style: AppTypography.labelSm),
            const SizedBox(height: 6),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Enter statutory remarks or validity conditions...'),
            ),
            const SizedBox(height: 16),

            Text('ATTACHED FILES (PDF / SCAN / PHOTO)', style: AppTypography.labelSm),
            const SizedBox(height: 8),
            if (_files.isNotEmpty)
              ..._files.map(
                (f) {
                  final isPdf = f.localPath.toLowerCase().endsWith('.pdf') ||
                      f.mimeType.contains('pdf');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cardLayer2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.strokeLowLight),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.insert_drive_file_outlined,
                          color: isPdf
                              ? AppColors.complianceGreen
                              : AppColors.primaryAmber,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.caption ?? 'Document file',
                                style: AppTypography.labelSm.copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isPdf ? 'PDF Document' : 'Document File / Scan',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.textDisabled,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'AI Extract Details',
                          icon: const Icon(
                            Icons.auto_awesome,
                            color: AppColors.primaryAmber,
                            size: 18,
                          ),
                          onPressed: () => _processImageWithOcr(f.localPath),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline, color: AppColors.hazardRed, size: 20),
                          onPressed: () => setState(() => _files.remove(f)),
                        ),
                      ],
                    ),
                  );
                },
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scanCamera,
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.complianceGreen),
                    label: const Text('SCAN (CAMERA)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.textHighEmphasis),
                    label: const Text('UPLOAD FILE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Statutory Digital Signature Pad
            Text('DIGITAL SIGNATURE / डिजिटल हस्ताक्षर', style: AppTypography.labelSm),
            const SizedBox(height: 4),
            Text(
              'Sign to authenticate this statutory document record.',
              style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 11),
            ),
            const SizedBox(height: 8),
            SignaturePadWidget(
              signerName: ref.watch(authStateProvider)?.fullName ?? 'Mining Official',
              signerRole: ref.watch(authStateProvider)?.designation ?? 'Safety Inspector',
              initialSignature: _signatureBase64,
              onSignatureSaved: (signatureBase64) {
                setState(() => _signatureBase64 = signatureBase64);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(top: BorderSide(color: AppColors.strokeLowLight, width: 1.5)),
          ),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDocument,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.complianceGreen,
              minimumSize: const Size.fromHeight(50),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: AppColors.onPrimary)
                : Text(
                    'SUBMIT STATUTORY COMPLIANCE DOCUMENT',
                    style: AppTypography.labelLg.copyWith(color: AppColors.onPrimary, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ),
      ),
    );
  }
}
