import 'package:hive/hive.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'files_box';
  static const String presetsBoxName = 'presets_box';

  static Future<void> initBoxes() async {
    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
  }

  static Box<CodeFile> get filesBox => Hive.box<CodeFile>(filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(presetsBoxName);
}
