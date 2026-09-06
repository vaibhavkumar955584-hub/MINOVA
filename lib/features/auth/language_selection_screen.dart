import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_language.dart';
import '../../core/localization/language_controller.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageControllerProvider).language;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: canPop
          ? AppBar(
              backgroundColor: AppColors.cardLayer2,
              title: Text(
                context.l10n.chooseLanguage,
                style: AppTypography.headlineSm,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  canPop ? 20 : 40,
                  20,
                  16,
                ),
                children: [
                  if (!canPop) ...[
                    Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryAmber.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryAmber.withAlpha(80),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppColors.primaryAmber,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.chooseLanguage,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineLg.copyWith(letterSpacing: 0.2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'अपनी भाषा चुनें / Select Statutory Language',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  ...AppLanguage.all.map(
                    (language) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LanguageOptionTile(
                        language: language,
                        isSelected: selected.code == language.code,
                        onTap: () {
                          ref
                              .read(languageControllerProvider.notifier)
                              .select(language);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: AppColors.strokeLowLight, width: 1.5),
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (canPop) {
                    Navigator.of(context).pop();
                  } else {
                    // Completes initial setup by ensuring current selection is persisted
                    ref
                        .read(languageControllerProvider.notifier)
                        .select(selected);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAmberDark,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.continueButton,
                      style: AppTypography.labelLg.copyWith(
                        color: Colors.white,
                        letterSpacing: 0.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
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

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${language.nativeName} (${language.englishName})',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryAmberDark
                  : AppColors.cardLayer1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryAmber
                    : AppColors.strokeLowLight,
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        language.nativeName,
                        style: AppTypography.bodyLg.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textHighEmphasis,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (language.nativeName != language.englishName) ...[
                        const SizedBox(height: 2),
                        Text(
                          language.englishName,
                          style: AppTypography.bodySm.copyWith(
                            color: isSelected
                                ? Colors.white.withAlpha(200)
                                : AppColors.textDisabled,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : AppColors.strokeActive,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.primaryAmberDark,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}