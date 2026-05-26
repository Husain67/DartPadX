import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_model.dart';
import '../models/compiler_preset.dart';

class StorageService {
  static const String _filesBoxName = 'filesBox';
  static const String _presetsBoxName = 'presetsBox';

  static Box<FileModel>? _filesBox;
  static Box<CompilerPreset>? _presetsBox;

  static Future<void> init() async {
    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    _filesBox = await Hive.openBox<FileModel>(_filesBoxName);
    _presetsBox = await Hive.openBox<CompilerPreset>(_presetsBoxName);
  }

  // Files
  static List<FileModel> getFiles() {
    return _filesBox?.values.toList() ?? [];
  }

  static Future<void> saveFile(FileModel file) async {
    await _filesBox?.put(file.id, file);
  }

  static Future<void> deleteFile(String id) async {
    await _filesBox?.delete(id);
  }

  // Presets
  static List<CompilerPreset> getPresets() {
    return _presetsBox?.values.toList() ?? [];
  }

  static Future<void> savePreset(CompilerPreset preset) async {
    await _presetsBox?.put(preset.id, preset);
  }

  static Future<void> deletePreset(String id) async {
    await _presetsBox?.delete(id);
  }

  // Settings
  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
