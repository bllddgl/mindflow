import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/core/constants/app_constants.dart';
import 'package:mindflow/core/l10n/app_language.dart';
import 'package:mindflow/core/l10n/app_strings.dart';
import 'package:mindflow/core/theme/app_theme.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final lang = settings.language;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(lang, 'settingsTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppStrings.t(lang, 'settingsLanguage'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<AppLanguage>(
            initialValue: settings.language,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: AppLanguage.values
                .map((l) => DropdownMenuItem(value: l, child: Text(l.nativeName)))
                .toList(),
            onChanged: (l) {
              if (l != null) notifier.setLanguage(l);
            },
          ),
          const SizedBox(height: 32),
          Text(AppStrings.t(lang, 'settingsTheme'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<AppThemeMode>(
            segments: [
              ButtonSegment(value: AppThemeMode.light, label: Text(AppStrings.t(lang, 'themeLight')), icon: const Icon(Icons.light_mode_outlined)),
              ButtonSegment(value: AppThemeMode.dark, label: Text(AppStrings.t(lang, 'themeDark')), icon: const Icon(Icons.dark_mode_outlined)),
              ButtonSegment(value: AppThemeMode.sepia, label: Text(AppStrings.t(lang, 'themeSepia')), icon: const Icon(Icons.auto_stories_outlined)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => notifier.setThemeMode(s.first),
          ),
          const SizedBox(height: 32),
          Text('${AppStrings.t(lang, 'settingsDefaultSpeed')}: ${settings.wpm}', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: settings.wpm.toDouble(),
            min: AppConstants.minWpm.toDouble(),
            max: AppConstants.maxWpm.toDouble(),
            divisions: (AppConstants.maxWpm - AppConstants.minWpm) ~/ 10,
            onChanged: (v) => notifier.setWpm(v.round()),
          ),
          const SizedBox(height: 16),
          Text('${AppStrings.t(lang, 'settingsWordsAtOnce')}: ${settings.wordsPerGroup}', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: settings.wordsPerGroup.toDouble(),
            min: AppConstants.minWordsPerGroup.toDouble(),
            max: AppConstants.maxWordsPerGroup.toDouble(),
            divisions: AppConstants.maxWordsPerGroup - AppConstants.minWordsPerGroup,
            onChanged: (v) => notifier.setWordsPerGroup(v.round()),
          ),
          const SizedBox(height: 16),
          Text('${AppStrings.t(lang, 'settingsFontSize')}: ${settings.fontSize}', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: settings.fontSize.toDouble(),
            min: AppConstants.minFontSize.toDouble(),
            max: AppConstants.maxFontSize.toDouble(),
            divisions: AppConstants.maxFontSize - AppConstants.minFontSize,
            onChanged: (v) => notifier.setFontSize(v.round()),
          ),
          const SizedBox(height: 16),
          Text('${AppStrings.t(lang, 'settingsLineCount')}: ${settings.lineCount}', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: settings.lineCount.toDouble(),
            min: AppConstants.minLineCount.toDouble(),
            max: AppConstants.maxLineCount.toDouble(),
            divisions: AppConstants.maxLineCount - AppConstants.minLineCount,
            onChanged: (v) => notifier.setLineCount(v.round()),
          ),
          const SizedBox(height: 16),
          Text('${AppStrings.t(lang, 'settingsImageDuration')}: ${(settings.imageDisplayMs / 1000).toStringAsFixed(1)}s',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: settings.imageDisplayMs.toDouble(),
            min: AppConstants.minImageDisplayMs.toDouble(),
            max: AppConstants.maxImageDisplayMs.toDouble(),
            divisions: (AppConstants.maxImageDisplayMs - AppConstants.minImageDisplayMs) ~/ 500,
            onChanged: (v) => notifier.setImageDisplayMs(v.round()),
          ),
        ],
      ),
    );
  }
}
