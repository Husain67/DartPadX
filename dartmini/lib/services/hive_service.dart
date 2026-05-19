import 'package:hive_flutter/hive_flutter.dart';
import '../models/file_model.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'files_box';
  static const String presetsBoxName = 'presets_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FileModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CompilerPresetAdapter());
    }

    // Open boxes
    await Hive.openBox<FileModel>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
  }

  static Box<FileModel> get filesBox => Hive.box<FileModel>(filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
}
