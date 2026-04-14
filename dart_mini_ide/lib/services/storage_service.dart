import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

class StorageService {
  static const String fileBoxName = 'files';
  static const String presetBoxName = 'presets';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CodeFileAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());
    await Hive.openBox<CodeFile>(fileBoxName);
    await Hive.openBox<CompilerPreset>(presetBoxName);
  }

  Box<CodeFile> get fileBox => Hive.box<CodeFile>(fileBoxName);
  Box<CompilerPreset> get presetBox => Hive.box<CompilerPreset>(presetBoxName);

  List<CodeFile> getFiles() {
    final files = fileBox.values.toList();
    if (files.isEmpty) {
      final initialFile = CodeFile(
        name: 'main.dart',
        content: '''void main() {
  print('Hello from DartMini IDE!');
}''',
      );
      fileBox.put(initialFile.id, initialFile);
      return [initialFile];
    }
    return files;
  }

  void saveFile(CodeFile file) {
    fileBox.put(file.id, file);
  }

  void deleteFile(String id) {
    fileBox.delete(id);
  }

  List<CompilerPreset> getPresets() {
    return presetBox.values.toList();
  }

  void savePreset(CompilerPreset preset) {
    presetBox.put(preset.id, preset);
  }

  void deletePreset(String id) {
    presetBox.delete(id);
  }

  void clearPresets() {
    presetBox.clear();
  }
}
