import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/core/constants/app_constants.dart';
import 'package:mindflow/core/l10n/app_language.dart';
import 'package:mindflow/core/platform/incoming_file_channel.dart';
import 'package:mindflow/core/router/app_router.dart';
import 'package:mindflow/core/storage/hive_boxes.dart';
import 'package:mindflow/core/theme/app_theme.dart';
import 'package:mindflow/features/document_import/presentation/providers/import_providers.dart';
import 'package:mindflow/features/library/presentation/providers/library_providers.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';

/// Root widget. Picks the active theme, wraps everything in
/// `Directionality` matching the chosen language (Arabic renders
/// right-to-left automatically), and -- on Android -- handles a file the
/// app was launched or re-opened with via "Open with MindFlow" (see
/// `IncomingFileChannel`), importing it and jumping straight to the reader.
class MindFlowApp extends ConsumerStatefulWidget {
  const MindFlowApp({super.key});

  @override
  ConsumerState<MindFlowApp> createState() => _MindFlowAppState();
}

class _MindFlowAppState extends ConsumerState<MindFlowApp> {
  @override
  void initState() {
    super.initState();
    IncomingFileChannel.listenForFileOpened(_handleIncomingFile);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await IncomingFileChannel.getInitialFile();
      if (initial != null) _handleIncomingFile(initial);
    });
  }

  Future<void> _handleIncomingFile(IncomingFile file) async {
    // Android can replay the exact same "Open with" launch intent when the
    // app process was killed in the background and later resumed --
    // without this check, that looked like the file re-opening itself
    // every single time the app was foregrounded. Comparing against the
    // last-handled URI (persisted in Hive, so it survives a process
    // restart) makes this a no-op the second time around.
    if (file.sourceUri != null) {
      final lastUri = HiveBoxes.settings.get(AppConstants.keyLastIncomingFileUri) as String?;
      if (lastUri == file.sourceUri) return;
      await HiveBoxes.settings.put(AppConstants.keyLastIncomingFileUri, file.sourceUri);
    }

    try {
      final document = await ref
          .read(importDocumentUseCaseProvider)
          .call(bytes: file.bytes, fileName: file.fileName);
      ref.invalidate(libraryProvider);
      ref.read(appRouterProvider).push('/reader', extra: document);
    } catch (_) {
      // Import failures from an external "Open with" launch have nowhere
      // good to surface an error yet (there's no screen open to show a
      // SnackBar on) -- silently ignoring is preferable to crashing the
      // app on startup. The Library screen's own "Import" button still
      // reports errors normally for the in-app flow.
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MindFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(settings.themeMode),
      locale: settings.language.locale,
      supportedLocales: const [
        Locale('en'), Locale('tr'), Locale('es'), Locale('de'), Locale('fr'), Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return Directionality(
          textDirection: settings.language.textDirection,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
