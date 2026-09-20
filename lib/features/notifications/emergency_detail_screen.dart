import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/emergency_notification_model.dart';
import '../../models/incident_model.dart';
import '../../models/inspection_model.dart';
import '../../shared/providers/app_providers.dart';
import '../report/incident/incident_report_screen.dart';

class EmergencyDetailScreen extends ConsumerStatefulWidget {
  final EmergencyNotificationModel notification;

  const EmergencyDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  ConsumerState<EmergencyDetailScreen> createState() =>
      _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends ConsumerState<EmergencyDetailScreen> {
  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() {
    ref
        .read(emergencyNotificationServiceProvider)
        .markAsRead(widget.notification.id);
  }

  void _openLocationDialog(BuildContext context) {
    final hasCoords = widget.notification.latitude != null &&
        widget.notification.longitude != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardLayer1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.strokeLowLight),
        ),
        title: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.telemetryBlue),
            const SizedBox(width: 8),
            Text(
              'Incident Location',
              style: AppTypography.headlineSm.copyWith(fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.notification.locationDisplay,
              style: AppTypography.labelLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (hasCoords) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed_rounded,
                        size: 16, color: AppColors.primaryAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GPS Coordinates:\nLat: ${widget.notification.latitude!.toStringAsFixed(5)}\nLong: ${widget.notification.longitude!.toStringAsFixed(5)}',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.primaryAmber,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Precise subterranean GPS coordinates unavailable for this sector. Please navigate via marked gallery signage.',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }

  void _openReportIncident() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncidentReportScreen(
          initialIncidentType: widget.notification.incidentType,
          initialLocationDescription: widget.notification.locationDisplay,
          initialLatitude: widget.notification.latitude,
          initialLongitude: widget.notification.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final isCritical = notif.severity == ViolationSeverity.critical;
    final badgeColor = isCritical ? AppColors.hazardRed : AppColors.secondaryOrange;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.cardLayer2,
        title: Text(
          'Emergency Incident Details',
          style: AppTypography.headlineSm.copyWith(fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Critical Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor, width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  notif.severity.name.toUpperCase(),
                                  style: AppTypography.labelSm.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ID: ${notif.id}',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notif.title,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Main Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.strokeLowLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Incident Type
                    _buildInfoTile(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.hazardRed,
                      label: 'EMERGENCY TYPE / घटना का प्रकार',
                      value: notif.incidentType.displayName,
                    ),
                    const Divider(color: AppColors.strokeLowLight, height: 20),

                    // Location
                    _buildInfoTile(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.telemetryBlue,
                      label: 'MINE LOCATION / खदान स्थल',
                      value: notif.locationDisplay,
                      subValue: notif.latitude != null && notif.longitude != null
                          ? 'GPS: ${notif.latitude!.toStringAsFixed(4)}, ${notif.longitude!.toStringAsFixed(4)}'
                          : null,
                    ),
                    const Divider(color: AppColors.strokeLowLight, height: 20),

                    // Target Specialist
                    _buildInfoTile(
                      icon: Icons.engineering_rounded,
                      iconColor: AppColors.primaryAmber,
                      label: 'TARGETED SPECIALIST / लक्षित विशेषज्ञ',
                      value: notif.targetSpecialist.toUpperCase(),
                    ),
                    const Divider(color: AppColors.strokeLowLight, height: 20),

                    // Description
                    Text(
                      'SITUATION OVERVIEW / स्थिति विवरण',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.description,
                      style: AppTypography.bodyMd.copyWith(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Dispatch Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAmber.withAlpha(100),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.integration_instructions_rounded,
                          color: AppColors.primaryAmber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'RESPONSE INSTRUCTIONS / निर्देश',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primaryAmber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notif.instructions,
                      style: AppTypography.bodyMd.copyWith(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openLocationDialog(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.telemetryBlue),
                      ),
                      icon: const Icon(
                        Icons.map_rounded,
                        color: AppColors.telemetryBlue,
                        size: 18,
                      ),
                      label: Text(
                        'OPEN LOCATION',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.telemetryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openReportIncident,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hazardRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        'REPORT INCIDENT',
                        style: AppTypography.labelSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.labelMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMediumEmphasis,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
