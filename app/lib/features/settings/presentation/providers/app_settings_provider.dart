import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mindflow/core/constants/app_constants.dart';
import 'package:mindflow/core/l10n/app_language.dart';
import 'package:mindflow/core/theme/app_theme.dart';

/// Single source of truth for every user-configurable setting: theme,
/// language, and the three RSVP dials. Both the Settings screen and the
/// Reader screen read from (and write to) this one provider.
class AppSettings {
  final AppThemeMode themeMode;
  final AppLanguage language;
  final int wpm;
  final int wordsPerGroup;
  final int lineCount;
  final int imageDisplayMs;
  final int fontSize;
  final bool onboardingComplete;

  const AppSettings({
    this.themeMode = AppThemeMode.light,
    this.language = AppLanguage.en,
    this.wpm = AppConstants.defaultWpm,
    this.wordsPerGroup = AppConstants.defaultWordsPerGroup,
    this.lineCount = AppConstants.defaultLineCount,
    this.imageDisplayMs = AppConstants.defaultImageDisplayMs,
    this.fontSize = AppConstants.defaultFontSize,
    this.onboardingComplete = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    int? wpm,
    int? wordsPerGroup,
    int? lineCount,
    int? imageDisplayMs,
    int? fontSize,
    bool? onboardingComplete,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      wpm: wpm ?? this.wpm,
      wordsPerGroup: wordsPerGroup ?? this.wordsPerGroup,
      lineCount: lineCount ?? this.lineCount,
      imageDisplayMs: imageDisplayMs ?? this.imageDisplayMs,
      fontSize: fontSize ?? this.fontSize,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}

/// Persists to the Hive `settings_box` (see `HiveBoxes`). Every mutator
/// clamps to the ranges in [AppConstants] so an invalid value can never
/// reach the reading engine.
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Box _box;

  AppSettingsNotifier(this._box) : super(_load(_box));

  static AppSettings _load(Box box) {
    return AppSettings(
      themeMode: AppThemeMode.values[
          (box.get(AppConstants.keyThemeMode, defaultValue: 0) as int)
              .clamp(0, AppThemeMode.values.length - 1)],
      language: AppLanguageX.fromCode(box.get(AppConstants.keyLanguageCode) as String?),
      wpm: (box.get(AppConstants.keyWpm, defaultValue: AppConstants.defaultWpm) as int)
          .clamp(AppConstants.minWpm, AppConstants.maxWpm),
      wordsPerGroup: (box.get(AppConstants.keyWordsPerGroup,
              defaultValue: AppConstants.defaultWordsPerGroup) as int)
          .clamp(AppConstants.minWordsPerGroup, AppConstants.maxWordsPerGroup),
      lineCount: (box.get(AppConstants.keyLineCount,
              defaultValue: AppConstants.defaultLineCount) as int)
          .clamp(AppConstants.minLineCount, AppConstants.maxLineCount),
      imageDisplayMs: box.get(AppConstants.keyImageDisplayMs,
          defaultValue: AppConstants.defaultImageDisplayMs) as int,
      fontSize: (box.get(AppConstants.keyFontSize, defaultValue: AppConstants.defaultFontSize) as int)
          .clamp(AppConstants.minFontSize, AppConstants.maxFontSize),
      onboardingComplete:
          box.get(AppConstants.keyOnboardingComplete, defaultValue: false) as bool,
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _box.put(AppConstants.keyThemeMode, mode.index);
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await _box.put(AppConstants.keyLanguageCode, language.name);
  }

  Future<void> setWpm(int wpm) async {
    final clamped = wpm.clamp(AppConstants.minWpm, AppConstants.maxWpm);
    state = state.copyWith(wpm: clamped);
    await _box.put(AppConstants.keyWpm, clamped);
  }

  Future<void> setWordsPerGroup(int count) async {
    final clamped =
        count.clamp(AppConstants.minWordsPerGroup, AppConstants.maxWordsPerGroup);
    state = state.copyWith(wordsPerGroup: clamped);
    await _box.put(AppConstants.keyWordsPerGroup, clamped);
  }

  Future<void> setLineCount(int count) async {
    final clamped = count.clamp(AppConstants.minLineCount, AppConstants.maxLineCount);
    state = state.copyWith(lineCount: clamped);
    await _box.put(AppConstants.keyLineCount, clamped);
  }

  Future<void> setImageDisplayMs(int ms) async {
    final clamped = ms.clamp(AppConstants.minImageDisplayMs, AppConstants.maxImageDisplayMs);
    state = state.copyWith(imageDisplayMs: clamped);
    await _box.put(AppConstants.keyImageDisplayMs, clamped);
  }

  Future<void> setFontSize(int size) async {
    final clamped = size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
    state = state.copyWith(fontSize: clamped);
    await _box.put(AppConstants.keyFontSize, clamped);
  }

  Future<void> completeOnboarding({required AppLanguage language}) async {
    state = state.copyWith(onboardingComplete: true, language: language);
    await _box.put(AppConstants.keyOnboardingComplete, true);
    await _box.put(AppConstants.keyLanguageCode, language.name);
  }
}

/// Overridden in `main.dart` once `HiveBoxes.init()` resolves.
final settingsBoxProvider = Provider<Box>((ref) {
  throw UnimplementedError('settingsBoxProvider must be overridden in main()');
});

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.watch(settingsBoxProvider));
});
