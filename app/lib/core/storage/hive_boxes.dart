import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindflow/core/constants/app_constants.dart';

/// Opens the two Hive boxes used for fast, schema-less reads/writes:
/// user settings and "where did I leave off" reading progress. Plain
/// `Map`-based boxes -- no `TypeAdapter` codegen needed.
class HiveBoxes {
  HiveBoxes._();

  static late Box settings;
  static late Box progress;

  static Future<void> init() async {
    await Hive.initFlutter();
    settings = await Hive.openBox(AppConstants.settingsBox);
    progress = await Hive.openBox(AppConstants.progressBox);
  }
}
