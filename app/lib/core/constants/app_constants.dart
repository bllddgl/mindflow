/// App-wide tuning limits and persistence keys, centralised so they're
/// never duplicated (or drift out of sync) across features.
class AppConstants {
  AppConstants._();

  static const int minWpm = 100;
  static const int maxWpm = 2000;
  static const int defaultWpm = 300;

  static const int minWordsPerGroup = 1;
  static const int maxWordsPerGroup = 20;
  static const int defaultWordsPerGroup = 1;

  static const int minLineCount = 1;
  static const int maxLineCount = 5;
  static const int defaultLineCount = 1;

  static const int minFontSize = 24;
  static const int maxFontSize = 80;
  static const int defaultFontSize = 44;

  static const int defaultImageDisplayMs = 2000;
  static const int minImageDisplayMs = 500;
  static const int maxImageDisplayMs = 8000;

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  // Hive box names
  static const String settingsBox = 'settings_box';
  static const String progressBox = 'progress_box';

  // Hive keys inside settingsBox
  static const String keyThemeMode = 'themeMode';
  static const String keyLanguageCode = 'languageCode';
  static const String keyWpm = 'wpm';
  static const String keyWordsPerGroup = 'wordsPerGroup';
  static const String keyLineCount = 'lineCount';
  static const String keyFontSize = 'fontSize';
  static const String keyImageDisplayMs = 'imageDisplayMs';
  static const String keyOnboardingComplete = 'onboardingComplete';
  static const String keyLastIncomingFileUri = 'lastIncomingFileUri';
}
