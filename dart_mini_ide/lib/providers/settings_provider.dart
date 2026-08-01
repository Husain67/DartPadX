import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useOneCompiler;
  final String activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    required this.useOneCompiler,
    required this.activePresetId,
    required this.presets,
  });

  CompilerPreset? get activePreset => presets.isNotEmpty
    ? presets.firstWhere((p) => p.id == activePresetId, orElse: () => presets.first)
    : null;

  SettingsState copyWith({
    bool? useOneCompiler,
    String? activePresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useOneCompiler: useOneCompiler ?? this.useOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  late SharedPreferences _prefs;
  late Box<CompilerPreset> _box;

  SettingsNotifier() : super(SettingsState(useOneCompiler: true, activePresetId: '', presets: [])) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _box = Hive.box<CompilerPreset>('compilerPresets');

    bool useOne = _prefs.getBool('useOneCompiler') ?? true;
    String activeId = _prefs.getString('activePresetId') ?? '';

    List<CompilerPreset> loadedPresets = _box.values.toList();

    // Load some defaults if empty
    if (loadedPresets.isEmpty) {
      final defaultPresets = [
        CompilerPreset(
          id: 'jdoodle_dart',
          name: 'JDoodle',
          url: 'https://api.jdoodle.com/v1/execute',
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"clientId": "YOUR_CLIENT_ID","clientSecret": "YOUR_CLIENT_SECRET","script": "{code}","language": "dart","versionIndex": "0"}',
          stdoutPath: 'output',
          stderrPath: 'error',
          executionTimePath: 'cpuTime',
          memoryPath: 'memory',
        ),
        CompilerPreset(
          id: 'piston_dart',
          name: 'Piston',
          url: 'https://emacs.ch/piston/api/v2/execute',
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"language": "dart", "version": "2.19.6", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'compile.stderr',
        ),
        CompilerPreset(
          id: 'replit_dart',
          name: 'Replit (Example)',
          url: 'https://your-replit-endpoint.com/run',
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"code": "{code}"}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
        ),
        CompilerPreset(
          id: 'codex_dart',
          name: 'CodeX',
          url: 'https://api.codex.jaagrav.in',
          method: 'POST',
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          bodyTemplate: 'code={code}&language=dart&input={stdin}',
          stdoutPath: 'output',
          stderrPath: 'error',
        ),
        CompilerPreset(
          id: 'hackerearth_dart',
          name: 'HackerEarth (V4)',
          url: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
          method: 'POST',
          headers: {'client-secret': 'YOUR_CLIENT_SECRET', 'Content-Type': 'application/json'},
          bodyTemplate: '{"source": "{code}", "lang": "DART", "input": "{stdin}", "time_limit": 5, "memory_limit": 262144}',
          stdoutPath: 'result.run_status.output',
          stderrPath: 'result.run_status.stderr',
          executionTimePath: 'result.run_status.time_used',
          memoryPath: 'result.run_status.memory_used',
        ),
        CompilerPreset(
          id: 'blank_preset',
          name: 'Blank Preset',
          url: '',
          method: 'POST',
          headers: {},
          bodyTemplate: '',
        ),
      ];

      for (var p in defaultPresets) {
        _box.put(p.id, p);
      }
      loadedPresets = defaultPresets;
      if (activeId.isEmpty) activeId = defaultPresets.first.id;
    }

    state = SettingsState(
      useOneCompiler: useOne,
      activePresetId: activeId,
      presets: loadedPresets,
    );
  }

  void toggleUseOneCompiler(bool value) {
    _prefs.setBool('useOneCompiler', value);
    state = state.copyWith(useOneCompiler: value);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList()
    );
  }

  void removePreset(String id) {
    _box.delete(id);
    state = state.copyWith(
      presets: state.presets.where((p) => p.id != id).toList()
    );
  }

  void duplicatePreset(String id) {
    final preset = state.presets.firstWhere((p) => p.id == id);
    final newPreset = preset.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${preset.name} (Copy)',
    );
    addPreset(newPreset);
  }

  String exportPresets() {
    final list = state.presets.map((p) => {
      'id': p.id,
      'name': p.name,
      'url': p.url,
      'method': p.method,
      'authType': p.authType,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'bodyTemplate': p.bodyTemplate,
      'stdoutPath': p.stdoutPath,
      'stderrPath': p.stderrPath,
      'errorPath': p.errorPath,
      'executionTimePath': p.executionTimePath,
      'memoryPath': p.memoryPath,
    }).toList();
    return jsonEncode(list);
  }

  void importPresets(String jsonStr) {
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      for (var item in list) {
        final preset = CompilerPreset(
          id: item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: item['name'] ?? 'Imported Preset',
          url: item['url'] ?? '',
          method: item['method'] ?? 'POST',
          authType: item['authType'] ?? 'None',
          headers: Map<String, String>.from(item['headers'] ?? {}),
          queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
          bodyTemplate: item['bodyTemplate'] ?? '',
          stdoutPath: item['stdoutPath'] ?? '',
          stderrPath: item['stderrPath'] ?? '',
          errorPath: item['errorPath'] ?? '',
          executionTimePath: item['executionTimePath'] ?? '',
          memoryPath: item['memoryPath'] ?? '',
        );
        addPreset(preset);
      }
    } catch (e) {
      // Ignored for simplicity
    }
  }
}
