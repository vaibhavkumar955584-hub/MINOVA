import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/evidence_model.dart';
import '../../../models/observation_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/ai_copilot_sheet.dart';
import '../../../shared/widgets/large_touch_card.dart';
import '../../../shared/widgets/signature_pad.dart';

class ObservationScreen extends ConsumerStatefulWidget {
  const ObservationScreen({super.key});

  @override
  ConsumerState<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends ConsumerState<ObservationScreen> {
  ObservationType _type = ObservationType.observation;
  ObservationCategory _category = ObservationCategory.safety;
  final _textController = TextEditingController();
  final _ch4Controller = TextEditingController(text: '0.12');
  final _coController = TextEditingController(text: '4');
  final _o2Controller = TextEditingController(text: '20.8');

  bool _isRecordingVoice = false;
  String? _voiceNoteText;
  final List<EvidenceItem> _evidenceList = [];
  String? _signatureBase64;
  bool _isSubmitting = false;
  bool _isAiAnalyzing = false;
  String? _statutoryAiRegulation;
  String? _suggestedAiAction;

  @override
  void initState() {
    super.initState();
    _recoverLostEvidence();
  }

  Future<void> _recoverLostEvidence() async {
    final evidenceService = ref.read(evidenceServiceProvider);
    final lost = await evidenceService.retrieveLostPhoto(reportClientUuid: 'temp_obs');
    if (lost != null && mounted) {
      setState(() => _evidenceList.add(lost));
    }
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isRecordingVoice = !_isRecordingVoice;
      if (!_isRecordingVoice) {
        _voiceNoteText = 'Voice note recorded (14s): "Checked roof bolts at ventilation gallery 1, sound strata with no cracks."';
        _textController.text = _voiceNoteText!;
      }
    });
  }

  Future<void> _runGeminiCopilot() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or record observation notes first! / कृपया पहले विवरण लिखें।'),
          backgroundColor: AppColors.secondaryOrange,
        ),
      );
      return;
    }

    setState(() => _isAiAnalyzing = true);

    try {
      final copilot = ref.read(geminiCopilotServiceProvider);
      final ch4 = double.tryParse(_ch4Controller.text);
      final co = int.tryParse(_coController.text);
      final o2 = double.tryParse(_o2Controller.text);

      final analysis = await copilot.analyzeObservation(
        rawNotes: _textController.text.trim(),
        ch4: ch4,
        co: co,
        o2: o2,
      );

      if (mounted) {
        AiCopilotReviewSheet.show(
          context,
          headline: analysis.headline,
          originalText: _textController.text.trim(),
          refinedText: analysis.refinedDescription,
          severity: analysis.suggestedSeverity,
          category: analysis.suggestedCategory,
          regulationHint: analysis.statutoryRegulationHint,
          recommendedAction: analysis.recommendedImmediateAction,
          onApplyAll: () {
            setState(() {
              _textController.text = analysis.refinedDescription;
              _category = analysis.suggestedCategory;
              _statutoryAiRegulation = analysis.statutoryRegulationHint;
              _suggestedAiAction = analysis.recommendedImmediateAction;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.complianceGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI statutory formulation applied to report!',
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
      if (mounted) setState(() => _isAiAnalyzing = false);
    }
  }

  Future<ImageSource?> _showPhotoSourceDialog() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardLayer1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ATTACH EVIDENCE / साक्ष्य जोड़ें',
                style: AppTypography.labelSm.copyWith(color: AppColors.primaryAmber),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryAmber),
                ),
                title: const Text('Live Camera Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('कैमरा से लाइव फोटो लें', style: TextStyle(fontSize: 11, color: AppColors.textDisabled)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const Divider(color: AppColors.strokeLowLight),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.telemetryBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.telemetryBlue),
                ),
                title: const Text('Gallery / Storage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('गैलरी से फोटो चुनें', style: TextStyle(fontSize: 11, color: AppColors.textDisabled)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureEvidence() async {
    final source = await _showPhotoSourceDialog();
    if (source == null) return;

    final evidenceService = ref.read(evidenceServiceProvider);
    final locationService = ref.read(locationServiceProvider);
    final loc = await locationService.captureLocation();

    final item = await evidenceService.capturePhoto(
      reportClientUuid: 'temp_obs',
      location: loc,
      source: source,
      caption: '${_type.name.toUpperCase()}: ${_category.displayName}',
    );
    if (item != null && mounted) {
      setState(() => _evidenceList.add(item));
    }
  }

  Future<void> _submitObservation() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.observation),
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
      final repo = ref.read(observationRepositoryProvider);
      final locationService = ref.read(locationServiceProvider);
      final loc = await locationService.captureLocation();

      final ch4 = double.tryParse(_ch4Controller.text);
      final co = int.tryParse(_coController.text);
      final o2 = double.tryParse(_o2Controller.text);

      final report = await repo.createDraft(
        user: user,
        entryType: _type,
        category: _category,
        description: _textController.text.trim(),
        voiceTranscription: _voiceNoteText,
        ch4Percent: ch4,
        coPpm: co,
        o2Percent: o2,
        evidence: _evidenceList,
      );

      report.latitude = loc.latitude;
      report.longitude = loc.longitude;
      report.accuracy = loc.accuracy;
      report.locationSource = loc.locationSource;
      report.signatureBase64 = _signatureBase64;

      await repo.submitAndLockObservation(report);

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
        title: Text(
          _type == ObservationType.observation ? 'Observation Log' : 'Grievance Record',
          style: AppTypography.headlineSm,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entry Type Segment
            Row(
              children: [
                Expanded(
                  child: LargeTouchCard(
                    isSelected: _type == ObservationType.observation,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onTap: () => setState(() => _type = ObservationType.observation),
                    child: Center(
                      child: Text(
                        'OBSERVATION / अवलोकन',
                        style: AppTypography.labelSm.copyWith(
                          color: _type == ObservationType.observation ? AppColors.primaryAmber : AppColors.textDisabled,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LargeTouchCard(
                    isSelected: _type == ObservationType.grievance,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onTap: () => setState(() => _type = ObservationType.grievance),
                    child: Center(
                      child: Text(
                        'GRIEVANCE / शिकायत',
                        style: AppTypography.labelSm.copyWith(
                          color: _type == ObservationType.grievance ? AppColors.secondaryOrange : AppColors.textDisabled,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Selector
            Text('CATEGORY / श्रेणी', style: AppTypography.labelSm),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ObservationCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.primaryAmberDark,
                  backgroundColor: AppColors.cardLayer1,
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Gas Readings Telemetry Block
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
                        'ATMOSPHERIC TELEMETRY (MULTI-GAS)',
                        style: AppTypography.labelSm.copyWith(color: AppColors.telemetryBlue),
                      ),
                      const Icon(Icons.sensors_rounded, color: AppColors.telemetryBlue, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DGMS Safe Limits: CH4 < 0.75% | CO < 50 PPM | O2 > 19.0%',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ch4Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'CH4 (%)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _coController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'CO (PPM)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _o2Controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'O2 (%)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Observation Notes Header & Quick Templates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DESCRIPTION / विवरण', style: AppTypography.labelSm),
                Text(
                  'Quick templates below',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.primaryAmber),
                    label: const Text('Roof Strata (छत में दरार)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _textController.text = 'Strata crack and loose roof coal observed near face.';
                      _runGeminiCopilot();
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.air_rounded, size: 14, color: AppColors.telemetryBlue),
                    label: const Text('Gas Alert (गैस चेतावनी)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _textController.text = 'Elevated methane CH4 reading and reduced ventilation airflow.';
                      _runGeminiCopilot();
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.bolt_rounded, size: 14, color: AppColors.secondaryOrange),
                    label: const Text('Electrical (विद्युत केबल)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _textController.text = 'Exposed electrical cable without flameproof packing.';
                      _runGeminiCopilot();
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.precision_manufacturing_rounded, size: 14, color: AppColors.textMediumEmphasis),
                    label: const Text('Haulage (हॉलेज/कन्वेयर)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _textController.text = 'Haulage tub derailment and defective pull-wire trip switch.';
                      _runGeminiCopilot();
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.water_drop_rounded, size: 14, color: AppColors.complianceGreen),
                    label: const Text('Dust/Sump (धूल/जलभराव)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _textController.text = 'Excessive airborne coal dust and defective water mist sprays.';
                      _runGeminiCopilot();
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.telemetryBlue),
                    label: const Text('Welfare (मजदूर कल्याण)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _textController.text = 'Drinking water facility unhygienic and PPE dust masks unavailable.';
                      _runGeminiCopilot();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter observation, hazard sighting in English or Hindi, or tap quick templates above...',
              ),
            ),
            const SizedBox(height: 10),

            // Voice & AI Copilot Action Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleVoiceRecording,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isRecordingVoice ? AppColors.hazardRed.withAlpha(30) : AppColors.cardLayer2,
                      side: BorderSide(color: _isRecordingVoice ? AppColors.hazardRed : AppColors.strokeActive),
                    ),
                    icon: Icon(
                      _isRecordingVoice ? Icons.stop_circle_rounded : Icons.mic_rounded,
                      color: _isRecordingVoice ? AppColors.hazardRed : AppColors.primaryAmber,
                      size: 18,
                    ),
                    label: Text(
                      _isRecordingVoice ? 'STOP RECORDING' : 'VOICE NOTE (आवाज़)',
                      style: AppTypography.labelSm.copyWith(
                        color: _isRecordingVoice ? AppColors.hazardRed : AppColors.primaryAmber,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAiAnalyzing ? null : _runGeminiCopilot,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.telemetryBlue.withAlpha(20),
                      side: BorderSide(color: AppColors.telemetryBlue.withAlpha(120)),
                    ),
                    icon: _isAiAnalyzing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.telemetryBlue),
                          )
                        : const Icon(Icons.auto_awesome, color: AppColors.telemetryBlue, size: 18),
                    label: Text(
                      _isAiAnalyzing ? 'ANALYZING...' : 'AI DGMS POLISH (AI भाषा)',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.telemetryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Statutory Regulation Citation Banner (from AI)
            if (_statutoryAiRegulation != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryAmber.withAlpha(120)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel_rounded, color: AppColors.primaryAmber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _statutoryAiRegulation!,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primaryAmber,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_suggestedAiAction != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Suggested Action: $_suggestedAiAction',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textMediumEmphasis,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 18),

            // Photos / Videos Evidence
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('PHOTO / VIDEO EVIDENCE / साक्ष्य', style: AppTypography.labelSm),
                Text(
                  '${_evidenceList.length} Attached',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_evidenceList.isNotEmpty)
              ..._evidenceList.map(
                (ev) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cardLayer1,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.strokeLowLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: AppColors.primaryAmber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ev.caption ?? 'Evidence item',
                          style: AppTypography.labelSm.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.hazardRed, size: 20),
                        onPressed: () => setState(() => _evidenceList.remove(ev)),
                      ),
                    ],
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _captureEvidence,
              icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryAmber),
              label: Text(
                _evidenceList.isEmpty ? '+ ADD PHOTO / VIDEO EVIDENCE' : '+ ADD ANOTHER EVIDENCE',
                style: AppTypography.labelMd.copyWith(color: AppColors.primaryAmber),
              ),
            ),
            const SizedBox(height: 20),

            // Statutory Digital Signature Pad
            Text('DIGITAL SIGNATURE / डिजिटल हस्ताक्षर', style: AppTypography.labelSm),
            const SizedBox(height: 4),
            Text(
              'Sign to authenticate this statutory observation/grievance log.',
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
            onPressed: _isSubmitting ? null : _submitObservation,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: AppColors.onPrimary)
                : Text(
                    'SUBMIT STATUTORY LOG',
                    style: AppTypography.labelLg.copyWith(color: AppColors.onPrimary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}
