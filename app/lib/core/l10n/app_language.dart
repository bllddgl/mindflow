import 'package:flutter/material.dart';

/// Every language MindFlow's UI can be shown in. Adding a new language is:
/// 1. add a case here, 2. add its row to `_translations` in
/// `translations.dart`. Nothing else in the app needs to change --
/// screens read strings through [AppStrings.of], never hardcoded text.
enum AppLanguage {
  en, // English
  tr, // Türkçe
  es, // Español
  de, // Deutsch
  fr, // Français
  ar, // العربية
}

extension AppLanguageX on AppLanguage {
  Locale get locale => Locale(name);

  /// Name shown *in that language itself* -- a Turkish speaker should see
  /// "Türkçe", not "Turkish", when scanning the picker.
  String get nativeName {
    switch (this) {
      case AppLanguage.en:
        return 'English';
      case AppLanguage.tr:
        return 'Türkçe';
      case AppLanguage.es:
        return 'Español';
      case AppLanguage.de:
        return 'Deutsch';
      case AppLanguage.fr:
        return 'Français';
      case AppLanguage.ar:
        return 'العربية';
    }
  }

  TextDirection get textDirection =>
      this == AppLanguage.ar ? TextDirection.rtl : TextDirection.ltr;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.name == code,
      orElse: () => AppLanguage.en,
    );
  }
}
