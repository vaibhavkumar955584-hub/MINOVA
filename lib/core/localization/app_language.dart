import 'package:flutter/material.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.locale,
    required this.nativeName,
    required this.englishName,
  });

  final String code;
  final Locale locale;
  final String nativeName;
  final String englishName;

  static const all = <AppLanguage>[
    AppLanguage(code: 'en', locale: Locale('en'), nativeName: 'English', englishName: 'English'),
    AppLanguage(code: 'hi', locale: Locale('hi'), nativeName: 'हिंदी', englishName: 'Hindi'),
    AppLanguage(code: 'or', locale: Locale('or'), nativeName: 'ଓଡ଼ିଆ', englishName: 'Odia'),
    AppLanguage(code: 'te', locale: Locale('te'), nativeName: 'తెలుగు', englishName: 'Telugu'),
    AppLanguage(code: 'bn', locale: Locale('bn'), nativeName: 'বাংলা', englishName: 'Bengali'),
    AppLanguage(code: 'mr', locale: Locale('mr'), nativeName: 'मराठी', englishName: 'Marathi'),
    AppLanguage(code: 'hne', locale: Locale('hne'), nativeName: 'छत्तीसगढ़ी', englishName: 'Chhattisgarhi'),
    AppLanguage(code: 'sat', locale: Locale('sat'), nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ', englishName: 'Santali'),
  ];

  static AppLanguage fromCode(String? code) {
    return all.firstWhere(
      (language) => language.code == code,
      orElse: () => all.first,
    );
  }
}