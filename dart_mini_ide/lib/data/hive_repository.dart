import 'package:hive_flutter/hive_flutter.dart';
import 'code_file.dart';
import 'compiler_preset.dart';

class HiveRepository {
  static const String filesBoxName = 'codeFiles';
  static const String presetsBoxName = 'compilerPresets';

  static Future<void> init() async {
    await Hive.openBox<CodeFile>(filesBoxName);
    await Hive.openBox<CompilerPreset>(presetsBoxName);
  }

  // --- Code Files ---
  Box<CodeFile> get _filesBox => Hive.box<CodeFile>(filesBoxName);

  List<CodeFile> getFiles() {
    return _filesBox.values.toList();
  }

  Future<void> saveFile(CodeFile file) async {
    await _filesBox.put(file.id, file);
  }

  Future<void> deleteFile(String id) async {
    await _filesBox.delete(id);
  }

  // --- Compiler Presets ---
  Box<CompilerPreset> get _presetsBox => Hive.box<CompilerPreset>(presetsBoxName);

  List<CompilerPreset> getPresets() {
    return _presetsBox.values.toList();
  }

  Future<void> savePreset(CompilerPreset preset) async {
    await _presetsBox.put(preset.id, preset);
  }

  Future<void> deletePreset(String id) async {
    await _presetsBox.delete(id);
  }
}
