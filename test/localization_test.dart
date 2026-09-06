import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:minesafe/core/localization/app_language.dart';
import 'package:minesafe/core/localization/language_controller.dart';

void main() {
  test('all supported languages have unique locale codes and native names', () {
    final codes = AppLanguage.all.map((language) => language.code).toSet();
    final names = AppLanguage.all.map((language) => language.nativeName).toSet();

    expect(AppLanguage.all, hasLength(8));
    expect(codes, hasLength(8));
    expect(names, hasLength(8));
    expect(codes, containsAll(<String>['en', 'hi', 'or', 'te', 'bn', 'mr', 'hne', 'sat']));
  });

  test('language selection persists independently of authentication', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = LanguageController(preferences: preferences);

    expect(controller.state.hasSelection, isFalse);
    await controller.select(AppLanguage.fromCode('hi'));

    expect(controller.state.language.code, 'hi');
    expect(preferences.getString('minesafe_preferred_language'), 'hi');

    final restored = LanguageController(preferences: preferences);
    expect(restored.state.hasSelection, isTrue);
    expect(restored.state.language.nativeName, 'हिंदी');
  });
}
