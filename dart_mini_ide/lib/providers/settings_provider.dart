import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';


class SettingsState {
  final bool useOneCompiler;
  final List<CompilerPreset> customPresets;
  final String? activePresetId;

  SettingsState({
    this.useOneCompiler = true,
    this.customPresets = const [],
    this.activePresetId,
  });

  SettingsState copyWith({
    bool? useOneCompiler,
    List<CompilerPreset>? customPresets,
    String? activePresetId,
  }) {
    return SettingsState(
      useOneCompiler: useOneCompiler ?? this.useOneCompiler,
      customPresets: customPresets ?? this.customPresets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useOneCompiler = prefs.getBool('useOneCompiler') ?? true;
    final activePresetId = prefs.getString('activePresetId');

    final box = Hive.box<CompilerPreset>('compiler_presets');
    List<CompilerPreset> presets = box.values.toList();

    if (presets.isEmpty) {
      presets = _getPreloadedPresets();
      for (var p in presets) {
        await box.put(p.id, p);
      }
    }

    state = state.copyWith(
      useOneCompiler: useOneCompiler,
      customPresets: presets,
      activePresetId: activePresetId ?? (presets.isNotEmpty ? presets.first.id : null),
    );
  }

  List<CompilerPreset> _getPreloadedPresets() {
    return [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle (Dart)',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": {code}, "language": "dart", "versionIndex": "0"}',
        responseStdoutPath: 'output',
        responseStderrPath: 'error',
        responseTimePath: 'cpuTime',
        responseMemoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpoint: 'https://emacs.piston.rs/api/v2/execute',
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        bodyTemplate: '{"language": "dart", "version": "3.3.0", "files": [{"name": "main.dart", "content": {code}}]}',
        responseStdoutPath: 'run.stdout',
        responseStderrPath: 'run.stderr',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpoint: 'https://example.com/api',
      ),
    ];
  }

  void setUseOneCompiler(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useOneCompiler', value);
    state = state.copyWith(useOneCompiler: value);
  }

  void setActivePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) async {
    final box = Hive.box<CompilerPreset>('compiler_presets');
    await box.put(preset.id, preset);
    state = state.copyWith(customPresets: box.values.toList());
  }

  void updatePreset(CompilerPreset preset) async {
    final box = Hive.box<CompilerPreset>('compiler_presets');
    await box.put(preset.id, preset);
    state = state.copyWith(customPresets: box.values.toList());
  }

  void deletePreset(String id) async {
    final box = Hive.box<CompilerPreset>('compiler_presets');
    await box.delete(id);
    final presets = box.values.toList();
    final activeId = state.activePresetId == id ? (presets.isNotEmpty ? presets.first.id : null) : state.activePresetId;
    state = state.copyWith(customPresets: presets, activePresetId: activeId);
  }

  void duplicatePreset(CompilerPreset preset) async {
    final newPreset = preset.copyWith(
      id: const Uuid().v4(),
      name: '${preset.name} (Copy)'
    );
    addPreset(newPreset);
  }

  Future<void> exportPresets() async {
    final presetsJson = state.customPresets.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(presetsJson);
    final file = File('${Directory.systemTemp.path}/presets_export.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'DartMini IDE Compiler Presets');
  }

  Future<void> importPresets() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      try {
        List<dynamic> parsed = jsonDecode(content);
        for (var item in parsed) {
          final preset = CompilerPreset.fromJson(item).copyWith(id: const Uuid().v4());
          addPreset(preset);
        }
      } catch (e) {
        // Handle error (ignored in this setup for simplicity, could show toast)
      }
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
