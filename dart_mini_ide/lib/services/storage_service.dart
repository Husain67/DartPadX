import 'package:dart_mini_ide/core/constants.dart';
import 'package:dart_mini_ide/models/code_file.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  late Box<CodeFile> _filesBox;
  late Box<CompilerPreset> _presetsBox;
  late Box _settingsBox;

  StorageService() {
    _filesBox = Hive.box<CodeFile>(AppConstants.boxFiles);
    _presetsBox = Hive.box<CompilerPreset>(AppConstants.boxPresets);
    _settingsBox = Hive.box(AppConstants.boxSettings);
  }

  // Files
  Future<List<CodeFile>> getAllFiles() async {
    if (_filesBox.isEmpty) {
      // Create default file if empty
      final defaultFile = CodeFile(
        name: 'main.dart',
        content: AppConstants.initialCode,
      );
      await _filesBox.add(defaultFile);
      return [defaultFile];
    }
    return _filesBox.values.toList();
  }

  Future<void> saveFile(CodeFile file) async {
    if (file.isInBox) {
      await file.save();
    } else {
      await _filesBox.add(file);
    }
  }

  Future<void> deleteFile(CodeFile file) async {
    if (file.isInBox) {
      await file.delete();
    }
  }

  // Presets
  List<CompilerPreset> getAllPresets() {
    return _presetsBox.values.toList();
  }

  Future<void> savePreset(CompilerPreset preset) async {
    if (preset.isInBox) {
      await preset.save();
    } else {
      await _presetsBox.add(preset);
    }
  }

  Future<void> deletePreset(CompilerPreset preset) async {
    if (preset.isInBox) {
      await preset.delete();
    }
  }

  // Settings
  String? get activeFileId => _settingsBox.get(AppConstants.keyActiveFileId);
  Future<void> setActiveFileId(String id) => _settingsBox.put(AppConstants.keyActiveFileId, id);

  String? get activePresetId => _settingsBox.get(AppConstants.keyActivePresetId);
  Future<void> setActivePresetId(String id) => _settingsBox.put(AppConstants.keyActivePresetId, id);

  bool get useCustomPreset => _settingsBox.get(AppConstants.keyUseCustomPreset, defaultValue: false);
  Future<void> setUseCustomPreset(bool value) => _settingsBox.put(AppConstants.keyUseCustomPreset, value);
}
