import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LargeTouchCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isHazard;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const LargeTouchCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.isHazard = false,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.strokeLowLight;
    if (isHazard) {
      borderColor = AppColors.hazardRed;
    } else if (isSelected) {
      borderColor = AppColors.primaryAmber;
    }

    Color bg = backgroundColor ?? (isSelected ? AppColors.cardLayer2 : AppColors.cardLayer1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected || isHazard ? 2.0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryAmber.withAlpha(40),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}
