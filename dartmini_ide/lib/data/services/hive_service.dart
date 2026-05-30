import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'filesBox';
  static const String presetsBoxName = 'presetsBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CodeFileAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CompilerPresetAdapter());
    }

    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<CodeFile> get filesBox => Hive.box<CodeFile>(filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
