import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/document_model.dart';
import '../../models/incident_model.dart';
import '../../models/inspection_model.dart';
import '../../models/observation_model.dart';
import '../../shared/providers/app_providers.dart';
import '../profile/profile_screen.dart';
import '../records/record_detail_screen.dart';
import '../report/attendance/attendance_screen.dart';
import '../report/document/document_upload_screen.dart';
import '../report/incident/incident_report_screen.dart';
import '../report/observation/observation_screen.dart';
import '../report/report_hub_screen.dart';
import '../../shared/widgets/minova_logo.dart';

class _UnifiedDashboardRecord {
  final String clientUuid;
  final String title;
  final String hindiSubtitle;
  final String recordType;
  final String mineName;
  final String zoneName;
  final RecordStatus status;
  final DateTime createdAt;
  final IconData icon;
  final Color color;
  final String summary;

  _UnifiedDashboardRecord({
    required this.clientUuid,
    required this.title,
    required this.hindiSubtitle,
    required this.recordType,
    required this.mineName,
    required this.zoneName,
    required this.status,
    required this.createdAt,
    required this.icon,
    required this.color,
    required this.summary,
  });
}

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  List<_UnifiedDashboardRecord> _recentRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRecentRecords();
  }

  Future<void> _loadAllRecentRecords() async {
    final inspRepo = ref.read(inspectionRepositoryProvider);
    final incRepo = ref.read(incidentRepositoryProvider);
    final attRepo = ref.read(attendanceRepositoryProvider);
    final obsRepo = ref.read(observationRepositoryProvider);
    final docRepo = ref.read(documentRepositoryProvider);

    final user = ref.read(authStateProvider);
    final userId = user?.id;

    final insps = await inspRepo.getAllReports(userId: userId);
    final incs = await incRepo.getAllIncidents(userId: userId);
    final atts = await attRepo.getAllAttendances(userId: userId);
    final obss = await obsRepo.getAllObservations(userId: userId);
    final docs = await docRepo.getAllDocuments(userId: userId);

    final List<_UnifiedDashboardRecord> unified = [];

    for (final r in insps) {
      unified.add(
        _UnifiedDashboardRecord(
          clientUuid: r.clientUuid,
          title: r.type.displayName,
          hindiSubtitle: 'दैनिक सुरक्षा निरीक्षण',
          recordType: 'Inspection',
          mineName: r.mineName,
          zoneName: r.zoneName ?? 'Underground Zone',
          status: r.status,
          createdAt: r.createdAt,
          icon: Icons.assignment_turned_in_outlined,
          color: AppColors.primaryAmberDark,
          summary: '${r.checklist.length} safety items inspected',
        ),
      );
    }

    for (final r in incs) {
      unified.add(
        _UnifiedDashboardRecord(
          clientUuid: r.clientUuid,
          title: 'Incident: ${r.type.displayName}',
          hindiSubtitle: 'आपातकालीन घटना रिपोर्ट',
          recordType: 'Incident',
          mineName: r.mineName,
          zoneName: r.zoneName ?? 'Underground Zone',
          status: r.status,
          createdAt: r.createdAt,
          icon: Icons.warning_amber_rounded,
          color: AppColors.hazardRed,
          summary: r.description,
        ),
      );
    }

    for (final r in atts) {
      unified.add(
        _UnifiedDashboardRecord(
          clientUuid: r.clientUuid,
          title: 'Muster: ${r.shiftName.split(' ').first}',
          hindiSubtitle: 'शिफ्ट मस्टर रोल',
          recordType: 'Attendance',
          mineName: r.mineName,
          zoneName: r.musterLocation,
          status: r.status,
          createdAt: r.createdAt,
          icon: Icons.people_alt_outlined,
          color: AppColors.telemetryBlue,
          summary: '${r.actualHeadcount} of ${r.expectedHeadcount} Present',
        ),
      );
    }

    for (final r in obss) {
      unified.add(
        _UnifiedDashboardRecord(
          clientUuid: r.clientUuid,
          title: 'Field Log: ${r.category.displayName}',
          hindiSubtitle: 'फील्ड अवलोकन व गैस लॉग',
          recordType: 'Observation',
          mineName: r.mineName,
          zoneName: r.zoneName ?? 'Underground Zone',
          status: r.status,
          createdAt: r.createdAt,
          icon: Icons.sensors_rounded,
          color: AppColors.secondaryOrange,
          summary: r.description,
        ),
      );
    }

    for (final r in docs) {
      unified.add(
        _UnifiedDashboardRecord(
          clientUuid: r.clientUuid,
          title: r.title,
          hindiSubtitle: 'वैधानिक प्रमाण पत्र',
          recordType: 'Document',
          mineName: r.mineName,
          zoneName: r.associatedContractor ?? 'Statutory Vault',
          status: r.status,
          createdAt: r.createdAt,
          icon: Icons.verified_user_outlined,
          color: AppColors.complianceGreen,
          summary: r.documentNumber != null && r.documentNumber!.isNotEmpty
              ? 'Cert #: ${r.documentNumber}'
              : '${r.category.displayName} (${r.files.length} attached file)',
        ),
      );
    }

    unified.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _recentRecords = unified.take(4).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _startReportHub() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReportHubScreen()));
    _loadAllRecentRecords();
  }

  void _triggerSyncNow() async {
    ref.read(syncEngineProvider).processQueue(force: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking subterranean connection and processing sync queue...'),
        backgroundColor: AppColors.telemetryBlue,
        duration: Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    _loadAllRecentRecords();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final isOnline =
        ref.watch(connectivityStreamProvider).value ??
        ref.watch(connectivityServiceProvider).isOnline;
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    final name = user?.fullName.split(' ').first ?? 'Inspector';
    final mine = user?.assignedMineName ?? 'BCCL Pit-7 (JH-DHA-007)';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllRecentRecords,
          color: AppColors.primaryAmberDark,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              // 1. Top Brand & Profile Bar
              Row(
                children: [
                  const MinovaLogo(
                    size: 44,
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
                          spacing: 8,
                          children: [
                            const MinovaWordmark(
                              fontSize: 19,
                              showTagline: false,
                              color: AppColors.textHighEmphasis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.telemetryCyan.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: AppColors.telemetryCyan.withAlpha(80),
                                ),
                              ),
                              child: Text(
                                'DGMS SAFE',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.telemetryCyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          mine.isNotEmpty
                              ? '$mine • SAFER MINES'
                              : 'TECHNOLOGY FOR SAFER MINES',
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
                    icon: const Icon(Icons.sync_rounded, color: AppColors.textMediumEmphasis),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryAmberDark,
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1) : 'I',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Greeting & Shift Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer1,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.strokeLowLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, $name',
                            style: AppTypography.headlineLg.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.designation ?? 'Statutory Safety Inspector',
                            style: AppTypography.bodySm.copyWith(color: AppColors.primaryAmber),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textDisabled),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Shift A (06:00 - 14:00) • Seam 3 Face',
                                  style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardLayer2,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.strokeActive),
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        color: AppColors.primaryAmber,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Status & Telemetry Indicators Row
              Row(
                children: [
                  Expanded(
                    child: _StatusRow(
                      icon: isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      label: 'Network Comms',
                      value: isOnline ? 'Online (Surface/Wi-Fi)' : 'Offline (Local Vault)',
                      color: isOnline ? AppColors.complianceGreen : AppColors.hazardRed,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatusRow(
                      icon: Icons.terrain_rounded,
                      label: 'Subterranean Lock',
                      value: 'Zone: Gallery 4 Active',
                      color: AppColors.telemetryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Primary Central Action Button (+ START REPORT)
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _startReportHub,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAmberDark,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                        child: const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+ START REPORT',
                              style: AppTypography.labelLg.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Create statutory inspection, incident or muster log',
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
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Quick Shortcut Grid (1-Tap Fast Actions)
              Row(
                children: [
                  _QuickActionTile(
                    icon: Icons.warning_amber_rounded,
                    label: 'Emergency',
                    sub: 'Incident',
                    color: AppColors.hazardRed,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
                      );
                      _loadAllRecentRecords();
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickActionTile(
                    icon: Icons.people_alt_outlined,
                    label: 'Muster',
                    sub: 'Form-D',
                    color: AppColors.telemetryBlue,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                      );
                      _loadAllRecentRecords();
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickActionTile(
                    icon: Icons.sensors_rounded,
                    label: 'Gas & Obs',
                    sub: 'CH4/CO Log',
                    color: AppColors.secondaryOrange,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ObservationScreen()),
                      );
                      _loadAllRecentRecords();
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickActionTile(
                    icon: Icons.document_scanner_outlined,
                    label: 'Doc Vault',
                    sub: 'FLP Cert',
                    color: AppColors.complianceGreen,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DocumentUploadScreen()),
                      );
                      _loadAllRecentRecords();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Metrics & Pending Sync Bar
              Row(
                children: [
                  Expanded(
                    child: _CountBlock(
                      label: "Today's Logs / आज",
                      value: '${_recentRecords.length}',
                      icon: Icons.done_all_rounded,
                      color: AppColors.primaryAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CountBlock(
                      label: 'Queue for Sync / सिंक',
                      value: '$pending',
                      icon: pending > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                      color: pending > 0 ? AppColors.secondaryOrange : AppColors.complianceGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 7. Recent Statutory Activity Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Recent Statutory Activity',
                      style: AppTypography.headlineMd.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _loadAllRecentRecords,
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(
                      'REFRESH',
                      style: AppTypography.labelSm.copyWith(color: AppColors.primaryAmber),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primaryAmber),
                  ),
                )
              else if (_recentRecords.isEmpty)
                const _EmptyReports()
              else
                ..._recentRecords.map(
                  (record) => _UnifiedReportRow(
                    record: record,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecordDetailScreen(
                          clientUuid: record.clientUuid,
                          recordType: record.recordType,
                          mineName: record.mineName,
                          zoneName: record.zoneName,
                          status: record.status,
                          createdAt: record.createdAt,
                          summaryDetails: record.summary,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // 8. Offline & Cryptographic Notice
              if (!isOnline)
                const _OfflineNotice()
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.complianceGreenLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.complianceGreen.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined, color: AppColors.complianceGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cloud link verified. Unsigned telemetry & SHA-256 statutory hashes synchronize seamlessly.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.complianceGreen, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.cardLayer1,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.strokeLowLight),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 10),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: AppTypography.labelSm.copyWith(color: color, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.cardLayer1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.strokeLowLight),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sub,
              style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}

class _CountBlock extends StatelessWidget {
  const _CountBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.cardLayer1,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.strokeLowLight),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(value, style: AppTypography.displayLg.copyWith(fontSize: 22)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, color: color, size: 24),
      ],
    ),
  );
}

class _UnifiedReportRow extends StatelessWidget {
  const _UnifiedReportRow({
    required this.record,
    required this.onTap,
  });

  final _UnifiedDashboardRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppColors.cardLayer1,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.strokeLowLight),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: record.color.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(record.icon, color: record.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: AppTypography.labelMd.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${record.zoneName} • ${record.summary}',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: record.status == RecordStatus.synced
                    ? AppColors.complianceGreenLight
                    : AppColors.cardLayer2,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: record.status == RecordStatus.synced
                      ? AppColors.complianceGreen.withAlpha(100)
                      : AppColors.strokeActive,
                ),
              ),
              child: Text(
                record.status == RecordStatus.synced ? 'SYNCED' : 'WAITING',
                style: AppTypography.labelSm.copyWith(
                  color: record.status == RecordStatus.synced
                      ? AppColors.complianceGreen
                      : AppColors.textDisabled,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardLayer1,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.strokeLowLight),
    ),
    child: Center(
      child: Column(
        children: [
          const Icon(Icons.assignment_late_outlined, color: AppColors.textDisabled, size: 36),
          const SizedBox(height: 8),
          Text(
            'No statutory reports recorded yet',
            style: AppTypography.bodyMd.copyWith(color: AppColors.textMediumEmphasis),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "+ START REPORT" to log your first statutory safety audit',
            style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardLayer2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.strokeLowLight),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.secondaryOrange, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subterranean Offline Mode Active',
                style: AppTypography.labelSm.copyWith(color: AppColors.secondaryOrange),
              ),
              Text(
                'All logs are securely saved with local SHA-256 cryptographic hashes and will automatically sync once Wi-Fi or mobile network connects.',
                style: AppTypography.bodySm.copyWith(color: AppColors.textMediumEmphasis, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
