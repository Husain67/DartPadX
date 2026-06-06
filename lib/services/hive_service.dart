import 'package:hive_flutter/hive_flutter.dart';
import '../models/file_model.dart';
import '../models/compiler_preset.dart';

class HiveService {
  static const String filesBoxName = 'files_box';
  static const String presetsBoxName = 'presets_box';
  static const String activeFileBoxName = 'active_file_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(filesBoxName);
    await Hive.openBox<String>(presetsBoxName);
    await Hive.openBox<String>(activeFileBoxName);
  }

  static Box<String> get filesBox => Hive.box<String>(filesBoxName);
  static Box<String> get presetsBox => Hive.box<String>(presetsBoxName);
  static Box<String> get activeFileBox => Hive.box<String>(activeFileBoxName);

  // Files
  static Future<void> saveFile(FileModel file) async {
    await filesBox.put(file.id, file.toJson());
  }

  static Future<void> deleteFile(String id) async {
    await filesBox.delete(id);
  }

  static List<FileModel> getFiles() {
    return filesBox.values.map((jsonStr) => FileModel.fromJson(jsonStr)).toList();
  }

  static Future<void> saveActiveFileId(String id) async {
    await activeFileBox.put('active_id', id);
  }

  static String? getActiveFileId() {
    return activeFileBox.get('active_id');
  }

  // Presets
  static Future<void> savePreset(CompilerPreset preset) async {
    await presetsBox.put(preset.id, preset.toJson());
  }

  static Future<void> deletePreset(String id) async {
    await presetsBox.delete(id);
  }

  static List<CompilerPreset> getPresets() {
    return presetsBox.values.map((jsonStr) => CompilerPreset.fromJson(jsonStr)).toList();
  }

  static Future<void> clearAll() async {
    await filesBox.clear();
    await presetsBox.clear();
    await activeFileBox.clear();
  }
}
