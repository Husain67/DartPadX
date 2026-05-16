import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../main.dart'; // for sharedPreferences
import '../models/compiler_preset.dart';

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  return PresetNotifier();
});

class PresetState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefaultOneCompiler;

  PresetState({
    required this.presets,
    required this.activePresetId,
    required this.useDefaultOneCompiler,
  });

  PresetState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  late Box<CompilerPreset> _box;
  final _uuid = const Uuid();

  PresetNotifier()
      : super(PresetState(
          presets: [],
          activePresetId: '',
          useDefaultOneCompiler: sharedPreferences.getBool('useDefaultOneCompiler') ?? true,
        )) {
    _box = Hive.box<CompilerPreset>('presets');
    _loadPresets();
  }

  void _loadPresets() {
    if (_box.isEmpty) {
      _loadDefaults();
    } else {
      final presets = _box.values.toList();
      String activeId = sharedPreferences.getString('activePresetId') ?? '';
      if (activeId.isEmpty && presets.isNotEmpty) {
        activeId = presets.first.id;
      }
      state = state.copyWith(presets: presets, activePresetId: activeId);
    }
  }

  void _loadDefaults() {
    final defaultPresets = [
      CompilerPreset(
        id: 'default_onecompiler',
        name: 'OneCompiler (Default)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM=')),
        headers: {
          'X-RapidAPI-Key': String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM=')),
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          'Content-Type': 'application/json'
        },
        queryParams: {},
        bodyTemplate: '''{
  "language": "dart",
  "stdin": "{stdin}",
  "files": [
    {
      "name": "main.dart",
      "content": "{code}"
    }
  ]
}''',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'piston',
        name: 'Piston (EngineMan)',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '''{
  "language": "dart",
  "version": "3.3.3",
  "files": [
    {
      "content": "{code}"
    }
  ],
  "stdin": "{stdin}"
}''',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'jdoodle',
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '''{
  "script": "{code}",
  "language": "dart",
  "versionIndex": "0",
  "clientId": "YOUR_CLIENT_ID",
  "clientSecret": "YOUR_CLIENT_SECRET"
}''',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'replit',
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '''{
  "language": "dart",
  "code": "{code}"
}''',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'codex',
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '''{
  "code": "{code}",
  "language": "dart",
  "input": "{stdin}"
}''',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'hackerearth',
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        authValue: '',
        headers: {
            'client-secret': 'YOUR_CLIENT_SECRET',
            'Content-Type': 'application/json'
        },
        queryParams: {},
        bodyTemplate: '''{
  "source": "{code}",
  "lang": "DART",
  "input": "{stdin}",
  "time_limit": 5,
  "memory_limit": 262144
}''',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'result.compile_status',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
        isPreloaded: true,
      ),
      CompilerPreset(
        id: 'blank',
        name: 'Blank Template',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{"code": "{code}"}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
        isPreloaded: true,
      ),
];

    for (var preset in defaultPresets) {
      _box.put(preset.id, preset);
    }

    state = state.copyWith(
      presets: defaultPresets,
      activePresetId: 'default_onecompiler',
    );
    sharedPreferences.setString('activePresetId', 'default_onecompiler');
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  void deletePreset(String id) {
    if (state.presets.firstWhere((p) => p.id == id).isPreloaded) return;
    _box.delete(id);

    final newPresets = _box.values.toList();
    String newActiveId = state.activePresetId;
    if (state.activePresetId == id) {
      newActiveId = newPresets.isNotEmpty ? newPresets.first.id : '';
      sharedPreferences.setString('activePresetId', newActiveId);
    }

    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  void duplicatePreset(String id) {
    final preset = state.presets.firstWhere((p) => p.id == id);
    final newPreset = preset.copyWith(
      id: _uuid.v4(),
      name: '${preset.name} (Copy)',
      isPreloaded: false,
    );
    addPreset(newPreset);
  }

  void setActivePreset(String id) {
    sharedPreferences.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void toggleUseDefaultOneCompiler(bool useDefault) {
    sharedPreferences.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  CompilerPreset? get activePreset {
    if (state.useDefaultOneCompiler) {
      return state.presets.firstWhere(
        (p) => p.id == 'default_onecompiler',
        orElse: () => state.presets.first,
      );
    }
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (e) {
      return state.presets.isNotEmpty ? state.presets.first : null;
    }
  }

  String exportPresets() {
    final customPresets = state.presets.where((p) => !p.isPreloaded).map((p) => p.toJson()).toList();
    return jsonEncode(customPresets);
  }

  void importPresets(String jsonString) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      for (var item in decoded) {
        final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
        // Ensure new ID to avoid conflicts
        final newPreset = preset.copyWith(id: _uuid.v4(), isPreloaded: false);
        _box.put(newPreset.id, newPreset);
      }
      state = state.copyWith(presets: _box.values.toList());
    } catch (e) {
      // Ignored for now, UI should handle error via toast
    }
  }
}
