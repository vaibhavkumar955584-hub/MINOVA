import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/user_model.dart';
import '../../shared/providers/app_providers.dart';
import '../home/employee_home_screen.dart';
import '../home/home_dashboard_screen.dart';
import '../notifications/emergency_notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../records/records_screen.dart';
import '../report/incident/incident_report_screen.dart';
import '../report/report_hub_screen.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkInterruptedDraft();
  }

  Future<void> _checkInterruptedDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeUuid = prefs.getString('active_incident_draft_uuid');
      if (activeUuid != null && activeUuid.isNotEmpty) {
        final repo = ref.read(incidentRepositoryProvider);
        final draft = await repo.getDraftByClientUuid(activeUuid);
        if (draft != null && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IncidentReportScreen(initialClientUuid: activeUuid),
                ),
              );
            }
          });
        }
      }
    } catch (_) {}
  }

  void _openAction(bool isEmployee) {
    if (isEmployee) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReportHubScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final isEmployee = user?.role == UserRole.employee;

    final screens = isEmployee
        ? const [
            EmployeeHomeScreen(),
            EmergencyNotificationsScreen(),
            ProfileScreen(),
          ]
        : const [
            HomeDashboardScreen(),
            RecordsScreen(),
            ProfileScreen(),
          ];

    final centerColor = isEmployee ? AppColors.hazardRed : AppColors.primaryAmberDark;
    final centerLabel = isEmployee ? 'Incident' : context.l10n.report;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex >= screens.length ? 0 : _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: AppColors.strokeLowLight, width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              Expanded(
                child: _buildNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: context.l10n.home,
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
              ),

              // 2. Center Action
              GestureDetector(
                onTap: () => _openAction(isEmployee),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: centerColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: centerColor.withAlpha(60),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEmployee ? Icons.warning_amber_rounded : Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        centerLabel,
                        style: AppTypography.labelLg.copyWith(
                          color: Colors.white,
                          letterSpacing: 0.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Right 1: Alerts (Employee) or Records (Inspector)
              Expanded(
                child: _buildNavItem(
                  icon: isEmployee
                      ? Icons.campaign_outlined
                      : Icons.inventory_2_outlined,
                  activeIcon: isEmployee
                      ? Icons.campaign_rounded
                      : Icons.inventory_2_rounded,
                  label: isEmployee ? 'Alerts' : context.l10n.records,
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),

              // 4. Right 2: Profile
              Expanded(
                child: _buildNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: context.l10n.profile,
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? AppColors.primaryAmber : AppColors.textDisabled;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: color,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

