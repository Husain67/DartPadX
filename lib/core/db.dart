import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class DB {
  static const String filesBoxName = 'filesBox';
  static const String presetsBoxName = 'presetsBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(FileStateAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<FileState>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<FileState> get filesBox => Hive.box<FileState>(filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
