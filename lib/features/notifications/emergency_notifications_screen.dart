import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/emergency_notification_model.dart';
import '../../models/inspection_model.dart';
import '../../models/specialist_category.dart';
import '../../shared/providers/app_providers.dart';
import 'emergency_detail_screen.dart';

class EmergencyNotificationsScreen extends ConsumerStatefulWidget {
  const EmergencyNotificationsScreen({super.key});

  @override
  ConsumerState<EmergencyNotificationsScreen> createState() =>
      _EmergencyNotificationsScreenState();
}

class _EmergencyNotificationsScreenState
    extends ConsumerState<EmergencyNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final notificationsAsync =
        ref.watch(emergencyNotificationsStreamProvider);
    final currentList = ref
        .watch(emergencyNotificationServiceProvider)
        .currentNotifications;

    final notifications = notificationsAsync.value ?? currentList;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.cardLayer2,
        title: Row(
          children: [
            const Icon(
              Icons.campaign_rounded,
              color: AppColors.hazardRed,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Emergency Alerts Feed',
              style: AppTypography.headlineSm.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.hazardRed,
          onRefresh: () async {
            await ref
                .read(emergencyNotificationServiceProvider)
                .initialize();
          },
          child: notifications.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 60),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardLayer1,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.strokeLowLight),
                        ),
                        child: const Icon(
                          Icons.notifications_off_outlined,
                          size: 44,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Emergency Broadcasts',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineSm.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mine safety telemetry and dispatcher channels are all normal.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final isUserSpecialist = user?.designation != null &&
                        item.targetSpecialist != 'all' &&
                        user!.designation
                            .toLowerCase()
                            .contains(item.targetSpecialist.toLowerCase());

                    return _EmergencyCard(
                      notification: item,
                      isSpecialistMatch: isUserSpecialist,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EmergencyDetailScreen(
                              notification: item,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({
    required this.notification,
    required this.isSpecialistMatch,
    required this.onTap,
  });

  final EmergencyNotificationModel notification;
  final bool isSpecialistMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCritical = notification.severity == ViolationSeverity.critical;
    final color = isCritical ? AppColors.hazardRed : AppColors.secondaryOrange;

    final timeStr = DateFormat('dd MMM, hh:mm a').format(notification.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardLayer1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSpecialistMatch
              ? AppColors.primaryAmberDark.withAlpha(180)
              : (notification.isRead
                  ? AppColors.strokeLowLight
                  : color.withAlpha(140)),
          width: isSpecialistMatch || !notification.isRead ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSpecialistMatch ? AppColors.primaryAmber : color).withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Priority & Type & Timestamp
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: color.withAlpha(80)),
                      ),
                      child: Text(
                        notification.severity.name.toUpperCase(),
                        style: AppTypography.labelSm.copyWith(
                          color: color,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isSpecialistMatch) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAmber.withAlpha(20),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primaryAmberDark.withAlpha(90),
                          ),
                        ),
                        child: Text(
                          'YOUR SPECIALTY',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primaryAmberDark,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        timeStr,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    if (!notification.isRead) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  notification.title,
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHighEmphasis,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  notification.description,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMediumEmphasis,
                    fontSize: 12,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Location Pill & View Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.telemetryBlue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              notification.locationDisplay,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.telemetryBlue,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VIEW DETAILS',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primaryAmber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primaryAmber,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
