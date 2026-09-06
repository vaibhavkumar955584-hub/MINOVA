import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/localization_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/attendance_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/large_touch_card.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  String _selectedShift = 'morning';
  final String _musterLocation = 'Pit-4 Main Shaft Muster Gate';
  late List<WorkerAttendanceEntry> _roster;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _roster = AttendanceReport.getRosterForShift(_selectedShift);
  }

  int get _presentCount => _roster.where((w) => w.isPresent).length;

  List<String> get _categories {
    final set = {'All'};
    for (final w in _roster) {
      set.add(w.category);
    }
    return set.toList();
  }

  List<WorkerAttendanceEntry> get _filteredRoster {
    return _roster.where((worker) {
      final matchesSearch = _searchQuery.isEmpty ||
          worker.workerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          worker.workerId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          worker.contractorName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' || worker.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  void _markAll(bool present) {
    setState(() {
      _roster = _roster.map((w) {
        return WorkerAttendanceEntry(
          workerId: w.workerId,
          workerName: w.workerName,
          category: w.category,
          contractorName: w.contractorName,
          isPresent: present,
          checkInTime: w.checkInTime,
          checkOutTime: w.checkOutTime,
          checkInZone: w.checkInZone,
        );
      }).toList();
    });
  }

  Widget _buildShiftSelector() {
    final current = _selectedShift.toLowerCase();
    final isMorning = current == 'morning' || current.contains('morning') || current.contains('shift a');
    final isAfternoon = current == 'afternoon' || current.contains('afternoon') || current.contains('shift b');
    final isNight = current == 'night' || current.contains('night') || current.contains('shift c');

    return Row(
      children: [
        Expanded(
          child: _buildShiftTile(
            id: 'morning',
            title: 'Morning',
            hindi: 'सुबह की पाली',
            time: '06:00 - 14:00',
            icon: Icons.wb_sunny_rounded,
            color: AppColors.primaryAmber,
            isSelected: isMorning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildShiftTile(
            id: 'afternoon',
            title: 'Afternoon',
            hindi: 'दोपहर की पाली',
            time: '14:00 - 22:00',
            icon: Icons.wb_twilight_rounded,
            color: AppColors.secondaryOrange,
            isSelected: isAfternoon,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildShiftTile(
            id: 'night',
            title: 'Night',
            hindi: 'रात्रि पाली',
            time: '22:00 - 06:00',
            icon: Icons.nights_stay_rounded,
            color: AppColors.telemetryBlue,
            isSelected: isNight,
          ),
        ),
      ],
    );
  }

  Widget _buildShiftTile({
    required String id,
    required String title,
    required String hindi,
    required String time,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        if (_selectedShift != id) {
          setState(() {
            _selectedShift = id;
            _roster = AttendanceReport.getRosterForShift(id);
            _selectedCategory = 'All';
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : AppColors.cardLayer2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.strokeLowLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textDisabled),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTypography.labelSm.copyWith(
                color: isSelected ? color : AppColors.textHighEmphasis,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
            ),
            Text(
              hindi,
              style: TextStyle(
                color: isSelected ? color : AppColors.textDisabled,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                color: isSelected ? color : AppColors.textDisabled,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    final user = ref.read(authStateProvider);
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      final report = await repo.createDraft(
        user: user,
        shiftName: _selectedShift,
        musterLocation: _musterLocation,
        expectedHeadcount: _roster.length,
        actualHeadcount: _presentCount,
        entries: _roster,
      );

      await repo.submitAndLockAttendance(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n.reportSaved} • Muster Roll submitted ($_presentCount / ${_roster.length} present)',
            ),
            backgroundColor: AppColors.complianceGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRoster;
    final ratio = _roster.isEmpty ? 0.0 : (_presentCount / _roster.length).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(context.l10n.attendance, style: AppTypography.headlineSm),
        actions: [
          IconButton(
            tooltip: 'Mark All Present',
            icon: const Icon(Icons.done_all_rounded, color: AppColors.complianceGreen),
            onPressed: () => _markAll(true),
          ),
          IconButton(
            tooltip: 'Clear All',
            icon: const Icon(Icons.remove_done_rounded, color: AppColors.textDisabled),
            onPressed: () => _markAll(false),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shift & Location Header Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardLayer1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.strokeLowLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ACTIVE SHIFT & MUSTER POINT',
                        style: AppTypography.labelSm.copyWith(color: AppColors.primaryAmber),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.telemetryBlue.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'MINES ACT FORM-D',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.telemetryBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildShiftSelector(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, color: AppColors.textDisabled, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _musterLocation,
                      style: AppTypography.bodySm.copyWith(color: AppColors.textMediumEmphasis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Headcount Telemetry Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardLayer1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.strokeLowLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXPECTED ON ROLL',
                            style: AppTypography.labelSm.copyWith(color: AppColors.textDisabled, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text('${_roster.length}', style: AppTypography.displayLg.copyWith(fontSize: 22)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONFIRMED PRESENT',
                            style: AppTypography.labelSm.copyWith(color: AppColors.complianceGreen, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_presentCount',
                            style: AppTypography.displayLg.copyWith(color: AppColors.complianceGreen, fontSize: 22),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ratio >= 0.9 ? AppColors.complianceGreenLight : AppColors.secondaryOrange.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(ratio * 100).round()}%',
                        style: AppTypography.labelMd.copyWith(
                          color: ratio >= 0.9 ? AppColors.complianceGreen : AppColors.secondaryOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: AppColors.cardLayer2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ratio >= 0.9 ? AppColors.complianceGreen : AppColors.primaryAmber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search & Quick Filter
          TextField(
            decoration: InputDecoration(
              hintText: 'Search worker name, ID or contractor...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.cardLayer1,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 10),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textMediumEmphasis)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryAmberDark,
                    backgroundColor: AppColors.cardLayer1,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WORKERS (${filtered.length})',
                style: AppTypography.labelSm.copyWith(letterSpacing: 0.5),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _markAll(true),
                    icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.complianceGreen),
                    label: const Text('All Present', style: TextStyle(fontSize: 11, color: AppColors.complianceGreen)),
                  ),
                  TextButton.icon(
                    onPressed: () => _markAll(false),
                    icon: const Icon(Icons.highlight_off, size: 16, color: AppColors.hazardRed),
                    label: const Text('Clear', style: TextStyle(fontSize: 11, color: AppColors.hazardRed)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          ...filtered.map((worker) {
            final masterIndex = _roster.indexWhere((w) => w.workerId == worker.workerId);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: LargeTouchCard(
                isSelected: worker.isPresent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () {
                  if (masterIndex != -1) {
                    setState(() {
                      _roster[masterIndex] = WorkerAttendanceEntry(
                        workerId: worker.workerId,
                        workerName: worker.workerName,
                        category: worker.category,
                        contractorName: worker.contractorName,
                        isPresent: !worker.isPresent,
                        checkInTime: worker.checkInTime,
                        checkInZone: worker.checkInZone,
                      );
                    });
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: worker.isPresent ? AppColors.primaryAmberDark : AppColors.cardLayer2,
                      child: Text(
                        worker.workerName.substring(0, 1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(worker.workerName, style: AppTypography.labelMd),
                          Text(
                            '${worker.workerId} • ${worker.category}',
                            style: AppTypography.bodySm.copyWith(color: AppColors.textDisabled, fontSize: 11),
                          ),
                          Text(
                            worker.contractorName,
                            style: AppTypography.bodySm.copyWith(color: AppColors.primaryAmber, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: worker.isPresent,
                      activeThumbColor: AppColors.complianceGreen,
                      activeTrackColor: AppColors.complianceGreenLight,
                      onChanged: (val) {
                        if (masterIndex != -1) {
                          setState(() {
                            _roster[masterIndex] = WorkerAttendanceEntry(
                              workerId: worker.workerId,
                              workerName: worker.workerName,
                              category: worker.category,
                              contractorName: worker.contractorName,
                              isPresent: val,
                              checkInTime: worker.checkInTime,
                              checkInZone: worker.checkInZone,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            border: Border(top: BorderSide(color: AppColors.strokeLowLight, width: 1.5)),
          ),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitAttendance,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.primaryAmberDark,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'SUBMIT STATUTORY MUSTER ROLL ($_presentCount PRESENT)',
                    style: AppTypography.labelLg.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}
