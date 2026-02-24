import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'code_files';
  static const String settingsBoxName = 'settings';
  static const String presetsBoxName = 'compiler_presets';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
  }
}
