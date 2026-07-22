import 'app_language.dart';
import 'translations.dart';

/// Looks up a UI string for the active [AppLanguage].
///
/// Usage: `AppStrings.t(ref.watch(appSettingsProvider).language, 'libraryTitle')`.
/// Falls back to English, then to the raw key, so a missing translation
/// never crashes the app -- it just shows English or the key itself,
/// which is an easy thing to spot and fix.
class AppStrings {
  AppStrings._();

  static String t(AppLanguage language, String key) {
    final table = Translations.forLanguage(language);
    return table[key] ?? Translations.forLanguage(AppLanguage.en)[key] ?? key;
  }
}
