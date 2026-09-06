import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';

class LanguageState {
  const LanguageState({required this.language, required this.hasSelection});

  final AppLanguage language;
  final bool hasSelection;
}

class LanguageController extends StateNotifier<LanguageState> {
  LanguageController({SharedPreferences? preferences})
      : _preferences = preferences,
        super(const LanguageState(
          language: AppLanguage(
            code: 'en',
            locale: Locale('en'),
            nativeName: 'English',
            englishName: 'English',
          ),
          hasSelection: false,
        )) {
    final savedCode = _preferences?.getString(_preferenceKey);
    if (savedCode != null) {
      state = LanguageState(
        language: AppLanguage.fromCode(savedCode),
        hasSelection: true,
      );
    }
  }

  static const _preferenceKey = 'minesafe_preferred_language';
  final SharedPreferences? _preferences;

  Future<void> select(AppLanguage language) async {
    // 1. Immediately update state to trigger synchronous UI rebuild across entire app
    state = LanguageState(language: language, hasSelection: true);

    // 2. Asynchronously persist to local storage without blocking UI thread
    if (_preferences != null) {
      await _preferences.setString(_preferenceKey, language.code);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferenceKey, language.code);
    }
  }
}

final languageControllerProvider = StateNotifierProvider<LanguageController, LanguageState>(
  (ref) => LanguageController(),
);