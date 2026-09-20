import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/incident_model.dart';
import '../../models/inspection_model.dart';
import '../../models/specialist_category.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/minova_logo.dart';
import '../notifications/emergency_detail_screen.dart';
import '../notifications/emergency_notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../records/record_detail_screen.dart';
import '../report/incident/incident_report_screen.dart';

class EmployeeHomeScreen extends ConsumerStatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  ConsumerState<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends ConsumerState<EmployeeHomeScreen> {
  List<IncidentReport> _recentIncidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentIncidents();
  }

  Future<void> _loadRecentIncidents() async {
    final user = ref.read(authStateProvider);
    final incRepo = ref.read(incidentRepositoryProvider);
    final list = await incRepo.getAllIncidents(userId: user?.id);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _recentIncidents = list.take(5).toList();
        _isLoading = false;
      });
    }
  }

  void _triggerSyncNow() async {
    ref.read(syncEngineProvider).processQueue(force: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking network and synchronizing incident logs...'),
        backgroundColor: AppColors.telemetryBlue,
        duration: Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    _loadRecentIncidents();
  }

  void _openReportIncident() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
    );
    _loadRecentIncidents();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final isOnline =
        ref.watch(connectivityStreamProvider).value ??
        ref.watch(connectivityServiceProvider).isOnline;
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;

    final name = user?.fullName.split(' ').first ?? 'Responder';
    final mine = user?.assignedMineName ?? 'Assigned Coal Mine';
    final specialist = SpecialistCategory.fromKey(user?.designation);

    final notifications = ref
        .watch(emergencyNotificationServiceProvider)
        .currentNotifications;
    final topAlert = notifications.isNotEmpty ? notifications.first : null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecentIncidents,
          color: AppColors.hazardRed,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              // 1. Top Brand & Profile Bar
              Row(
                children: [
                  const MinovaLogo(
                    size: 42,
                    layout: MinovaLogoLayout.iconOnly,
                    theme: MinovaLogoTheme.fullColorDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            const MinovaWordmark(
                              fontSize: 18,
                              showTagline: false,
                              color: AppColors.textHighEmphasis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.telemetryBlue.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.telemetryBlue.withAlpha(90),
                                ),
                              ),
                              child: Text(
                                'RESPONDER',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.telemetryBlue,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          mine.isNotEmpty ? mine : 'MINE FIELD TERMINAL',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textMediumEmphasis,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sync Now',
                    onPressed: _triggerSyncNow,
                    icon: const Icon(
                      Icons.sync_rounded,
                      color: AppColors.textMediumEmphasis,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.telemetryBlue,
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1) : 'R',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Greeting & Specialist Badge Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.strokeLowLight, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Field Responder, $name',
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHighEmphasis,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.telemetryBlue.withAlpha(18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.telemetryBlue.withAlpha(70),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  specialist.icon,
                                  size: 13,
                                  color: AppColors.telemetryBlue,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    specialist.displayName,
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.telemetryBlue,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ID: ${user?.employeeId ?? "EMP-FIELD"} • Shift Active',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textMediumEmphasis,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.telemetryBlue.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.telemetryBlue.withAlpha(60),
                        ),
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        color: AppColors.telemetryBlue,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Top Active Emergency Alert Card (if any)
              if (topAlert != null) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.cardLayer1,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.hazardRed.withAlpha(160),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.hazardRed.withAlpha(25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.hazardRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'LATEST EMERGENCY BROADCAST',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.hazardRed,
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const EmergencyNotificationsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Text(
                                'ALL ALERTS',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primaryAmberDark,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topAlert.title,
                        style: AppTypography.headlineSm.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHighEmphasis,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        topAlert.description,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textMediumEmphasis,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
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
                                    topAlert.locationDisplay,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.telemetryBlue,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EmergencyDetailScreen(
                                    notification: topAlert,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.hazardRed,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 1,
                            ),
                            child: const Text(
                              'ACT NOW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 4. Primary Field Action Button (+ REPORT INCIDENT)
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _openReportIncident,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.hazardRed,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 2,
                    shadowColor: AppColors.hazardRed.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+ REPORT INCIDENT',
                              style: AppTypography.labelLg.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Log field hazard, worker injury, fire or roof spalling',
                              style: AppTypography.bodySm.copyWith(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Telemetry & Pending Sync Count
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardLayer1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.strokeLowLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isOnline
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            color: isOnline
                                ? AppColors.complianceGreen
                                : AppColors.hazardRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Network Comms',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  isOnline ? 'Online (Surface Link)' : 'Offline Vault',
                                  style: AppTypography.labelSm.copyWith(
                                    color: isOnline
                                        ? AppColors.complianceGreen
                                        : AppColors.hazardRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardLayer1,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.strokeLowLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pending > 0
                                ? Icons.cloud_upload_outlined
                                : Icons.cloud_done_outlined,
                            color: pending > 0
                                ? AppColors.secondaryOrange
                                : AppColors.complianceGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sync Queue',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  pending > 0 ? '$pending Pending' : 'All Synced',
                                  style: AppTypography.labelSm.copyWith(
                                    color: pending > 0
                                        ? AppColors.secondaryOrange
                                        : AppColors.complianceGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. Recent Incidents Submitted by Employee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'My Recent Incident Reports',
                      style: AppTypography.headlineMd.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _loadRecentIncidents,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      'REFRESH',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primaryAmber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(
                      color: AppColors.hazardRed,
                    ),
                  ),
                )
              else if (_recentIncidents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardLayer1,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.strokeLowLight),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 36,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No incident reports submitted yet',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.textMediumEmphasis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Any dangerous occurrences or injuries reported will appear here.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textDisabled,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._recentIncidents.map(
                  (inc) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardLayer1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.strokeLowLight),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecordDetailScreen(
                              clientUuid: inc.clientUuid,
                              recordType: 'Incident',
                              mineName: inc.mineName,
                              zoneName: inc.zoneName ?? 'Mine Zone',
                              status: inc.status,
                              createdAt: inc.createdAt,
                              summaryDetails: inc.description,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.hazardRed.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.hazardRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          inc.type.displayName,
                                          style: AppTypography.labelMd.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: inc.status == RecordStatus.synced
                                              ? AppColors.complianceGreen.withAlpha(30)
                                              : AppColors.primaryAmber.withAlpha(30),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          inc.status == RecordStatus.synced
                                              ? 'SYNCED'
                                              : 'LOCAL',
                                          style: AppTypography.labelSm.copyWith(
                                            color: inc.status == RecordStatus.synced
                                                ? AppColors.complianceGreen
                                                : AppColors.primaryAmber,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    inc.description,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.textMediumEmphasis,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textDisabled,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
