import 'package:flutter/material.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/minova_logo.dart';
import 'employee_onboarding_screen.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: context.l10n.language,
            icon: const Icon(Icons.language_rounded, color: AppColors.primaryAmber),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LanguageSelectionScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. MINOVA Branding
                const Center(
                  child: MinovaLogo(
                    size: 96,
                    layout: MinovaLogoLayout.vertical,
                    theme: MinovaLogoTheme.fullColorLight,
                    showTagline: true,
                    customTagline: 'SAFER MINES. A STRONGER TOMORROW.',
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryAmber.withAlpha(60),
                      ),
                    ),
                    child: Text(
                      'खनन सुरक्षा एवं परिचालन प्रणाली • OPERATIONAL TERMINAL',
                      style: AppTypography.bilingualCue.copyWith(
                        color: AppColors.primaryAmberDark,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Title Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Your Role',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.textHighEmphasis,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'अपनी भूमिका चुनें (Designated Role in Mining Operations)',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textMediumEmphasis,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Choice 1: Inspector
                _RoleCard(
                  title: 'Statutory Inspector',
                  hindiTitle: 'वैधानिक खान निरीक्षक (DGMS / Management)',
                  description:
                      'Conduct safety audits, multi-gas telemetry inspections, Form-D muster, and compliance vault.',
                  badge: 'FULL ACCESS',
                  badgeColor: AppColors.primaryAmberDark,
                  icon: Icons.shield_rounded,
                  iconColor: AppColors.primaryAmberDark,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 4. Choice 2: Employee / Field Responder
                _RoleCard(
                  title: 'Employee / Field Responder',
                  hindiTitle: 'खान कर्मी एवं आपातकालीन रेस्पोंडर',
                  description:
                      'Receive real-time emergency broadcasts, specialist role alerts, and submit offline field incident reports.',
                  badge: 'FIELD RESPONDER',
                  badgeColor: AppColors.telemetryBlue,
                  icon: Icons.engineering_rounded,
                  iconColor: AppColors.telemetryBlue,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmployeeOnboardingScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 5. Statutory Footnote
                Center(
                  child: Text(
                    'DIRECTORATE GENERAL OF MINES SAFETY • STATUTORY COMPLIANCE',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.hindiTitle,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String hindiTitle;
  final String description;
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardLayer1,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: iconColor.withAlpha(25),
        highlightColor: iconColor.withAlpha(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.strokeLowLight,
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withAlpha(60),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textHighEmphasis,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: badgeColor.withAlpha(70),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: AppTypography.labelSm.copyWith(
                              color: badgeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hindiTitle,
                      style: AppTypography.bilingualCue.copyWith(
                        color: AppColors.primaryAmberDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textMediumEmphasis,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textDisabled,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
