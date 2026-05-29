import 'package:hive_flutter/hive_flutter.dart';
import '../models/file_model.dart';
import '../models/compiler_preset_model.dart';

class HiveSetup {
  static const String filesBoxName = 'filesBox';
  static const String presetsBoxName = 'presetsBox';
  static const String settingsBoxName = 'settingsBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetModelAdapter());

    await Hive.openBox<FileModel>(filesBoxName);
    await Hive.openBox<CompilerPresetModel>(presetsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Box<FileModel> get filesBox => Hive.box<FileModel>(filesBoxName);
  static Box<CompilerPresetModel> get presetsBox => Hive.box<CompilerPresetModel>(presetsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
}
