import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/mine_model.dart';
import 'large_touch_card.dart';

class LocationPickerSheet extends StatefulWidget {
  final MineZone selectedZone;
  final ValueChanged<MineZone> onZoneSelected;

  const LocationPickerSheet({
    super.key,
    required this.selectedZone,
    required this.onZoneSelected,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late MineZone _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selectedZone;
  }

  @override
  Widget build(BuildContext context) {
    final zones = MineModel.defaultZones;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.strokeActive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.satellite_alt_rounded, color: AppColors.primaryAmber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SELECT UNDERGROUND ZONE / SEAM',
                  style: AppTypography.labelMd.copyWith(color: AppColors.primaryAmber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'GPS satellite signals are blocked by subterranean rock strata. Choose sector below:',
            style: AppTypography.bodySm.copyWith(color: AppColors.textMediumEmphasis),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: zones.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final zone = zones[index];
                final isSelected = zone.id == _current.id;

                return LargeTouchCard(
                  isSelected: isSelected,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: () {
                    setState(() {
                      _current = zone;
                    });
                    widget.onZoneSelected(zone);
                    Navigator.pop(context);
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.terrain_rounded,
                        color: isSelected ? AppColors.primaryAmber : AppColors.textDisabled,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zone.name,
                              style: AppTypography.labelMd.copyWith(
                                color: isSelected ? AppColors.primaryAmber : AppColors.textHighEmphasis,
                              ),
                            ),
                            Text(
                              '${zone.depthLevel} • ${zone.description}',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.textDisabled,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            color: isSelected ? AppColors.primaryAmber : AppColors.strokeActive,
                            width: 2,
                          ),
                          color: isSelected ? AppColors.primaryAmber : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
