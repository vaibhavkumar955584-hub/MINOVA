import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/language_controller.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/specialist_category.dart';
import '../../models/user_model.dart';
import '../../shared/providers/app_providers.dart';
import '../auth/language_selection_screen.dart';
import '../auth/role_selection_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showSpecialistSelectionSheet(BuildContext context, WidgetRef ref, UserModel user) {
    final currentSpecialist = SpecialistCategory.fromKey(user.designation);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.canvas,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.strokeActive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.engineering_rounded, color: AppColors.telemetryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Update Specialist Role / विशेषज्ञता बदलें',
                      style: AppTypography.headlineSm.copyWith(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.strokeLowLight),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: SpecialistCategory.values.map((cat) {
                  final isSelected = currentSpecialist == cat;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected ? AppColors.cardLayer2 : AppColors.cardLayer1,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () async {
                          final updated = user.copyWith(designation: cat.displayName);
                          await ref.read(authServiceProvider).setAuthenticatedUser(
                            user: updated,
                            token: 'employee_mvp_${updated.id}',
                          );
                          ref.read(authStateProvider.notifier).switchUser(updated);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.telemetryBlue
                                  : AppColors.strokeLowLight,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                cat.icon,
                                color: isSelected
                                    ? AppColors.telemetryBlue
                                    : AppColors.textDisabled,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.displayName,
                                      style: AppTypography.labelMd.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textHighEmphasis,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      cat.hindiName,
                                      style: AppTypography.bilingualCue.copyWith(
                                        color: isSelected
                                            ? AppColors.primaryAmber
                                            : AppColors.textDisabled,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.telemetryBlue,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final connectivity = ref.watch(connectivityServiceProvider);
    final isOnline =
        ref.watch(connectivityStreamProvider).value ?? connectivity.isOnline;
    final isEmployee = user?.role == UserRole.employee;

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
                    backgroundColor: isEmployee
                        ? AppColors.telemetryBlue
                        : AppColors.primaryAmberDark,
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName.substring(0, 1).toUpperCase()
                          : 'U',
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user?.designation ?? 'Field Officer',
                          style: AppTypography.bodyMd.copyWith(
                            color: isEmployee
                                ? AppColors.telemetryBlue
                                : AppColors.primaryAmber,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

            // Specialist Selection Tile (For Employee only)
            if (isEmployee && user != null) ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                tileColor: AppColors.cardLayer1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.strokeLowLight),
                ),
                leading: const Icon(
                  Icons.engineering_rounded,
                  color: AppColors.telemetryBlue,
                ),
                title: const Text('Specialist Category', style: TextStyle(fontSize: 14)),
                subtitle: Text(
                  user.designation,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.telemetryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primaryAmber),
                onTap: () => _showSpecialistSelectionSheet(context, ref, user),
              ),
              const SizedBox(height: 12),
            ],

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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 14),

            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardLayer2,
                side: const BorderSide(color: AppColors.strokeActive),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
