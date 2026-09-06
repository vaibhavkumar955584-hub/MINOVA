import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this) ?? AppLocalizationsEn();
}