import 'package:hive_flutter/hive_flutter.dart';
import '../models/project_file.dart';
import '../models/compiler_preset.dart';

class StorageService {
  static const String filesBoxName = 'project_files';
  static const String presetsBoxName = 'compiler_presets';
  static const String settingsBoxName = 'settings';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProjectFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<ProjectFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Box<ProjectFile> get filesBox => Hive.box<ProjectFile>(filesBoxName);
  Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);
}
