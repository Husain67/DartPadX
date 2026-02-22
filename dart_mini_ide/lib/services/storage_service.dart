import 'package:hive/hive.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';
import 'hive_service.dart';

class StorageService {
  final Box<CodeFile> _filesBox;
  final Box<CompilerPreset> _presetsBox;
  final Box _settingsBox;

  StorageService()
      : _filesBox = HiveService.getFilesBox(),
        _presetsBox = HiveService.getPresetsBox(),
        _settingsBox = HiveService.getSettingsBox();

  // Files
  List<CodeFile> getAllFiles() {
    return _filesBox.values.toList();
  }

  Future<void> saveFile(CodeFile file) async {
    await _filesBox.put(file.id, file);
  }

  Future<void> deleteFile(String id) async {
    await _filesBox.delete(id);
  }

  CodeFile? getFile(String id) {
    return _filesBox.get(id);
  }

  // Presets
  List<CompilerPreset> getAllPresets() {
    return _presetsBox.values.toList();
  }

  Future<void> savePreset(CompilerPreset preset) async {
    await _presetsBox.put(preset.id, preset);
  }

  Future<void> deletePreset(String id) async {
    await _presetsBox.delete(id);
  }

  CompilerPreset? getPreset(String id) {
    return _presetsBox.get(id);
  }

  // Settings
  Future<void> saveActivePresetId(String? id) async {
    await _settingsBox.put('activePresetId', id);
  }

  String? getActivePresetId() {
    return _settingsBox.get('activePresetId');
  }

  Future<void> saveUseCustomPreset(bool value) async {
    await _settingsBox.put('useCustomPreset', value);
  }

  bool getUseCustomPreset() {
    return _settingsBox.get('useCustomPreset', defaultValue: false);
  }
}
