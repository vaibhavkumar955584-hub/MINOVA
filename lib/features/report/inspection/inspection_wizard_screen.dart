import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/inspection_model.dart';
import '../../../models/mine_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/ai_copilot_sheet.dart';
import '../../../shared/widgets/large_touch_card.dart';
import '../../../shared/widgets/signature_pad.dart';

enum WizardStep { questions, locationAndEvidence, reviewAndSign }

class InspectionWizardScreen extends ConsumerStatefulWidget {
  final InspectionType type;

  const InspectionWizardScreen({super.key, this.type = InspectionType.safety});

  @override
  ConsumerState<InspectionWizardScreen> createState() =>
      _InspectionWizardScreenState();
}

class _InspectionWizardScreenState
    extends ConsumerState<InspectionWizardScreen> {
  InspectionReport? _report;
  bool _isLoading = true;
  bool _isAiAssisting = false;
  int _currentQuestionIndex = 0;
  WizardStep _currentStep = WizardStep.questions;

  // Controllers for current question violation
  final _violationController = TextEditingController();
  final _actionController = TextEditingController();
  final _deadlineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDraft();
  }

  Future<void> _initDraft() async {
    final user = ref.read(authStateProvider);
    if (user == null) return;

    final repo = ref.read(inspectionRepositoryProvider);
    final draft = await repo.createDraft(user: user, type: widget.type);

    if (mounted) {
      setState(() {
        _report = draft;
        _isLoading = false;
      });
      _syncControllersWithCurrentQuestion();
      _recoverLostEvidence();
    }
  }

  Future<void> _recoverLostEvidence() async {
    if (_report == null) return;
    final evidenceService = ref.read(evidenceServiceProvider);
    final lost = await evidenceService.retrieveLostPhoto(
      reportClientUuid: _report!.clientUuid,
    );
    if (lost != null && mounted) {
      setState(() {
        _report!.checklist[_currentQuestionIndex].evidence.add(lost);
      });
      _autoSave();
    }
  }

  void _syncControllersWithCurrentQuestion() {
    if (_report == null || _report!.checklist.isEmpty) return;
    final item = _report!.checklist[_currentQuestionIndex];
    _violationController.text = item.violationDescription ?? '';
    _actionController.text = item.correctiveAction ?? '';
    _deadlineController.text = item.deadline == null
        ? ''
        : '${item.deadline!.day.toString().padLeft(2, '0')}/${item.deadline!.month.toString().padLeft(2, '0')}/${item.deadline!.year}';
  }

  Future<void> _autoSave() async {
    if (_report == null) return;
    final repo = ref.read(inspectionRepositoryProvider);
    await repo.autoSaveDraft(_report!);
  }

  void _setQuestionStatus(CheckItemStatus status) {
    if (_report == null) return;
    setState(() {
      final item = _report!.checklist[_currentQuestionIndex];
      item.status = status;
      if (status == CheckItemStatus.fail && item.severity == null) {
        item.severity = ViolationSeverity.major;
      }
    });
    _autoSave();
  }

  void _setViolationSeverity(ViolationSeverity severity) {
    if (_report == null) return;
    setState(() {
      _report!.checklist[_currentQuestionIndex].severity = severity;
    });
    _autoSave();
  }

  Future<void> _selectDeadline() async {
    if (_report == null) return;
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate:
          _report!.checklist[_currentQuestionIndex].deadline ?? DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _report!.checklist[_currentQuestionIndex].deadline = selected;
      _deadlineController.text =
          '${selected.day.toString().padLeft(2, '0')}/${selected.month.toString().padLeft(2, '0')}/${selected.year}';
    });
    _autoSave();
  }

  Future<void> _runAiAssistForQuestion(InspectionChecklistItem item) async {
    final queryText = _violationController.text.trim().isNotEmpty
        ? 'Checklist Item: ${item.question}. Section: ${item.section}. Guidance: ${item.guidance}. Finding: ${_violationController.text.trim()}'
        : 'Checklist Item: ${item.question}. Section: ${item.section}. Guidance: ${item.guidance}. Non-compliance observed.';

    setState(() => _isAiAssisting = true);
    try {
      final copilot = ref.read(geminiCopilotServiceProvider);
      final analysis = await copilot.analyzeObservation(rawNotes: queryText);

      if (mounted) {
        AiCopilotReviewSheet.show(
          context,
          headline: analysis.headline,
          originalText: _violationController.text.trim().isNotEmpty ? _violationController.text.trim() : item.question,
          refinedText: analysis.refinedDescription,
          severity: analysis.suggestedSeverity,
          category: analysis.suggestedCategory,
          regulationHint: analysis.statutoryRegulationHint ?? item.section,
          recommendedAction: analysis.recommendedImmediateAction,
          onApplyAll: () {
            setState(() {
              _violationController.text = analysis.refinedDescription;
              item.violationDescription = analysis.refinedDescription;
              if (analysis.recommendedImmediateAction != null) {
                _actionController.text = analysis.recommendedImmediateAction!;
                item.correctiveAction = analysis.recommendedImmediateAction;
              }
              item.severity = analysis.suggestedSeverity;
            });
            _autoSave();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.complianceGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI statutory formulation applied to violation!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.cardLayer2,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isAiAssisting = false);
    }
  }

  Future<ImageSource?> _showPhotoSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardLayer2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Evidence Source / साक्ष्य का स्रोत चुनें',
                style: AppTypography.headlineSm.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryAmber),
                title: const Text('Capture Live Photo (Camera)'),
                subtitle: const Text('फ़ोटो खींचे'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryAmber),
                title: const Text('Pick from Device Gallery'),
                subtitle: const Text('गैलरी / मेमोरी से चुनें (Safe & Fast)'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureItemEvidence() async {
    if (_report == null) return;
    final source = await _showPhotoSourceDialog();
    if (source == null) return;

    final evidenceService = ref.read(evidenceServiceProvider);
    final locationService = ref.read(locationServiceProvider);
    final loc = await locationService.captureLocation();

    final item = await evidenceService.capturePhoto(
      reportClientUuid: _report!.clientUuid,
      location: loc,
      source: source,
      caption: 'Question ${_currentQuestionIndex + 1} Evidence',
      userId: _report!.userId,
    );

    if (item != null && mounted) {
      setState(() {
        _report!.checklist[_currentQuestionIndex].evidence.add(item);
      });
      _autoSave();
    }
  }

  Future<void> _captureItemVideo() async {
    if (_report == null) return;
    final evidenceService = ref.read(evidenceServiceProvider);
    final loc = await ref.read(locationServiceProvider).captureLocation();
    final item = await evidenceService.captureVideo(
      reportClientUuid: _report!.clientUuid,
      location: loc,
      caption: 'Question ${_currentQuestionIndex + 1} Video Evidence',
    );
    if (item != null && mounted) {
      setState(
        () => _report!.checklist[_currentQuestionIndex].evidence.add(item),
      );
      _autoSave();
    }
  }

  void _nextQuestion() {
    if (_report == null) return;
    final currentItem = _report!.checklist[_currentQuestionIndex];
    if (currentItem.status == CheckItemStatus.fail) {
      currentItem.violationDescription = _violationController.text;
      currentItem.correctiveAction = _actionController.text;
    }

    _autoSave();

    if (_currentQuestionIndex < _report!.checklist.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _syncControllersWithCurrentQuestion();
    } else {
      setState(() {
        _currentStep = WizardStep.locationAndEvidence;
      });
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _syncControllersWithCurrentQuestion();
    }
  }

  Future<void> _submitFinalInspection() async {
    if (_report == null) return;
    if (_report!.signatureBase64 == null ||
        _report!.signatureBase64!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digital statutory signature is required before submission.\nसबमिट करने से पहले डिजिटल हस्ताक्षर आवश्यक है।',
          ),
          backgroundColor: AppColors.hazardRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final repo = ref.read(inspectionRepositoryProvider);
    try {
      await repo.submitAndLockReport(_report!);
    } on FormatException catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.hazardRed,
          ),
        );
      }
      return;
    } on StateError catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.lockedSubmitted),
          backgroundColor: AppColors.complianceGreen,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _report == null) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAmber),
        ),
      );
    }

    switch (_currentStep) {
      case WizardStep.questions:
        return _buildQuestionStep();
      case WizardStep.locationAndEvidence:
        return _buildLocationAndEvidenceStep();
      case WizardStep.reviewAndSign:
        return _buildReviewAndSignStep();
    }
  }

  // -------------------------------------------------------------
  // STEP 1: CHECKLIST QUESTION WIZARD (Matches Screenshot 2)
  // -------------------------------------------------------------
  Widget _buildQuestionStep() {
    final item = _report!.checklist[_currentQuestionIndex];
    final totalQuestions = _report!.checklist.length;
    final progress = (_currentQuestionIndex + 1) / totalQuestions;
    final progressPercent = (progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.report, style: AppTypography.headlineSm),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryAmberDark,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Safety Inspection + Saved on phone badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.primaryAmber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'SAFETY INSPECTION',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.textMediumEmphasis,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.complianceGreenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.complianceGreen),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_done_outlined,
                          color: AppColors.complianceGreen,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Saved on phone',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.complianceGreen,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Progress Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of $totalQuestions',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.textHighEmphasis,
                    ),
                  ),
                  Text(
                    '$progressPercent% Done',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primaryAmber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Progress Linear Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.cardLayer2,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primaryAmberDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable Question & Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Protocol Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardLayer2,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.strokeActive),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: AppColors.telemetryBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.section,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.telemetryBlue,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Question Text
                    Text(
                      item.question,
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.hindiQuestion,
                      style: AppTypography.bilingualCue.copyWith(
                        color: AppColors.primaryAmber,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Guidance Hint
                    Text(
                      item.guidance,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.textMediumEmphasis,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. YES - ALL COMPLIANT
                    _buildOptionButton(
                      title: context.l10n.yes,
                      subtitle: 'हाँ — सभी मानक पूर्ण हैं',
                      icon: Icons.check,
                      isSelected: item.status == CheckItemStatus.pass,
                      activeColor: AppColors.primaryAmberDark,
                      onTap: () => _setQuestionStatus(CheckItemStatus.pass),
                    ),
                    const SizedBox(height: 12),

                    // 2. NO - SAFETY ISSUE FOUND
                    _buildOptionButton(
                      title: context.l10n.no,
                      subtitle: 'नहीं — सुरक्षा उल्लंघन मिला है',
                      icon: Icons.warning_amber_rounded,
                      isSelected: item.status == CheckItemStatus.fail,
                      activeColor: AppColors.primaryAmberDark,
                      onTap: () => _setQuestionStatus(CheckItemStatus.fail),
                    ),
                    const SizedBox(height: 12),

                    // 3. NOT APPLICABLE
                    _buildOptionButton(
                      title: context.l10n.notApplicable,
                      subtitle: 'लागू नहीं होता',
                      icon: Icons.remove,
                      isSelected: item.status == CheckItemStatus.na,
                      activeColor: AppColors.primaryAmberDark,
                      onTap: () => _setQuestionStatus(CheckItemStatus.na),
                    ),
                    const SizedBox(height: 20),

                    // CONDITIONAL VIOLATION CARD (When FAIL is selected)
                    if (item.status == CheckItemStatus.fail) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0x20EF4444),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.hazardRed.withAlpha(120),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.hazardRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Safety issue found — How serious is it?',
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.textHighEmphasis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Severity Selectors
                            Row(
                              children: [
                                _buildSeverityChip(
                                  label: 'MINOR',
                                  sub: 'Notice',
                                  severity: ViolationSeverity.minor,
                                  current: item.severity,
                                  color: AppColors.primaryAmber,
                                ),
                                const SizedBox(width: 8),
                                _buildSeverityChip(
                                  label: 'MAJOR',
                                  sub: 'Stop Work',
                                  severity: ViolationSeverity.major,
                                  current: item.severity,
                                  color: AppColors.secondaryOrange,
                                ),
                                const SizedBox(width: 8),
                                _buildSeverityChip(
                                  label: '! CRITICAL',
                                  sub: 'Evacuate/Hold',
                                  severity: ViolationSeverity.critical,
                                  current: item.severity,
                                  color: AppColors.hazardRed,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Violation Description Field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'What is wrong?',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.textHighEmphasis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '* Required',
                                      style: AppTypography.labelSm.copyWith(
                                        color: AppColors.hazardRed,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: _isAiAssisting ? null : () => _runAiAssistForQuestion(item),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.telemetryBlue.withAlpha(25),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.telemetryBlue.withAlpha(100)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isAiAssisting)
                                          const SizedBox(
                                            width: 10,
                                            height: 10,
                                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.telemetryBlue),
                                          )
                                        else
                                          const Icon(Icons.auto_awesome, size: 12, color: AppColors.telemetryBlue),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isAiAssisting ? 'AI...' : 'AI STATUTORY DRAFT',
                                          style: const TextStyle(
                                            color: AppColors.telemetryBlue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _violationController,
                              maxLines: 3,
                              style: AppTypography.bodyMd,
                              decoration: const InputDecoration(
                                hintText:
                                    'Describe the statutory violation, or tap "AI STATUTORY DRAFT" to auto-formulate...',
                              ),
                              onChanged: (value) {
                                item.violationDescription = value;
                                _autoSave();
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _actionController,
                              maxLines: 2,
                              style: AppTypography.bodyMd,
                              decoration: const InputDecoration(
                                labelText: 'Corrective action',
                                hintText:
                                    'What must be done to close this issue?',
                              ),
                              onChanged: (value) {
                                item.correctiveAction = value;
                                _autoSave();
                              },
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _deadlineController,
                              readOnly: true,
                              onTap: _selectDeadline,
                              decoration: const InputDecoration(
                                labelText: 'Correction deadline',
                                hintText: 'Select a date',
                                suffixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Evidence Attachment Card
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Visual Documentation',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.textHighEmphasis,
                                  ),
                                ),
                                Text(
                                  '${item.evidence.length} Photo attached',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            if (item.evidence.isNotEmpty)
                              ...item.evidence.map(
                                (ev) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardLayer1,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.strokeLowLight,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.cardLayer2,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.image,
                                          color: AppColors.primaryAmber,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ev.caption ??
                                                  'photo_evidence.jpg',
                                              style: AppTypography.labelSm
                                                  .copyWith(fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              ev.uploadStatus == 'uploaded'
                                                  ? 'Uploaded'
                                                  : ev.uploadStatus ==
                                                        'uploading'
                                                  ? 'Uploading'
                                                  : ev.uploadStatus == 'failed'
                                                  ? 'Upload failed'
                                                  : 'Waiting to upload',
                                              style: AppTypography.bodySm
                                                  .copyWith(
                                                    color:
                                                        AppColors.textDisabled,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.hazardRed,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            item.evidence.remove(ev);
                                          });
                                          _autoSave();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            OutlinedButton.icon(
                              onPressed: _captureItemEvidence,
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.textHighEmphasis,
                              ),
                              label: Text(
                                item.evidence.isEmpty
                                    ? 'TAKE PHOTO EVIDENCE'
                                    : 'TAKE ANOTHER PHOTO',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.textHighEmphasis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _captureItemVideo,
                              icon: const Icon(
                                Icons.videocam_outlined,
                                color: AppColors.textHighEmphasis,
                              ),
                              label: Text(
                                'RECORD VIDEO',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.textHighEmphasis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              top: BorderSide(color: AppColors.strokeLowLight, width: 1.5),
            ),
          ),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0) ...[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _prevQuestion,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.cardLayer2,
                      side: const BorderSide(color: AppColors.strokeActive),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, size: 16),
                        const SizedBox(width: 4),
                        Text('PREV', style: AppTypography.labelMd),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAmberDark,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _currentQuestionIndex == totalQuestions - 1
                              ? 'ADD LOCATION & EVIDENCE'
                              : 'NEXT QUESTION',
                          style: AppTypography.labelMd.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.cardLayer1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.strokeLowLight,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withAlpha(40)
                    : AppColors.cardLayer2,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textMediumEmphasis,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMd.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textHighEmphasis,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bilingualCue.copyWith(
                      color: isSelected
                          ? Colors.white.withAlpha(200)
                          : AppColors.textMediumEmphasis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : AppColors.strokeActive,
                  width: 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.primaryAmberDark,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityChip({
    required String label,
    required String sub,
    required ViolationSeverity severity,
    required ViolationSeverity? current,
    required Color color,
  }) {
    final isSelected = current == severity;

    return Expanded(
      child: GestureDetector(
        onTap: () => _setViolationSeverity(severity),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.cardLayer2,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? color : AppColors.strokeActive,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: isSelected ? Colors.white : AppColors.textHighEmphasis,
                  fontSize: 11,
                ),
                maxLines: 1,
              ),
              Text(
                sub,
                style: AppTypography.bodySm.copyWith(
                  color: isSelected
                      ? Colors.white.withAlpha(220)
                      : AppColors.textDisabled,
                  fontSize: 10,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 2: LOCATION & EVIDENCE (Matches Screenshot 3)
  // -------------------------------------------------------------
  Widget _buildLocationAndEvidenceStep() {
    final zones = MineModel.defaultZones;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _currentStep = WizardStep.questions);
          },
        ),
        title: Text('Report', style: AppTypography.headlineSm),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryAmberDark,
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryAmber.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Step 4 of 6  •  Safety Inspection',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.primaryAmber,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Add Location & Evidence',
              style: AppTypography.headlineMd,
            ),
            const SizedBox(height: 4),
            Text(
              'Verify underground surroundings and attach fresh visual evidence.',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.textMediumEmphasis,
              ),
            ),
            const SizedBox(height: 16),

            // Satellite Signals Unavailable Notice Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x20EA580C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.secondaryOrange.withAlpha(120),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.satellite_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Satellite signals unavailable (Underground Strata)',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.textHighEmphasis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You are working underground where rock strata naturally blocks GPS. Simply select your active mine sector below for statutory coordinate binding.',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textMediumEmphasis,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Mine Area List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECT MINE AREA / कार्य क्षेत्र',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.textMediumEmphasis,
                    letterSpacing: 0.8,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.complianceGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ready to save',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.complianceGreen,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            ...zones.map((zone) {
              final isSelected = _report!.zoneId == zone.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: LargeTouchCard(
                  isSelected: isSelected,
                  backgroundColor: isSelected
                      ? AppColors.primaryAmberDark
                      : AppColors.cardLayer1,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  onTap: () {
                    setState(() {
                      _report!.zoneId = zone.id;
                      _report!.zoneName = zone.name;
                      _report!.locationSource = 'manual';
                    });
                    _autoSave();
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.terrain_rounded,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textMediumEmphasis,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          zone.name,
                          style: AppTypography.labelMd.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textHighEmphasis,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : AppColors.strokeActive,
                            width: 2,
                          ),
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: AppColors.primaryAmberDark,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),

            // Current Selected Pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.telemetryBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.telemetryBlue.withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.telemetryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected manually: ${_report!.zoneName ?? "Seam 3 - Gallery 4"}',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.telemetryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Media Evidence Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MEDIA EVIDENCE / साक्ष्य फोटो व वीडियो',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.textMediumEmphasis,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.telemetryBlue.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_report!.globalEvidence.length} Attached',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.telemetryBlue,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_report!.globalEvidence.isNotEmpty)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.cardLayer2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.strokeLowLight),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.photo_library_rounded,
                        size: 54,
                        color: AppColors.textDisabled.withAlpha(80),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.complianceGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              color: AppColors.onPrimary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Attached',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _report!.zoneName ??
                                'Gallery 4 active face',
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dust suppression spray inspection',
                                style: AppTypography.bodySm.copyWith(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '10:42 AM',
                                style: AppTypography.bodySm.copyWith(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Capture Photo Button
            OutlinedButton.icon(
              onPressed: () async {
                final service = ref.read(evidenceServiceProvider);
                final item = await service.capturePhoto(
                  reportClientUuid: _report!.clientUuid,
                  userId: _report!.userId,
                );
                if (item != null && mounted) {
                  setState(() => _report!.globalEvidence.add(item));
                  _autoSave();
                }
              },
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.textHighEmphasis,
              ),
              label: Text(
                'Take Photo Evidence / फोटो लें',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.textHighEmphasis,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Record Video Button
            OutlinedButton.icon(
              onPressed: () async {
                final service = ref.read(evidenceServiceProvider);
                final item = await service.captureVideo(
                  reportClientUuid: _report!.clientUuid,
                  location: await ref
                      .read(locationServiceProvider)
                      .captureLocation(),
                );
                if (item != null && mounted) {
                  setState(() => _report!.globalEvidence.add(item));
                  _autoSave();
                }
              },
              icon: const Icon(
                Icons.videocam_outlined,
                color: AppColors.hazardRed,
              ),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Record Video Evidence / वीडियो रिकॉर्ड करें',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.textHighEmphasis,
                    ),
                  ),
                  Text(
                    'Max 30 seconds • Stored locally',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
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
            border: Border(
              top: BorderSide(color: AppColors.strokeLowLight, width: 1.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep = WizardStep.questions);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.cardLayer2,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back, size: 16),
                      const SizedBox(width: 4),
                      Text('BACK', style: AppTypography.labelMd),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentStep = WizardStep.reviewAndSign);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAmberDark,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'CONTINUE TO REVIEW',
                          style: AppTypography.labelMd.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _violationController.dispose();
    _actionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // STEP 3: REVIEW & STATUTORY SIGNATURE (Submission Locking)
  // -------------------------------------------------------------
  Widget _buildReviewAndSignStep() {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _currentStep = WizardStep.locationAndEvidence);
          },
        ),
        title: Text('Review & Sign', style: AppTypography.headlineSm),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardLayer1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.strokeLowLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STATUTORY INSPECTION SUMMARY',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primaryAmber,
                        ),
                      ),
                      Text(
                        _report!.clientUuid,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mine: ${_report!.mineName}',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.textHighEmphasis,
                    ),
                  ),
                  Text(
                    'Location: ${_report!.zoneName ?? "Underground"}',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.textMediumEmphasis,
                    ),
                  ),
                  Text(
                    'Inspector: ${_report!.userName} (${_report!.userDesignation})',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'CHECKLIST FINDINGS',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.textMediumEmphasis,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            ..._report!.checklist.map((item) {
              Color statusColor = AppColors.textDisabled;
              String statusText = 'UNANSWERED';
              if (item.status == CheckItemStatus.pass) {
                statusColor = AppColors.complianceGreen;
                statusText = 'PASSED';
              } else if (item.status == CheckItemStatus.fail) {
                statusColor = AppColors.hazardRed;
                statusText =
                    'VIOLATION (${item.severity?.name.toUpperCase() ?? "MAJOR"})';
              } else if (item.status == CheckItemStatus.na) {
                statusColor = AppColors.textDisabled;
                statusText = 'N/A';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.strokeLowLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.question,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.textHighEmphasis,
                              fontSize: 13,
                            ),
                          ),
                          if (item.violationDescription != null &&
                              item.violationDescription!.isNotEmpty)
                            Text(
                              'Violation: ${item.violationDescription}',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.hazardRed,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: AppTypography.labelSm.copyWith(
                        color: statusColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Statutory Signature Pad
            SignaturePadWidget(
              signerName: user?.fullName ?? 'Rajesh Sharma',
              signerRole: user?.designation ?? 'Safety Officer',
              initialSignature: _report!.signatureBase64,
              isReadOnly: _report!.status.isLocked,
              onSignatureSaved: (base64Sig) {
                setState(() {
                  _report!.signatureBase64 = base64Sig;
                  _report!.signedAt = DateTime.now();
                });
                _autoSave();
              },
            ),
            const SizedBox(height: 16),

            // Immutable Lock Legal Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x20F59E0B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryAmber.withAlpha(100),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primaryAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upon submission, this statutory record will be permanently locked with a SHA-256 integrity hash. Direct modification is prohibited under the Mines Act.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textHighEmphasis,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(
              top: BorderSide(color: AppColors.strokeLowLight, width: 1.5),
            ),
          ),
          child: ElevatedButton(
            onPressed: _submitFinalInspection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.complianceGreen,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  color: AppColors.onPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'LOCK & SUBMIT STATUTORY REPORT',
                    style: AppTypography.labelLg.copyWith(
                      color: AppColors.onPrimary,
                      letterSpacing: 0.5,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
