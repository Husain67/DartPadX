import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'app_files';
  static const String presetsBoxName = 'compiler_presets';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(AppFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());
    Hive.registerAdapter(ResponseMappingAdapter());

    await Hive.openBox<AppFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
  }

  static Box<AppFile> get filesBox => Hive.box<AppFile>(filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
}
