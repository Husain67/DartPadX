import 'package:hive_flutter/hive_flutter.dart';
import '../models/file_model.dart';
import '../models/preset_model.dart';

class HiveHelper {
  static const String fileBoxName = 'files';
  static const String presetBoxName = 'presets';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(PresetModelAdapter());

    await Hive.openBox<FileModel>(fileBoxName);
    await Hive.openBox<PresetModel>(presetBoxName);
  }

  static Box<FileModel> get fileBox => Hive.box<FileModel>(fileBoxName);
  static Box<PresetModel> get presetBox => Hive.box<PresetModel>(presetBoxName);
}
