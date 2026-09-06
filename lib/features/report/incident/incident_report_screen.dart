import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/evidence_model.dart';
import '../../../models/incident_model.dart';
import '../../../models/inspection_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/ai_copilot_sheet.dart';
import '../../../shared/widgets/large_touch_card.dart';
import '../../../shared/widgets/signature_pad.dart';

class IncidentReportScreen extends ConsumerStatefulWidget {
  final String? initialClientUuid;
  const IncidentReportScreen({super.key, this.initialClientUuid});

  @override
  ConsumerState<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends ConsumerState<IncidentReportScreen> {
  static const String _activeIncidentDraftKey = 'active_incident_draft_uuid';

  late String _submissionId;
  IncidentType _selectedType = IncidentType.injury;
  ViolationSeverity _selectedSeverity = ViolationSeverity.critical;
  final _descriptionController = TextEditingController();
  final _actionController = TextEditingController();
  final _peopleCountController = TextEditingController(text: '1');
  final List<TextEditingController> _personControllers = [
    TextEditingController(),
  ];
  final _equipmentController = TextEditingController();

  bool _medicalAttention = true;
  bool _notifyAuthority = true;
  final List<EvidenceItem> _evidenceList = [];
  String? _signatureBase64;
  bool _isSubmitting = false;
  bool _isAiDrafting = false;
  String? _statutoryIncidentRule;

  @override
  void initState() {
    super.initState();
    _submissionId = widget.initialClientUuid ??
        'INC-EMG-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    _initOrRestoreDraft();
  }

  Future<void> _initOrRestoreDraft() async {
    try {
      final repo = ref.read(incidentRepositoryProvider);
      final prefs = await SharedPreferences.getInstance();

      final candidateUuid =
          widget.initialClientUuid ?? prefs.getString(_activeIncidentDraftKey);
      IncidentReport? existingDraft;

      if (candidateUuid != null && candidateUuid.isNotEmpty) {
        existingDraft = await repo.getDraftByClientUuid(candidateUuid);
      }

      if (existingDraft != null && mounted) {
        _submissionId = existingDraft.clientUuid;
        _selectedType = existingDraft.type;
        _selectedSeverity = existingDraft.severity;
        _descriptionController.text = existingDraft.description;
        _actionController.text = existingDraft.immediateActionTaken;
        _equipmentController.text = existingDraft.equipmentInvolved ?? '';
        _medicalAttention = existingDraft.medicalAttentionRequired;
        _notifyAuthority = existingDraft.notifyAuthorityImmediately;
        _signatureBase64 = existingDraft.signatureBase64;

        _personControllers.clear();
        if (existingDraft.affectedPersonDetails.isNotEmpty) {
          for (final p in existingDraft.affectedPersonDetails) {
            _personControllers.add(TextEditingController(text: p));
          }
        } else {
          _personControllers.add(TextEditingController());
        }
        _peopleCountController.text = existingDraft.peopleAffected > 0
            ? existingDraft.peopleAffected.toString()
            : _personControllers.length.toString();

        _evidenceList.clear();
        _evidenceList.addAll(existingDraft.evidence);
      } else {
        _submissionId = widget.initialClientUuid ??
            'INC-EMG-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      }

      await prefs.setString(_activeIncidentDraftKey, _submissionId);
      await _recoverLostEvidence();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveDraftLocally() async {
    final user = ref.read(authStateProvider);
    if (user == null) return;
    try {
      final repo = ref.read(incidentRepositoryProvider);
      final affectedPersons = _getAffectedPersons();
      final count = int.tryParse(_peopleCountController.text) ?? affectedPersons.length;

      final draft = IncidentReport(
        clientUuid: _submissionId,
        mineId: user.assignedMineId.isNotEmpty
            ? user.assignedMineId
            : (user.assignedMineIds.isNotEmpty ? user.assignedMineIds.first : ''),
        mineName: user.assignedMineName.isNotEmpty
            ? user.assignedMineName
            : 'Assigned Mine',
        userId: user.id,
        userName: user.fullName,
        userDesignation: user.designation,
        type: _selectedType,
        severity: _selectedSeverity,
        peopleAffected: count > 0 ? count : (affectedPersons.isNotEmpty ? affectedPersons.length : 0),
        affectedPersonDetails: affectedPersons,
        description: _descriptionController.text.trim(),
        immediateActionTaken: _actionController.text.trim(),
        medicalAttentionRequired: _medicalAttention,
        equipmentInvolved: _equipmentController.text.trim().isNotEmpty
            ? _equipmentController.text.trim()
            : null,
        notifyAuthorityImmediately: _notifyAuthority,
        status: RecordStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        evidence: _evidenceList,
        signatureBase64: _signatureBase64,
      );
      await repo.autoSaveDraft(draft);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeIncidentDraftKey, _submissionId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _actionController.dispose();
    _peopleCountController.dispose();
    for (final c in _personControllers) {
      c.dispose();
    }
    _equipmentController.dispose();
    super.dispose();
  }

  void _addPersonField([String initialText = '']) {
    setState(() {
      _personControllers.add(TextEditingController(text: initialText));
      _peopleCountController.text = _personControllers.length.toString();
    });
  }

  void _removePersonField(int index) {
    if (_personControllers.length > 1) {
      setState(() {
        _personControllers[index].dispose();
        _personControllers.removeAt(index);
        _peopleCountController.text = _personControllers.length.toString();
      });
    } else {
      setState(() {
        _personControllers[0].clear();
        _peopleCountController.text = '0';
      });
    }
  }

  List<String> _getAffectedPersons() {
    return _personControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  Future<void> _recoverLostEvidence() async {
    final evidenceService = ref.read(evidenceServiceProvider);
    final lost = await evidenceService.retrieveLostPhoto(reportClientUuid: _submissionId);
    if (lost != null && mounted) {
      if (!_evidenceList.any((e) => e.sha256Hash == lost.sha256Hash || e.localFilePath == lost.localFilePath)) {
        setState(() => _evidenceList.add(lost));
        await _saveDraftLocally();
      }
    }
  }

  Future<void> _runGeminiIncidentCopilot() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the incident first! / कृपया पहले घटना का विवरण लिखें।'),
          backgroundColor: AppColors.hazardRed,
        ),
      );
      return;
    }

    setState(() => _isAiDrafting = true);

    try {
      final copilot = ref.read(geminiCopilotServiceProvider);
      final analysis = await copilot.analyzeIncident(
        incidentType: _selectedType.displayName,
        roughDescription: _descriptionController.text.trim(),
      );

      if (mounted) {
        AiCopilotReviewSheet.show(
          context,
          headline: analysis.headline,
          originalText: _descriptionController.text.trim(),
          refinedText: analysis.refinedDescription,
          severity: analysis.suggestedSeverity,
          regulationHint: analysis.statutoryRegulation,
          recommendedAction: analysis.suggestedImmediateAction,
          isIncident: true,
          onApplyAll: () {
            setState(() {
              _descriptionController.text = analysis.refinedDescription;
              _actionController.text = analysis.suggestedImmediateAction;
              _selectedSeverity = analysis.suggestedSeverity;
              _medicalAttention = analysis.medicalAttentionRecommended;
              _notifyAuthority = analysis.notifyAuthorityImmediately;
              _statutoryIncidentRule = analysis.statutoryRegulation;
            });
            _saveDraftLocally();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.complianceGreen, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI statutory incident containment applied!',
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
      if (mounted) setState(() => _isAiDrafting = false);
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
                'ATTACH INCIDENT EVIDENCE / घटना साक्ष्य जोड़ें',
                style: AppTypography.labelSm.copyWith(color: AppColors.hazardRed),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.hazardRed.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.hazardRed),
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

    await _saveDraftLocally();

    try {
      final evidenceService = ref.read(evidenceServiceProvider);
      final item = await evidenceService.capturePhoto(
        reportClientUuid: _submissionId,
        source: source,
        caption: 'Emergency Incident Evidence',
      );
      if (item != null && mounted) {
        setState(() => _evidenceList.add(item));
        await _saveDraftLocally();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not capture photo. Please try again.'),
            backgroundColor: AppColors.hazardRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitIncident() async {
    if (_descriptionController.text.trim().isEmpty || _actionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.incidentHint),
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
      final repo = ref.read(incidentRepositoryProvider);
      final affectedPersons = _getAffectedPersons();
      final count = int.tryParse(_peopleCountController.text) ?? affectedPersons.length;

      final report = await repo.createDraft(
        clientUuid: _submissionId,
        user: user,
        type: _selectedType,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        immediateActionTaken: _actionController.text.trim(),
        peopleAffected: count > 0 ? count : (affectedPersons.isNotEmpty ? affectedPersons.length : 0),
        affectedPersonDetails: affectedPersons,
        medicalAttentionRequired: _medicalAttention,
        equipmentInvolved: _equipmentController.text.trim().isNotEmpty
            ? _equipmentController.text.trim()
            : null,
        notifyAuthorityImmediately: _notifyAuthority,
      );

      // Capture active location
      final locationService = ref.read(locationServiceProvider);
      final loc = await locationService.captureLocation();
      report.latitude = loc.latitude;
      report.longitude = loc.longitude;
      report.accuracy = loc.accuracy;
      report.locationSource = loc.locationSource;
      report.zoneId = loc.zoneId;
      report.zoneName = loc.zoneName;

      report.evidence = _evidenceList;
      report.signatureBase64 = _signatureBase64;
      report.signedAt = DateTime.now();

      await repo.submitAndLockIncident(report);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeIncidentDraftKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.reportSaved),
            backgroundColor: AppColors.complianceGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.hazardRed,
          ),
        );
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.hazardRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.cardLayer2,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.hazardRed, size: 22),
            const SizedBox(width: 8),
            Text(
              'Emergency Incident Log',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.hazardRed,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority Alert Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.hazardRed.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.hazardRed, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign_rounded, color: AppColors.hazardRed, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUTORY EMERGENCY NOTICE (CMR REG 116 / MINES ACT SEC 23)',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.hazardRed,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Report dangerous occurrences, personal injuries, or catastrophic equipment failure for statutory escalation.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.textMediumEmphasis),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. Incident Type Selector
            Text('INCIDENT CLASSIFICATION / घटना का प्रकार', style: AppTypography.labelSm),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncidentType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.hazardRed,
                  backgroundColor: AppColors.cardLayer1,
                  labelStyle: AppTypography.labelSm.copyWith(
                    color: isSelected ? Colors.white : AppColors.textHighEmphasis,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // 2. Severity
            Text('SEVERITY LEVEL / गंभीरता स्तर', style: AppTypography.labelSm),
            const SizedBox(height: 8),
            Row(
              children: ViolationSeverity.values.map((sev) {
                final isSelected = _selectedSeverity == sev;
                final color = sev == ViolationSeverity.critical
                    ? AppColors.hazardRed
                    : sev == ViolationSeverity.major
                        ? AppColors.secondaryOrange
                        : AppColors.primaryAmber;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: LargeTouchCard(
                      isSelected: isSelected,
                      backgroundColor: isSelected ? color : AppColors.cardLayer1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      onTap: () => setState(() => _selectedSeverity = sev),
                      child: Center(
                        child: Text(
                          sev.name.toUpperCase(),
                          style: AppTypography.labelSm.copyWith(
                            color: isSelected ? Colors.white : AppColors.textHighEmphasis,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // 3. People Affected (Dynamic Multi-Person Input List)
            Text('PERSONS AFFECTED & DETAILS / प्रभावित व्यक्ति', style: AppTypography.labelSm),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardLayer1,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.strokeLowLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, color: AppColors.primaryAmber, size: 18),
                      const SizedBox(width: 8),
                      Text('Count: ${_peopleCountController.text}', style: AppTypography.labelSm),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _addPersonField,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          side: const BorderSide(color: AppColors.telemetryBlue),
                        ),
                        icon: const Icon(Icons.add, size: 14, color: AppColors.telemetryBlue),
                        label: const Text(
                          'Add Person',
                          style: TextStyle(fontSize: 11, color: AppColors.telemetryBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._personControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              onChanged: (_) {
                                setState(() {
                                  _peopleCountController.text = _getAffectedPersons().length.toString();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g. A. K. Banerjee (Operator)',
                                labelText: 'Person #${index + 1} Name / Details',
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_personControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.hazardRed, size: 20),
                              onPressed: () => _removePersonField(index),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Equipment Involved
            Text('EQUIPMENT INVOLVED / उपकरण या मशीनरी (Optional)', style: AppTypography.labelSm),
            const SizedBox(height: 6),
            TextField(
              controller: _equipmentController,
              decoration: const InputDecoration(
                hintText: 'e.g. Hydraulic Roof Support Stand #H-12 / CAT 777D Haul Truck',
              ),
            ),
            const SizedBox(height: 16),

            // 5. Description
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'WHAT HAPPENED? (DESCRIPTION / विवरण)',
                    style: AppTypography.labelSm,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick templates',
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
                    avatar: const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.hazardRed),
                    label: const Text('Roof Fall / Side Collapse (छत गिरना)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _descriptionController.text = 'Roof fall at Seam 4 junction during depillaring operations. High risk strata pressure displacement.';
                      _runGeminiIncidentCopilot();
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.secondaryOrange),
                    label: const Text('Fire / Gas Ignition (आग/धुआं)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _descriptionController.text = 'Electrical switchgear panel flashover and localized cable smoldering in substation switchyard.';
                      _runGeminiIncidentCopilot();
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.medical_services_rounded, size: 14, color: AppColors.hazardRed),
                    label: const Text('Worker Injury (मजदूर को चोट)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _descriptionController.text = 'Miner sustained leg fracture during haulage rope operation.';
                      _runGeminiIncidentCopilot();
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.car_crash_rounded, size: 14, color: AppColors.telemetryBlue),
                    label: const Text('Machinery Crash (डंपर/मशीन दुर्घटना)'),
                    labelStyle: const TextStyle(fontSize: 11),
                    backgroundColor: AppColors.cardLayer2,
                    onPressed: () {
                      _descriptionController.text = 'Dumper brake failure on haul road incline; collision with embankment.';
                      _runGeminiIncidentCopilot();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe machinery failure, roof spalling, gas release, or worker injury in detail...',
              ),
            ),
            const SizedBox(height: 8),

            // AI Copilot Action Button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _isAiDrafting ? null : _runGeminiIncidentCopilot,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.telemetryBlue.withAlpha(20),
                  side: BorderSide(color: AppColors.telemetryBlue.withAlpha(120)),
                ),
                icon: _isAiDrafting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.telemetryBlue),
                      )
                    : const Icon(Icons.auto_awesome, color: AppColors.telemetryBlue, size: 16),
                label: Text(
                  _isAiDrafting ? 'DRAFTING...' : 'AI TRIAGE & ACTION DRAFT (AI सुझाव)',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.telemetryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            if (_statutoryIncidentRule != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.hazardRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.hazardRed.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel_rounded, color: AppColors.hazardRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Statutory Citation: $_statutoryIncidentRule',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.hazardRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // 6. Immediate Action Taken
            Text('IMMEDIATE RESCUE / ACTION TAKEN (त्वरित कार्रवाई)', style: AppTypography.labelSm),
            const SizedBox(height: 6),
            TextField(
              controller: _actionController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Power cut, ventilation increased, first aid administered, area isolated...',
              ),
            ),
            const SizedBox(height: 16),

            // 7. Toggles (Medical Attention & Authority Alert)
            CheckboxListTile(
              title: Text('Medical attention / First aid required (चिकित्सा सहायता)', style: AppTypography.bodyMd),
              value: _medicalAttention,
              activeColor: AppColors.primaryAmber,
              onChanged: (val) => setState(() => _medicalAttention = val ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text('Broadcast urgent alert to Mine Dispatcher & DGMS', style: AppTypography.bodyMd),
              subtitle: Text(
                'Status will queue offline until subterranean/surface network connects',
                style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled),
              ),
              value: _notifyAuthority,
              activeColor: AppColors.hazardRed,
              onChanged: (val) => setState(() => _notifyAuthority = val ?? true),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // 8. Photo Evidence Capture & Visual Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'PHOTO EVIDENCE / साक्ष्य फोटो (${_evidenceList.length} ATTACHED)',
                    style: AppTypography.labelSm,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_evidenceList.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Tap ✕ to remove',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            if (_evidenceList.isNotEmpty) ...[
              SizedBox(
                height: 115,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _evidenceList.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = _evidenceList[index];
                    final file = File(item.localFilePath);
                    final exists = file.existsSync();

                    return Container(
                      width: 115,
                      decoration: BoxDecoration(
                        color: AppColors.cardLayer2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.strokeLowLight),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: exists
                                  ? Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: AppColors.cardLayer1,
                                        child: const Center(
                                          child: Icon(Icons.broken_image_rounded, color: AppColors.textDisabled, size: 28),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.cardLayer1,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.photo_camera_rounded, color: AppColors.primaryAmber, size: 28),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Photo #${index + 1}',
                                            style: AppTypography.labelSm.copyWith(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withAlpha(220),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                              ),
                              child: Text(
                                'Photo ${index + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _evidenceList.removeAt(index));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(180),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.hazardRed,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _captureEvidence,
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textHighEmphasis),
                label: Text(
                  _evidenceList.isEmpty
                      ? 'CAPTURE INCIDENT PHOTO'
                      : 'ADD ANOTHER PHOTO (${_evidenceList.length} ATTACHED)',
                  style: AppTypography.labelMd,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 9. Digital Signature Pad
            SignaturePadWidget(
              signerName: user?.fullName ?? 'Reporter',
              signerRole: user?.designation ?? 'Field Official',
              initialSignature: _signatureBase64,
              onSignatureSaved: (sig) => _signatureBase64 = sig,
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
            border: Border(top: BorderSide(color: AppColors.strokeLowLight, width: 1.5)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitIncident,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hazardRed,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'SUBMIT EMERGENCY INCIDENT REPORT',
                            style: AppTypography.labelLg.copyWith(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
