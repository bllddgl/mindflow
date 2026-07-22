import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/app.dart';
import 'package:mindflow/core/storage/hive_boxes.dart';
import 'package:mindflow/features/settings/presentation/providers/app_settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive must be ready before the widget tree builds: AppSettingsNotifier
  // reads synchronously from it at construction time, and the router
  // decides onboarding-vs-library based on that same snapshot.
  await HiveBoxes.init();

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(HiveBoxes.settings),
      ],
      child: const MindFlowApp(),
    ),
  );
}
