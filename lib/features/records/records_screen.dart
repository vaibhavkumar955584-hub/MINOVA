import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/language_controller.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/attendance_model.dart';
import '../../models/document_model.dart';
import '../../models/incident_model.dart';
import '../../models/inspection_model.dart';
import '../../models/observation_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/minova_logo.dart';
import 'record_detail_screen.dart';

enum RecordsFilterTab { all, waiting, sent }

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  RecordsFilterTab _activeTab = RecordsFilterTab.waiting;
  List<InspectionReport> _inspections = [];
  List<IncidentReport> _incidents = [];
  List<AttendanceReport> _attendances = [];
  List<ObservationRecord> _observations = [];
  List<ComplianceDocument> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRecords();
  }

  Future<void> _loadAllRecords() async {
    setState(() => _isLoading = true);

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

    if (mounted) {
      setState(() {
        _inspections = insps;
        _incidents = incs;
        _attendances = atts;
        _observations = obss;
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  void _triggerSyncNow() async {
    ref.read(syncEngineProvider).processQueue();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.checkingConnection),
        duration: Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    _loadAllRecords();
  }

  int get _waitingCount {
    final pendingInsps = _inspections
        .where(
          (r) =>
              r.status == RecordStatus.pendingSync ||
              r.status == RecordStatus.syncFailed ||
              r.status == RecordStatus.syncing,
        )
        .length;
    final pendingIncs = _incidents
        .where(
          (r) =>
              r.status == RecordStatus.pendingSync ||
              r.status == RecordStatus.syncFailed ||
              r.status == RecordStatus.syncing,
        )
        .length;
    final pendingAtts = _attendances
        .where(
          (r) =>
              r.status == RecordStatus.pendingSync ||
              r.status == RecordStatus.syncFailed ||
              r.status == RecordStatus.syncing,
        )
        .length;
    final pendingObss = _observations
        .where(
          (r) =>
              r.status == RecordStatus.pendingSync ||
              r.status == RecordStatus.syncFailed ||
              r.status == RecordStatus.syncing,
        )
        .length;
    final pendingDocs = _documents
        .where(
          (r) =>
              r.status == RecordStatus.pendingSync ||
              r.status == RecordStatus.syncFailed ||
              r.status == RecordStatus.syncing,
        )
        .length;
    final total = pendingInsps + pendingIncs + pendingAtts + pendingObss + pendingDocs;
    return total;
  }

  int get _allCount =>
      _inspections.length +
      _incidents.length +
      _attendances.length +
      _observations.length +
      _documents.length;
  int get _sentCount => _allCount - _waitingCount;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final mineName = (user?.assignedMineName.isNotEmpty == true)
        ? '${user!.assignedMineName} (${user.assignedMineId})'
        : (user?.assignedMineId.isNotEmpty == true ? user!.assignedMineId : 'Assigned Mine');
    final language = ref.watch(languageControllerProvider).language;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllRecords,
          color: AppColors.primaryAmber,
          backgroundColor: AppColors.cardLayer2,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  children: [
                    const MinovaLogo(
                      size: 40,
                      layout: MinovaLogoLayout.iconOnly,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MinovaWordmark(
                            fontSize: 18,
                            showTagline: false,
                            color: AppColors.textHighEmphasis,
                          ),
                          Text(
                            mineName,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textMediumEmphasis,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardLayer1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryAmber.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.language_rounded,
                            size: 13,
                            color: AppColors.primaryAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            language.nativeName,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primaryAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryAmberDark,
                            AppColors.secondaryOrange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAmberDark.withAlpha(40),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pending Internet Banner (Sleek, Compact Industrial Telemetry)
                if (_waitingCount > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryAmberDark.withAlpha(35),
                          AppColors.cardLayer1,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryAmber.withAlpha(120),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAmberDark.withAlpha(50),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryAmber.withAlpha(160),
                                ),
                              ),
                              child: const Icon(
                                Icons.cloud_off_rounded,
                                color: AppColors.primaryAmber,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.waitingReports(_waitingCount),
                                    style: AppTypography.labelLg.copyWith(
                                      color: AppColors.textHighEmphasis,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Offline safe • Encrypted in local database',
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.textMediumEmphasis,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _triggerSyncNow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAmberDark,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.sync_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              label: Text(
                                context.l10n.tryAgain,
                                style: AppTypography.labelSm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Filter Tabs (Sleek Modern Segmented Control)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardLayer1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.strokeLowLight),
                  ),
                  child: Row(
                    children: [
                      _buildFilterTab(
                        tab: RecordsFilterTab.all,
                        icon: Icons.folder_outlined,
                        label: 'All ($_allCount)',
                      ),
                      _buildFilterTab(
                        tab: RecordsFilterTab.waiting,
                        icon: Icons.sync_problem_rounded,
                        label: 'Waiting ($_waitingCount)',
                        badgeColor: _waitingCount > 0
                            ? AppColors.primaryAmber
                            : null,
                      ),
                      _buildFilterTab(
                        tab: RecordsFilterTab.sent,
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Synced ($_sentCount)',
                        badgeColor: AppColors.complianceGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Record Cards List
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAmber,
                      ),
                    ),
                  )
                else
                  ..._renderRecordCards(),

                const SizedBox(height: 14),

                // Bottom Statutory Legal Recognition Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.complianceGreenLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.complianceGreen.withAlpha(90),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.complianceGreen.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.complianceGreen,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUTORY COMPLIANCE SEALED',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.complianceGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'All offline records carry tamper-evident SHA-256 hashes under Mines Act.',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.textMediumEmphasis,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required RecordsFilterTab tab,
    required IconData icon,
    required String label,
    Color? badgeColor,
  }) {
    final isSelected = _activeTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryAmberDark
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryAmberDark.withAlpha(60),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (badgeColor ?? AppColors.textDisabled),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSm.copyWith(
                    color: isSelected
                        ? Colors.white
                        : AppColors.textMediumEmphasis,
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _renderRecordCards() {
    final allCards = <({DateTime date, RecordStatus status, Widget widget})>[];

    for (final insp in _inspections) {
      allCards.add((
        date: insp.createdAt,
        status: insp.status,
        widget: _buildInspectionCard(insp),
      ));
    }
    for (final inc in _incidents) {
      allCards.add((
        date: inc.createdAt,
        status: inc.status,
        widget: _buildIncidentCard(inc),
      ));
    }
    for (final att in _attendances) {
      allCards.add((
        date: att.createdAt,
        status: att.status,
        widget: _buildAttendanceCard(att),
      ));
    }
    for (final obs in _observations) {
      allCards.add((
        date: obs.createdAt,
        status: obs.status,
        widget: _buildObservationCard(obs),
      ));
    }
    for (final doc in _documents) {
      allCards.add((
        date: doc.createdAt,
        status: doc.status,
        widget: _buildDocumentCard(doc),
      ));
    }

    allCards.sort((a, b) => b.date.compareTo(a.date));

    final filtered = allCards.where((item) {
      if (_activeTab == RecordsFilterTab.waiting) {
        return item.status == RecordStatus.pendingSync ||
            item.status == RecordStatus.syncFailed ||
            item.status == RecordStatus.syncing;
      }
      if (_activeTab == RecordsFilterTab.sent) {
        return item.status == RecordStatus.synced ||
            item.status == RecordStatus.underReview ||
            item.status == RecordStatus.resolved;
      }
      return true;
    }).toList();

    if (allCards.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardLayer1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.strokeLowLight),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: 40,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 10),
              Text(
                'No reports saved on this phone yet.',
                style: AppTypography.bodyLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.add),
                label: const Text('Start a report'),
              ),
            ],
          ),
        ),
      ];
    }

    if (filtered.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardLayer1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.strokeLowLight),
          ),
          child: Center(
            child: Text(
              'No records match this filter tab.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.textDisabled),
            ),
          ),
        ),
      ];
    }

    return filtered.map((item) => item.widget).toList();
  }

  Widget _buildInspectionCard(InspectionReport report) {
    final waiting = report.status != RecordStatus.synced;
    final failed = report.checklist
        .where((item) => item.status == CheckItemStatus.fail)
        .length;
    final tag = report.clientUuid.length > 8
        ? '#${report.clientUuid.substring(report.clientUuid.length - 8)}'
        : '#${report.clientUuid}';

    return _buildCardContainer(
      badgeText: waiting ? 'Waiting for internet' : 'Successfully sent',
      badgeColor: waiting
          ? AppColors.primaryAmberDark
          : AppColors.complianceGreen,
      badgeBg: waiting ? const Color(0x25B86A00) : const Color(0x2510B981),
      badgeIcon: waiting
          ? Icons.sync_problem_rounded
          : Icons.check_circle_outline_rounded,
      idTag: tag,
      title: report.type.displayName,
      locationTime:
          '${report.zoneName ?? 'Mine zone'} • ${_formatReportTime(report.createdAt)}',
      contentChild: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardLayer2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              failed == 0
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              color: failed == 0
                  ? AppColors.complianceGreen
                  : AppColors.hazardRed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                failed == 0
                    ? 'All checklist items compliant'
                    : '$failed safety issue${failed == 1 ? '' : 's'} recorded',
                style: AppTypography.labelMd,
              ),
            ),
          ],
        ),
      ),
      onView: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecordDetailScreen(
            clientUuid: report.clientUuid,
            recordType: report.type.displayName,
            mineName: report.mineName,
            zoneName: report.zoneName ?? 'Mine zone',
            status: report.status,
            createdAt: report.createdAt,
            summaryDetails: failed == 0
                ? 'All checklist items marked compliant according to DGMS standards.'
                : '$failed issue(s) recorded for review and corrective orders.',
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentCard(IncidentReport report) {
    final waiting = report.status != RecordStatus.synced;
    final tag = report.clientUuid.length > 8
        ? '#${report.clientUuid.substring(report.clientUuid.length - 8)}'
        : '#${report.clientUuid}';

    return _buildCardContainer(
      badgeText: waiting ? 'Waiting for internet' : 'Successfully sent',
      badgeColor: waiting ? AppColors.hazardRed : AppColors.complianceGreen,
      badgeBg: waiting ? const Color(0x25EF4444) : const Color(0x2510B981),
      badgeIcon: waiting ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
      idTag: tag,
      title: 'Emergency: ${report.type.displayName}',
      locationTime: '${report.zoneName} • ${_formatReportTime(report.createdAt)}',
      contentChild: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardLayer2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.hazardRed, size: 16),
                const SizedBox(width: 6),
                Text(
                  'SEVERITY: ${report.severity.name.toUpperCase()}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.hazardRed,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(color: AppColors.textHighEmphasis),
            ),
          ],
        ),
      ),
      onView: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecordDetailScreen(
            clientUuid: report.clientUuid,
            recordType: 'Emergency Incident',
            mineName: report.mineName,
            zoneName: report.zoneName ?? 'Mine zone',
            status: report.status,
            createdAt: report.createdAt,
            summaryDetails:
                'Incident Type: ${report.type.displayName}\nSeverity: ${report.severity.name.toUpperCase()}\nPeople Affected: ${report.peopleAffected}\nMedical Attention: ${report.medicalAttentionRequired ? 'Yes' : 'No'}\n\nDescription:\n${report.description}\n\nImmediate Action Taken:\n${report.immediateActionTaken}',
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceReport report) {
    final waiting = report.status != RecordStatus.synced;
    final tag = report.clientUuid.length > 8
        ? '#${report.clientUuid.substring(report.clientUuid.length - 8)}'
        : '#${report.clientUuid}';

    final cleanTitle = report.shiftName.toLowerCase().contains('muster')
        ? report.shiftName
        : '${report.shiftName} • Muster Roll';

    return _buildCardContainer(
      badgeText: waiting ? 'Waiting for internet' : 'Successfully sent',
      badgeColor: waiting ? AppColors.primaryAmberDark : AppColors.complianceGreen,
      badgeBg: waiting ? const Color(0x25B86A00) : const Color(0x2510B981),
      badgeIcon: waiting ? Icons.sync_problem_rounded : Icons.check_circle_outline_rounded,
      idTag: tag,
      title: cleanTitle,
      locationTime: '${report.musterLocation} • ${_formatReportTime(report.createdAt)}',
      contentChild: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardLayer2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardLayer1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.strokeLowLight),
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: AppColors.primaryAmber,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MUSTER ROLL',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${report.actualHeadcount} of ${report.expectedHeadcount} Present',
                    style: AppTypography.headlineSm.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.complianceGreenLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.complianceGreen.withAlpha(80),
                ),
              ),
              child: Text(
                'Shift Complete',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.complianceGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      onView: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecordDetailScreen(
            clientUuid: report.clientUuid,
            recordType: 'Shift Attendance',
            mineName: report.mineName,
            zoneName: report.musterLocation,
            status: report.status,
            createdAt: report.createdAt,
            summaryDetails:
                'Shift: ${report.shiftName}\nLocation: ${report.musterLocation}\nHeadcount: ${report.actualHeadcount} Present of ${report.expectedHeadcount} Expected\nEntries: ${report.entries.length} workers recorded',
          ),
        ),
      ),
    );
  }

  Widget _buildObservationCard(ObservationRecord report) {
    final waiting = report.status != RecordStatus.synced;
    final isGrievance = report.entryType == ObservationType.grievance;
    final tag = report.clientUuid.length > 8
        ? '#${report.clientUuid.substring(report.clientUuid.length - 8)}'
        : '#${report.clientUuid}';

    return _buildCardContainer(
      badgeText: waiting ? 'Waiting for internet' : 'Successfully sent',
      badgeColor: waiting ? AppColors.primaryAmberDark : AppColors.complianceGreen,
      badgeBg: waiting ? const Color(0x25B86A00) : const Color(0x2510B981),
      badgeIcon: waiting ? Icons.sync_problem_rounded : Icons.check_circle_outline_rounded,
      idTag: tag,
      title: isGrievance ? 'Worker Grievance' : 'Field Log: ${report.category.displayName}',
      locationTime: '${report.zoneName ?? 'Mine zone'} • ${_formatReportTime(report.createdAt)}',
      contentChild: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardLayer2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (report.ch4Percent != null || report.coPpm != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.complianceGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'CH4: ${report.ch4Percent ?? 0}% • CO: ${report.coPpm ?? 0} PPM',
                        style: AppTypography.labelMd.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                  Text(
                    'TELEMETRY',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.complianceGreen,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(color: AppColors.textHighEmphasis),
            ),
          ],
        ),
      ),
      onView: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecordDetailScreen(
            clientUuid: report.clientUuid,
            recordType: isGrievance ? 'Worker Grievance' : 'Field Observation',
            mineName: report.mineName,
            zoneName: report.zoneName ?? 'Mine zone',
            status: report.status,
            createdAt: report.createdAt,
            summaryDetails:
                'Type: ${isGrievance ? 'Grievance' : 'Observation'}\nCategory: ${report.category.displayName}\n\nDescription:\n${report.description}${report.ch4Percent != null ? '\n\nGas Telemetry:\n• CH4: ${report.ch4Percent}%\n• CO: ${report.coPpm} PPM\n• O2: ${report.o2Percent}%' : ''}',
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(ComplianceDocument doc) {
    final waiting = doc.status != RecordStatus.synced;
    final tag = doc.clientUuid.length > 8
        ? '#${doc.clientUuid.substring(doc.clientUuid.length - 8)}'
        : '#${doc.clientUuid}';

    final validityText = doc.expiryDate != null
        ? 'Valid until: ${_formatReportTime(doc.expiryDate!)}'
        : 'Statutory compliance record';

    return _buildCardContainer(
      badgeText: waiting ? 'Waiting for internet' : 'Successfully sent',
      badgeColor: waiting
          ? AppColors.primaryAmberDark
          : AppColors.complianceGreen,
      badgeBg: waiting ? const Color(0x25B86A00) : const Color(0x2510B981),
      badgeIcon: waiting
          ? Icons.sync_problem_rounded
          : Icons.check_circle_outline_rounded,
      idTag: tag,
      title: doc.title,
      locationTime:
          '${doc.associatedContractor ?? doc.mineName} • ${_formatReportTime(doc.createdAt)}',
      contentChild: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardLayer2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.complianceGreen,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.documentNumber != null && doc.documentNumber!.isNotEmpty
                        ? 'Cert #: ${doc.documentNumber}'
                        : doc.category.displayName,
                    style: AppTypography.labelMd,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    validityText,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textMediumEmphasis,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onView: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecordDetailScreen(
            clientUuid: doc.clientUuid,
            recordType: 'Statutory Document',
            mineName: doc.mineName,
            zoneName: doc.associatedContractor ?? 'Statutory Vault',
            status: doc.status,
            createdAt: doc.createdAt,
            summaryDetails:
                'Document Title: ${doc.title}\nCategory: ${doc.category.displayName}\nCertificate Number: ${doc.documentNumber ?? "N/A"}\nContractor / Entity: ${doc.associatedContractor ?? "N/A"}\nIssue Date: ${doc.issueDate != null ? "${doc.issueDate!.day.toString().padLeft(2, '0')}/${doc.issueDate!.month.toString().padLeft(2, '0')}/${doc.issueDate!.year}" : "N/A"}\nExpiry Date: ${doc.expiryDate != null ? "${doc.expiryDate!.day.toString().padLeft(2, '0')}/${doc.expiryDate!.month.toString().padLeft(2, '0')}/${doc.expiryDate!.year}" : "N/A"}\nRemarks: ${doc.remarks ?? "None"}\nAttached Files: ${doc.files.length} file(s)',
          ),
        ),
      ),
    );
  }

  String _formatReportTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Widget _buildCardContainer({
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required IconData badgeIcon,
    required String idTag,
    required String title,
    required String locationTime,
    required Widget contentChild,
    required VoidCallback onView,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardLayer1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.strokeLowLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: badgeColor.withAlpha(90),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: AppTypography.labelSm.copyWith(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer2,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  idTag,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.textMediumEmphasis,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.headlineSm.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textHighEmphasis,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.textDisabled,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  locationTime,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMediumEmphasis,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          contentChild,
          const SizedBox(height: 12),

          // High-Contrast Sleek View Report Action
          InkWell(
            onTap: onView,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryAmberDark.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryAmberDark.withAlpha(100),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.primaryAmberDark,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'VIEW AUDITED REPORT',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primaryAmberDark,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryAmberDark,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
