import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/language_controller.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/specialist_category.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/minova_logo.dart';
import 'language_selection_screen.dart';
import 'setup_security_screen.dart';
import 'unlock_screen.dart';

class EmployeeOnboardingScreen extends ConsumerStatefulWidget {
  const EmployeeOnboardingScreen({super.key});

  @override
  ConsumerState<EmployeeOnboardingScreen> createState() =>
      _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState
    extends ConsumerState<EmployeeOnboardingScreen> {
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  SpecialistCategory _selectedSpecialist = SpecialistCategory.mechanical;

  String _selectedMineId = 'JH-DHA-BCCL-007';
  String _selectedMineName = 'BCCL Pit-7 (Dhanbad)';

  final List<Map<String, String>> _availableMines = const [
    {
      'id': 'JH-DHA-BCCL-007',
      'name': 'BCCL Pit-7 (Dhanbad)',
    },
    {
      'id': 'WB-ECL-SB-012',
      'name': 'ECL Sonepur Bazari OpenCast',
    },
    {
      'id': 'JH-CCL-AMP-004',
      'name': 'CCL Amrapali OpenCast',
    },
    {
      'id': 'OD-MCL-TL-021',
      'name': 'MCL Talcher Deep Underground',
    },
    {
      'id': 'CG-SECL-DP-033',
      'name': 'SECL Dipka Mega Mine',
    },
  ];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage =
            'Please enter your full name. / कृपया अपना पूरा नाम दर्ज करें।';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final preferredLang =
          ref.read(languageControllerProvider).language.code;

      await ref.read(authStateProvider.notifier).loginEmployee(
            fullName: name,
            employeeId: _employeeIdController.text.trim(),
            mineId: _selectedMineId,
            mineName: _selectedMineName,
            specialist: _selectedSpecialist,
            preferredLanguage: preferredLang,
          );

      final isMpinConfigured =
          await ref.read(mpinServiceProvider).isMpinConfigured();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => isMpinConfigured
                ? const UnlockScreen()
                : const SetupSecurityScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          'Field Responder Setup',
          style: AppTypography.headlineSm.copyWith(fontSize: 16),
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer1,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.strokeLowLight),
                ),
                child: Row(
                  children: [
                    const MinovaLogo(
                      size: 48,
                      layout: MinovaLogoLayout.iconOnly,
                      theme: MinovaLogoTheme.fullColorDark,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FIELD RESPONDER PROFILE',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.telemetryBlue,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'कर्मचारी प्रोफाइल एवं विशेषज्ञता सेटअप',
                            style: AppTypography.bilingualCue.copyWith(
                              color: AppColors.primaryAmber,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 1. Employee Full Name
              Text(
                'YOUR FULL NAME / पूरा नाम *',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textHighEmphasis,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: AppTypography.bodyLg,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.telemetryBlue,
                  ),
                  hintText: 'e.g. Ramesh Kumar Verma',
                ),
              ),
              const SizedBox(height: 14),

              // 2. Employee Identifier (Optional)
              Text(
                'EMPLOYEE / BADGE ID (Optional)',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textMediumEmphasis,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _employeeIdController,
                textCapitalization: TextCapitalization.characters,
                style: AppTypography.bodyLg,
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: AppColors.telemetryBlue,
                  ),
                  hintText: 'e.g. EMP-9042 (Or Leave Empty)',
                ),
              ),
              const SizedBox(height: 14),

              // 3. Assigned Mine Selection
              Text(
                'ASSIGNED MINE LEASE / खदान का चयन *',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.textHighEmphasis,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardLayer1,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.strokeLowLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMineId,
                    isExpanded: true,
                    dropdownColor: AppColors.cardLayer2,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.primaryAmber,
                    ),
                    items: _availableMines.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['id'],
                        child: Text(
                          '${m['name']} (${m['id']})',
                          style: AppTypography.bodyMd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final found = _availableMines.firstWhere((m) => m['id'] == val);
                        setState(() {
                          _selectedMineId = val;
                          _selectedMineName = found['name']!;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 4. Specialist Category (Choose ONE)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'CHOOSE SPECIALIST ROLE / विशेषज्ञता चुनें *',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.textHighEmphasis,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select 1',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.primaryAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Emergency alerts matching your specialist category will be highlighted.',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),

              // Specialist Options List
              ...SpecialistCategory.values.map((cat) {
                final isSelected = _selectedSpecialist == cat;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected ? AppColors.cardLayer2 : AppColors.cardLayer1,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSpecialist = cat),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.telemetryBlue.withAlpha(40)
                                    : AppColors.cardLayer2,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                cat.icon,
                                color: isSelected
                                    ? AppColors.telemetryBlue
                                    : AppColors.textDisabled,
                                size: 20,
                              ),
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
                            Radio<SpecialistCategory>(
                              value: cat,
                              groupValue: _selectedSpecialist,
                              activeColor: AppColors.telemetryBlue,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedSpecialist = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.hazardRed.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.hazardRed.withAlpha(100)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.hazardRed,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 5. Submit Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCompleteOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.telemetryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'CONTINUE TO FIELD TERMINAL',
                              style: AppTypography.labelLg.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Security transparency note
              Center(
                child: Text(
                  'MVP identification mode • Passwordless field responder profile',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
