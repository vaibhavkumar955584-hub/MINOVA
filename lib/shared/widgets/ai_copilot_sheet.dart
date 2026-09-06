import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/inspection_model.dart';
import '../../models/observation_model.dart';

class AiCopilotReviewSheet extends StatefulWidget {
  final String headline;
  final String originalText;
  final String refinedText;
  final ViolationSeverity severity;
  final ObservationCategory? category;
  final String? regulationHint;
  final String? recommendedAction;
  final bool isIncident;
  final VoidCallback onApplyAll;
  final VoidCallback? onApplyTextOnly;
  final VoidCallback? onApplyActionOnly;

  const AiCopilotReviewSheet({
    super.key,
    this.headline = 'Statutory AI Formulation',
    required this.originalText,
    required this.refinedText,
    required this.severity,
    this.category,
    this.regulationHint,
    this.recommendedAction,
    this.isIncident = false,
    required this.onApplyAll,
    this.onApplyTextOnly,
    this.onApplyActionOnly,
  });

  static Future<void> show(
    BuildContext context, {
    String headline = 'Statutory AI Formulation',
    required String originalText,
    required String refinedText,
    required ViolationSeverity severity,
    ObservationCategory? category,
    String? regulationHint,
    String? recommendedAction,
    bool isIncident = false,
    required VoidCallback onApplyAll,
    VoidCallback? onApplyTextOnly,
    VoidCallback? onApplyActionOnly,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiCopilotReviewSheet(
        headline: headline,
        originalText: originalText,
        refinedText: refinedText,
        severity: severity,
        category: category,
        regulationHint: regulationHint,
        recommendedAction: recommendedAction,
        isIncident: isIncident,
        onApplyAll: onApplyAll,
        onApplyTextOnly: onApplyTextOnly,
        onApplyActionOnly: onApplyActionOnly,
      ),
    );
  }

  @override
  State<AiCopilotReviewSheet> createState() => _AiCopilotReviewSheetState();
}

class _AiCopilotReviewSheetState extends State<AiCopilotReviewSheet> {
  bool _showOriginalComparison = false;

  Color get _severityColor {
    switch (widget.severity) {
      case ViolationSeverity.critical:
        return AppColors.hazardRed;
      case ViolationSeverity.major:
        return AppColors.secondaryOrange;
      case ViolationSeverity.minor:
        return AppColors.complianceGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardLayer1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.primaryAmber, width: 2.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Grab Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.strokeLowLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Banner
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryAmber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AI STATUTORY COPILOT',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primaryAmber,
                              letterSpacing: 0.8,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DGMS / CMR',
                              style: TextStyle(
                                color: AppColors.textDisabled,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _severityColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _severityColor.withAlpha(120)),
                  ),
                  child: Text(
                    widget.severity.name.toUpperCase(),
                    style: AppTypography.labelSm.copyWith(
                      color: _severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Regulation Tag if present
            if (widget.regulationHint != null && widget.regulationHint!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryAmber.withAlpha(70)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      color: AppColors.primaryAmber,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.regulationHint!,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primaryAmber,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Refined Phrasing Box with Comparison Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STATUTORY NARRATIVE / वैधानिक विवरण',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                if (widget.originalText.trim().isNotEmpty &&
                    widget.originalText.trim() != widget.refinedText.trim())
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showOriginalComparison = !_showOriginalComparison;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        _showOriginalComparison ? 'Hide Original / छुपाएं' : 'Compare Original / मूल देखें',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.telemetryBlue,
                          fontSize: 10,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            if (_showOriginalComparison) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer2.withAlpha(120),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.strokeLowLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORIGINAL DRAFT / आपका लिखा:',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.originalText,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textMediumEmphasis,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardLayer2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.strokeActive),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.refinedText,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.textHighEmphasis,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: widget.refinedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied refined narrative to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 13, color: AppColors.textDisabled),
                          const SizedBox(width: 4),
                          Text(
                            'Copy Text',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.textDisabled,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Recommended Containment Action if present
            if (widget.recommendedAction != null && widget.recommendedAction!.isNotEmpty) ...[
              Text(
                'RECOMMENDED ACTION / त्वरित कार्रवाई',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1510B981),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.complianceGreen.withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.complianceGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.recommendedAction!,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.complianceGreen,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.strokeLowLight),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'DISCARD\nमूल रखें',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.textMediumEmphasis,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApplyAll();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAmberDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'APPLY ALL\nपूरा लागू करें',
                            textAlign: TextAlign.center,
                            style: AppTypography.labelSm.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
