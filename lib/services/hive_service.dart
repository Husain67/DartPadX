import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'filesBox';
  static const String presetsBoxName = 'presetsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());
    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
  }

  static Box<CodeFile> get filesBox => Hive.box<CodeFile>(filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
}
