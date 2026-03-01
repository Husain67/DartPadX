import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class StorageService {
  static const String _filesBoxName = 'files_box';
  static const String _presetsBoxName = 'presets_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<CodeFile>(_filesBoxName);
    await Hive.openBox<CompilerPreset>(_presetsBoxName);
  }

  static Box<CodeFile> get filesBox => Hive.box<CodeFile>(_filesBoxName);
  static Box<CompilerPreset> get presetsBox => Hive.box<CompilerPreset>(_presetsBoxName);
}
