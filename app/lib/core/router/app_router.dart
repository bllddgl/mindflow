import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mindflow/core/router/app_shell.dart';
import 'package:mindflow/features/document_import/domain/entities/reading_document.dart';
import 'package:mindflow/features/library/presentation/screens/library_screen.dart';
import 'package:mindflow/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mindflow/features/quotes/presentation/screens/quotes_screen.dart';
import 'package:mindflow/features/reader/presentation/screens/reader_screen.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:mindflow/features/settings/presentation/screens/settings_screen.dart';
import 'package:mindflow/features/stats/presentation/screens/stats_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const onboarding = '/onboarding';
  static const library = '/library';
  static const quotes = '/quotes';
  static const stats = '/stats';
  static const settings = '/settings';
  static const reader = '/reader';
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// Whether onboarding is needed is decided ONCE, when the router is built
/// (using `ref.read`, not `ref.watch` -- Hive has already loaded by the
/// time `main()` calls `runApp`, so this is a real, correct snapshot, and
/// the router is never rebuilt just because some other setting changes
/// later). `OnboardingScreen` itself navigates to `/library` once the
/// user finishes, so no reactive redirect logic is needed here.
final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.read(appSettingsProvider).onboardingComplete;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: onboardingComplete ? AppRoutes.library : AppRoutes.onboarding,
    // Defensive fallback: if the app is ever handed a location it doesn't
    // recognise as an initial route (this can happen with "Open with" on
    // some devices/launchers, which may surface the raw content:// URI to
    // Flutter before our own file-import channel has a chance to react),
    // land safely on the library instead of GoRouter's default
    // "Page Not Found" screen. The actual file import/open still happens
    // separately, via `IncomingFileChannel` in app.dart.
    errorBuilder: (context, state) => onboardingComplete
        ? const LibraryScreen()
        : const OnboardingScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          final index = switch (state.uri.path) {
            AppRoutes.quotes => 1,
            AppRoutes.stats => 2,
            AppRoutes.settings => 3,
            _ => 0,
          };
          return Consumer(builder: (context, ref, _) {
            final lang = ref.watch(appSettingsProvider).language;
            return AppShell(
              currentIndex: index,
              language: lang,
              onDestinationSelected: (i) {
                context.go(switch (i) {
                  1 => AppRoutes.quotes,
                  2 => AppRoutes.stats,
                  3 => AppRoutes.settings,
                  _ => AppRoutes.library,
                });
              },
              child: child,
            );
          });
        },
        routes: [
          GoRoute(path: AppRoutes.library, builder: (context, state) => const LibraryScreen()),
          GoRoute(path: AppRoutes.quotes, builder: (context, state) => const QuotesScreen()),
          GoRoute(path: AppRoutes.stats, builder: (context, state) => const StatsScreen()),
          GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.reader,
        builder: (context, state) => ReaderScreen(document: state.extra as ReadingDocument),
      ),
    ],
  );
});
