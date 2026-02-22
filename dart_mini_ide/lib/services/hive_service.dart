import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'code_files';
  static const String presetsBoxName = 'compiler_presets';
  static const String settingsBoxName = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<CodeFile> getFilesBox() => Hive.box<CodeFile>(filesBoxName);
  static Box<CompilerPreset> getPresetsBox() => Hive.box<CompilerPreset>(presetsBoxName);
  static Box getSettingsBox() => Hive.box(settingsBoxName);
}
