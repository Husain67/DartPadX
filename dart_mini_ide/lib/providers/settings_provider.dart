import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultCompiler;
  final String? activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    required this.useDefaultCompiler,
    this.activePresetId,
    required this.presets,
  });

  SettingsState copyWith({
    bool? useDefaultCompiler,
    String? activePresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(useDefaultCompiler: true, presets: [])) {
    _loadSettings();
  }

  static const String _defaultCompilerKey = 'use_default_compiler';
  static const String _activePresetIdKey = 'active_preset_id';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useDefault = prefs.getBool(_defaultCompilerKey) ?? true;
    final activeId = prefs.getString(_activePresetIdKey);

    final box = Hive.box<CompilerPreset>('presetsBox');
    if (box.isEmpty) {
      _initDefaultPresets(box);
    }

    state = state.copyWith(
      useDefaultCompiler: useDefault,
      activePresetId: activeId,
      presets: box.values.toList(),
    );
  }

  void _initDefaultPresets(Box<CompilerPreset> box) {
    final defaultPresets = [
      CompilerPreset(
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: AuthType.apiKeyHeader,
        headers: {
          'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
          'x-rapidapi-key': 'YOUR_RAPID_API_KEY', // Requires user to supply
          'Content-Type': 'application/json',
        },
        requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": {code}}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isReadOnly: false,
      ),
      CompilerPreset(
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: AuthType.none,
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"script": {code}, "language": "dart", "versionIndex": "0", "clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET"}',
        stdoutPath: 'output',
        stderrPath: '',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isReadOnly: false,
      ),
      // ... Add Piston, Replit, CodeX, HackerEarth, Blank ...
    ];

    for (var preset in defaultPresets) {
      box.put(preset.id, preset);
    }
  }

  Future<void> toggleDefaultCompiler(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_defaultCompilerKey, value);
    state = state.copyWith(useDefaultCompiler: value);
  }

  Future<void> setActivePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePresetIdKey, id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    final box = Hive.box<CompilerPreset>('presetsBox');
    box.put(preset.id, preset);
    state = state.copyWith(presets: box.values.toList());
  }

  void updatePreset(CompilerPreset preset) {
    final box = Hive.box<CompilerPreset>('presetsBox');
    box.put(preset.id, preset);
    state = state.copyWith(presets: box.values.toList());
  }

  void deletePreset(String id) {
    final box = Hive.box<CompilerPreset>('presetsBox');
    box.delete(id);
    final presets = box.values.toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
       newActiveId = presets.isNotEmpty ? presets.first.id : null;
       setActivePreset(newActiveId ?? '');
    }
    state = state.copyWith(presets: presets, activePresetId: newActiveId);
  }
}
