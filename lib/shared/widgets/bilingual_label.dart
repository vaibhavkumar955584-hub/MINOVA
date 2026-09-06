import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class BilingualLabel extends StatelessWidget {
  final String primaryEnglish;
  final String secondaryHindi;
  final TextStyle? englishStyle;
  final TextStyle? hindiStyle;
  final CrossAxisAlignment crossAxisAlignment;

  const BilingualLabel({
    super.key,
    required this.primaryEnglish,
    required this.secondaryHindi,
    this.englishStyle,
    this.hindiStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryEnglish,
          style: englishStyle ?? AppTypography.labelMd,
        ),
        const SizedBox(height: 2),
        Text(
          secondaryHindi,
          style: hindiStyle ??
              AppTypography.bilingualCue.copyWith(
                color: AppColors.textMediumEmphasis,
              ),
        ),
      ],
    );
  }
}
