import 'package:hive_flutter/hive_flutter.dart';
import '../models/file_model.dart';
import '../models/compiler_preset.dart';
import '../models/response_mapping.dart';
import '../utils/constants.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());
    Hive.registerAdapter(ResponseMappingAdapter());

    await Hive.openBox<FileModel>(Constants.boxFiles);
    await Hive.openBox<CompilerPreset>(Constants.boxPresets);
    await Hive.openBox(Constants.boxSettings);
  }

  static Box<FileModel> getFilesBox() {
    return Hive.box<FileModel>(Constants.boxFiles);
  }

  static Box<CompilerPreset> getPresetsBox() {
    return Hive.box<CompilerPreset>(Constants.boxPresets);
  }

  static Box getSettingsBox() {
    return Hive.box(Constants.boxSettings);
  }
}
