import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindflow/core/l10n/app_language.dart';
import 'package:mindflow/core/l10n/app_strings.dart';
import 'package:mindflow/core/router/app_router.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';

/// First-launch screen: choose a language before anything else. GoRouter's
/// redirect logic (see `app_router.dart`) sends every first-time user here
/// and never shows it again once `onboardingComplete` is set.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late AppLanguage _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(appSettingsProvider).language;
  }

  @override
  Widget build(BuildContext context) {
    // Live-preview strings in the language being highlighted, so the
    // welcome text itself demonstrates the choice as it's made.
    final lang = _selected;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.auto_stories, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                AppStrings.t(lang, 'onboardingWelcomeTitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.t(lang, 'onboardingWelcomeBody'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Text(
                AppStrings.t(lang, 'onboardingChooseLanguage'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppLanguage.values.map((l) {
                  final isSelected = l == _selected;
                  return ChoiceChip(
                    label: Text(l.nativeName),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selected = l),
                  );
                }).toList(),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .completeOnboarding(language: _selected);
                  if (context.mounted) context.go(AppRoutes.library);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(AppStrings.t(lang, 'onboardingContinue')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
