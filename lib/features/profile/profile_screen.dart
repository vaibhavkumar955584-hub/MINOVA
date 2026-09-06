import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/language_controller.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/user_model.dart';
import '../../shared/providers/app_providers.dart';
import '../auth/login_screen.dart';
import '../auth/language_selection_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final connectivity = ref.watch(connectivityServiceProvider);
    final isOnline =
        ref.watch(connectivityStreamProvider).value ?? connectivity.isOnline;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.l10n.profileSettings,
          style: AppTypography.headlineSm,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardLayer1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.strokeLowLight, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryAmberDark,
                    child: Text(
                      user?.fullName.substring(0, 1) ?? 'U',
                      style: AppTypography.headlineMd.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Operator',
                          style: AppTypography.headlineSm.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          user?.designation ?? 'Field Officer',
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primaryAmber,
                          ),
                        ),
                        Text(
                          'ID: ${user?.employeeId ?? "N/A"} • ${user?.role.displayName ?? ""}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assigned Mine
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardLayer2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.strokeActive),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_city_rounded,
                    color: AppColors.primaryAmber,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASSIGNED MINE LEASE',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.textDisabled,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          (user?.assignedMineName.isNotEmpty == true)
                              ? '${user!.assignedMineName} (${user.assignedMineId})'
                              : (user?.assignedMineId.isNotEmpty == true ? user!.assignedMineId : 'None'),
                          style: AppTypography.labelMd,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings & Controls
            Text(
              context.l10n.operationalControls,
              style: AppTypography.labelSm,
            ),
            const SizedBox(height: 8),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              tileColor: AppColors.cardLayer1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              leading: const Icon(
                Icons.language_rounded,
                color: AppColors.primaryAmber,
              ),
              title: Text(context.l10n.language, style: AppTypography.bodyMd),
              subtitle: Text(
                ref.watch(languageControllerProvider).language.nativeName,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LanguageSelectionScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Network Simulation Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardLayer1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.strokeLowLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? Icons.wifi : Icons.wifi_off_rounded,
                          color: isOnline
                              ? AppColors.complianceGreen
                              : AppColors.hazardRed,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.undergroundMode,
                                style: AppTypography.bodyMd,
                              ),
                              Text(
                                isOnline
                                    ? context.l10n.networkOnline
                                    : context.l10n.forcedOffline,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.textDisabled,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: connectivity.isSimulatedOffline,
                    activeThumbColor: AppColors.hazardRed,
                    onChanged: (val) {
                      connectivity.toggleSimulatedOffline(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardLayer2,
                side: const BorderSide(color: AppColors.strokeActive),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.hazardRed,
              ),
              label: Text(
                context.l10n.logout,
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.hazardRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
