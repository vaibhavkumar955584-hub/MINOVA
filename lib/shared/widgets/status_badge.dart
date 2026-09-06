import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/inspection_model.dart';

class StatusBadge extends StatelessWidget {
  final RecordStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;
    String? hindi;

    switch (status) {
      case RecordStatus.draft:
        bg = AppColors.cardLayer2;
        border = AppColors.strokeActive;
        text = AppColors.textMediumEmphasis;
        icon = Icons.edit_note_rounded;
        label = 'DRAFT';
        hindi = 'प्रारूप';
        break;
      case RecordStatus.pendingSync:
        bg = const Color(0x25F59E0B);
        border = AppColors.primaryAmber;
        text = AppColors.primaryAmber;
        icon = Icons.sync_problem_rounded;
        label = 'WAITING FOR SYNC';
        hindi = 'इंटरनेट की प्रतीक्षा';
        break;
      case RecordStatus.syncing:
        bg = const Color(0x253B82F6);
        border = AppColors.telemetryBlue;
        text = AppColors.telemetryBlue;
        icon = Icons.sync_rounded;
        label = 'SYNCING';
        hindi = 'सिंक हो रहा है';
        break;
      case RecordStatus.synced:
        bg = const Color(0x2510B981);
        border = AppColors.complianceGreen;
        text = AppColors.complianceGreen;
        icon = Icons.check_circle_rounded;
        label = 'SENT';
        hindi = 'सुरक्षित भेजा गया';
        break;
      case RecordStatus.syncFailed:
        bg = const Color(0x25EF4444);
        border = AppColors.hazardRed;
        text = AppColors.hazardRed;
        icon = Icons.error_outline_rounded;
        label = 'SYNC FAILED';
        hindi = 'सिंक विफल';
        break;
      case RecordStatus.underReview:
        bg = const Color(0x25EA580C);
        border = AppColors.secondaryOrange;
        text = AppColors.secondaryOrange;
        icon = Icons.hourglass_top_rounded;
        label = 'UNDER REVIEW';
        hindi = 'समीक्षाधीन';
        break;
      case RecordStatus.resolved:
        bg = const Color(0x2510B981);
        border = AppColors.complianceGreen;
        text = AppColors.complianceGreen;
        icon = Icons.task_alt_rounded;
        label = 'RESOLVED';
        hindi = 'समाधानित';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: text,
                fontSize: compact ? 10 : 11,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!compact && hindi.isNotEmpty) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '• $hindi',
                style: AppTypography.bilingualCue.copyWith(
                  color: text.withAlpha(200),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
