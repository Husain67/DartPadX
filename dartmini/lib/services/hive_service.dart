import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<CodeFile>('filesBox');
    await Hive.openBox<CompilerPreset>('presetsBox');
    await Hive.openBox('settingsBox');
  }
}
