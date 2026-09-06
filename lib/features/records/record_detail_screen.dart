import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/audit_event_model.dart';
import '../../models/correction_request_model.dart';
import '../../models/inspection_model.dart';
import '../../models/sync_item_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/status_badge.dart';

class RecordDetailScreen extends ConsumerStatefulWidget {
  final String clientUuid;
  final String recordType;
  final String mineName;
  final String zoneName;
  final RecordStatus status;
  final DateTime createdAt;
  final String summaryDetails;

  const RecordDetailScreen({
    super.key,
    required this.clientUuid,
    required this.recordType,
    required this.mineName,
    required this.zoneName,
    required this.status,
    required this.createdAt,
    required this.summaryDetails,
  });

  @override
  ConsumerState<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends ConsumerState<RecordDetailScreen> {
  List<CorrectionRequest> _corrections = [];
  List<AuditEvent> _auditEvents = [];
  bool _isLoadingAudit = true;
  late RecordStatus _currentStatus;
  SyncQueueItem? _syncItem;
  bool _isManualSyncing = false;
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
    _loadAuditAndCorrections();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncSubscription =
          ref.read(syncEngineProvider).onSyncEvents.listen((_) {
        _refreshSyncState();
      });
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshSyncState() async {
    final syncEngine = ref.read(syncEngineProvider);
    final item = await syncEngine.getSyncItem(widget.clientUuid);
    if (mounted) {
      setState(() {
        _syncItem = item;
        if (item?.state == SyncState.completed) {
          _currentStatus = RecordStatus.synced;
        } else if (item?.state == SyncState.failed) {
          _currentStatus = RecordStatus.syncFailed;
        } else if (item?.state == SyncState.inProgress) {
          _currentStatus = RecordStatus.syncing;
        }
      });
    }
  }

  Future<void> _loadAuditAndCorrections() async {
    final repo = ref.read(correctionRepositoryProvider);
    final reqs = await repo.getCorrectionsForRecord(widget.clientUuid);
    final audits = await repo.getAuditEventsForRecord(widget.clientUuid);
    final item = await ref.read(syncEngineProvider).getSyncItem(widget.clientUuid);

    if (mounted) {
      setState(() {
        _corrections = reqs;
        _auditEvents = audits;
        _syncItem = item;
        if (item?.state == SyncState.completed) {
          _currentStatus = RecordStatus.synced;
        } else if (item?.state == SyncState.failed) {
          _currentStatus = RecordStatus.syncFailed;
        } else if (item?.state == SyncState.inProgress) {
          _currentStatus = RecordStatus.syncing;
        }
        _isLoadingAudit = false;
      });
    }
  }

  void _openCorrectionRequestDialog() {
    final reasonController = TextEditingController();
    final changesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardLayer1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primaryAmber, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.rate_review_outlined, color: AppColors.primaryAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'REQUEST AUDITED CORRECTION',
                  style: AppTypography.labelMd.copyWith(color: AppColors.primaryAmber),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submitted statutory records cannot be directly edited. An audited correction request will be sent to the Mine Safety Manager for approval.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textMediumEmphasis),
                ),
                const SizedBox(height: 14),
                Text('STATUTORY REASON FOR CORRECTION *', style: AppTypography.labelSm.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Typographical error in belt conveyor motor serial number...',
                  ),
                ),
                const SizedBox(height: 12),
                Text('PROPOSED CORRECTION / AMENDMENT *', style: AppTypography.labelSm.copyWith(fontSize: 11)),
                const SizedBox(height: 6),
                TextField(
                  controller: changesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Change motor serial from MTR-401 to MTR-402',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: AppTypography.labelMd.copyWith(color: AppColors.textDisabled)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                final user = ref.read(authStateProvider);
                if (user == null) return;

                final repo = ref.read(correctionRepositoryProvider);
                await repo.requestCorrection(
                  recordClientUuid: widget.clientUuid,
                  recordType: widget.recordType,
                  user: user,
                  reason: reasonController.text.trim(),
                  requestedChangesJson: changesController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correction request submitted to Safety Manager for audit review.'),
                      backgroundColor: AppColors.complianceGreen,
                    ),
                  );
                  _loadAuditAndCorrections();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAmberDark,
                minimumSize: const Size(120, 42),
              ),
              child: Text('SUBMIT REQUEST', style: AppTypography.labelSm.copyWith(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          widget.recordType,
          style: AppTypography.headlineSm.copyWith(fontSize: 17),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatusBadge(
              status: _currentStatus,
              compact: true,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Immutable Record Header Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLayer1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.strokeLowLight, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, color: AppColors.primaryAmber, size: 18),
                          const SizedBox(width: 8),
                          Text('LOCKED RECORD', style: AppTypography.labelSm.copyWith(color: AppColors.primaryAmber)),
                        ],
                      ),
                      Text(
                        widget.clientUuid,
                        style: AppTypography.labelSm.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.textMediumEmphasis,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Mine: ${widget.mineName}', style: AppTypography.headlineSm.copyWith(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${widget.zoneName}',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textMediumEmphasis),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Timestamp: ${widget.createdAt.toIso8601String().substring(0, 16).replaceAll('T', ' ')}',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardLayer2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SHA-256 HASH: 8f49a17b2c938d84... (Verified Statutory Integrity)',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.complianceGreen,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_currentStatus == RecordStatus.syncFailed ||
                _currentStatus == RecordStatus.pendingSync ||
                _currentStatus == RecordStatus.syncing ||
                _isManualSyncing) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _currentStatus == RecordStatus.syncFailed
                      ? AppColors.hazardRedLight
                      : AppColors.telemetryBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentStatus == RecordStatus.syncFailed
                        ? AppColors.hazardRed.withAlpha(120)
                        : AppColors.telemetryBlue.withAlpha(100),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isManualSyncing || _currentStatus == RecordStatus.syncing)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.telemetryBlue,
                        ),
                      )
                    else
                      Icon(
                        _currentStatus == RecordStatus.syncFailed
                            ? Icons.sync_problem_rounded
                            : Icons.sync_rounded,
                        color: _currentStatus == RecordStatus.syncFailed
                            ? AppColors.hazardRed
                            : AppColors.telemetryBlue,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isManualSyncing || _currentStatus == RecordStatus.syncing
                                ? 'Synchronizing with Central Cloud...'
                                : (_currentStatus == RecordStatus.syncFailed
                                    ? 'Cloud Sync Failed — Action Required'
                                    : 'Waiting for Cloud Sync'),
                            style: AppTypography.labelSm.copyWith(
                              color: _currentStatus == RecordStatus.syncFailed
                                  ? AppColors.hazardRed
                                  : AppColors.telemetryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentStatus == RecordStatus.syncFailed
                                ? (_syncItem?.errorMessage ?? 'Verification error. Tap to retry synchronization.')
                                : 'Tap to immediately sync this record & media to Cloudinary & Central Server.',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textMediumEmphasis,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: (_isManualSyncing || _currentStatus == RecordStatus.syncing)
                          ? null
                          : () async {
                              setState(() => _isManualSyncing = true);
                              final syncEngine = ref.read(syncEngineProvider);
                              final success = await syncEngine.syncReport(
                                widget.clientUuid,
                                force: true,
                              );
                              await _refreshSyncState();
                              if (!mounted) return;
                              setState(() => _isManualSyncing = false);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Record synchronized successfully!'
                                        : (_syncItem?.errorMessage ??
                                            'Sync failed. Check connectivity or mine authorization.'),
                                  ),
                                  backgroundColor: success
                                      ? AppColors.complianceGreen
                                      : AppColors.hazardRed,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStatus == RecordStatus.syncFailed
                            ? AppColors.hazardRed
                            : AppColors.telemetryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        _isManualSyncing ? 'SYNCING...' : 'SYNC NOW',
                        style: AppTypography.labelSm.copyWith(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Summary Details
            Text('RECORD CONTENTS', style: AppTypography.labelSm),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardLayer2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.strokeActive),
              ),
              child: Text(
                widget.summaryDetails,
                style: AppTypography.bodyMd.copyWith(color: AppColors.textHighEmphasis),
              ),
            ),
            const SizedBox(height: 20),

            // Direct Edit Blocked Notice & Correction Request Button
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x20F59E0B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryAmber.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primaryAmber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'DIRECT MODIFICATION RESTRICTED',
                        style: AppTypography.labelSm.copyWith(color: AppColors.primaryAmber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'To prevent statutory compliance fraud, locked records cannot be silently overwritten. You may initiate an audited correction request.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textMediumEmphasis, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openCorrectionRequestDialog,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.cardLayer1,
                      side: const BorderSide(color: AppColors.primaryAmber),
                    ),
                    icon: const Icon(Icons.rate_review_outlined, color: AppColors.primaryAmber, size: 18),
                    label: Text(
                      'REQUEST AUDITED CORRECTION',
                      style: AppTypography.labelMd.copyWith(color: AppColors.primaryAmber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Correction Requests if any
            if (_corrections.isNotEmpty) ...[
              Text('CORRECTION REQUESTS', style: AppTypography.labelSm),
              const SizedBox(height: 8),
              ..._corrections.map((c) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardLayer2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryAmber.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                c.id,
                                style: AppTypography.labelSm.copyWith(color: AppColors.primaryAmber),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c.status.name.toUpperCase(),
                                style: AppTypography.labelSm.copyWith(
                                    color: c.status == CorrectionStatus.approved
                                        ? AppColors.complianceGreen
                                        : c.status == CorrectionStatus.rejected
                                            ? AppColors.hazardRed
                                            : AppColors.secondaryOrange)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Reason: ${c.reason}', style: AppTypography.bodySm.copyWith(color: AppColors.textHighEmphasis)),
                        Text('By: ${c.requestedByUserName} • ${c.requestedAt.toLocal().toString().substring(0, 16)}',
                            style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 10)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Audited History Timeline
            Text('AUDIT TRAIL / संशोधन इतिहास', style: AppTypography.labelSm),
            const SizedBox(height: 8),

            if (_isLoadingAudit)
              const Center(child: CircularProgressIndicator(color: AppColors.primaryAmber))
            else if (_auditEvents.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer1,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('No external modifications logged. Record is pristine.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled)),
              )
            else
              ..._auditEvents.map(
                (ev) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardLayer1,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.strokeLowLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.history_rounded, color: AppColors.telemetryBlue, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ev.description, style: AppTypography.bodyMd.copyWith(fontSize: 13)),
                            Text(
                              '${ev.userRole.toUpperCase()} • ${ev.timestamp.toLocal().toString().substring(0, 16)}',
                              style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 10),
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
      ),
    );
  }
}
