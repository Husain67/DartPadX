import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/preset_model.dart';
import '../utils/hive_helper.dart';

class CompilerState {
  final List<PresetModel> presets;
  final PresetModel? activePreset;
  final bool useDefaultCompiler;

  CompilerState({
    required this.presets,
    this.activePreset,
    this.useDefaultCompiler = true,
  });

  CompilerState copyWith({
    List<PresetModel>? presets,
    PresetModel? activePreset,
    bool? useDefaultCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePreset: activePreset ?? this.activePreset,
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  void _loadPresets() {
    final box = HiveHelper.presetBox;
    if (box.isEmpty) {
      _seedDefaultPresets(box);
    }
    final items = box.values.toList();
    final defaultPreset = items.where((p) => p.isDefault).firstOrNull ?? (items.isNotEmpty ? items.first : null);

    state = CompilerState(
      presets: items,
      activePreset: defaultPreset,
      useDefaultCompiler: true, // as per requirements default is OneCompiler
    );
  }

  void _seedDefaultPresets(Box<PresetModel> box) {
    final seedPresets = [
      PresetModel(
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': 'YOUR_KEY_HERE',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isDefault: true,
      ),
      PresetModel(
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None', // Sent in body
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      PresetModel(
        name: 'Piston',
        endpointUrl: 'https://emacs.piston.rs/api/v2/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [{"content": "{code}"}],\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'run.error',
        executionTimePath: '',
        memoryPath: '',
      ),
      PresetModel(
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/execute',
        httpMethod: 'POST',
        authType: 'Bearer Token',
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer YOUR_TOKEN'},
        queryParams: {},
        requestBodyTemplate: '{\n  "code": "{code}",\n  "language": "dart",\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      PresetModel(
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        requestBodyTemplate: '{\n  "code": "{code}",\n  "language": "dart",\n  "input": "{stdin}"\n}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: '',
        memoryPath: '',
      ),
      PresetModel(
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {'Content-Type': 'application/json', 'client-secret': 'YOUR_SECRET'},
        queryParams: {},
        requestBodyTemplate: '{\n  "source": "{code}",\n  "lang": "DART",\n  "input": "{stdin}",\n  "memory_limit": 262144,\n  "time_limit": 5\n}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        errorPath: 'result.compile_status',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
      ),
      PresetModel(
        name: 'Blank',
        endpointUrl: '',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        requestBodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      ),
    ];

    for (var preset in seedPresets) {
      box.put(preset.id, preset);
    }
  }

  void toggleUseDefault(bool val) {
    state = state.copyWith(useDefaultCompiler: val);
  }

  void setActivePreset(PresetModel preset) {
    state = state.copyWith(activePreset: preset);
  }

  void addOrUpdatePreset(PresetModel preset) {
    HiveHelper.presetBox.put(preset.id, preset);
    final items = HiveHelper.presetBox.values.toList();
    state = state.copyWith(presets: items, activePreset: preset);
  }

  void deletePreset(String id) {
    HiveHelper.presetBox.delete(id);
    final items = HiveHelper.presetBox.values.toList();
    state = state.copyWith(
      presets: items,
      activePreset: state.activePreset?.id == id ? (items.isNotEmpty ? items.first : null) : state.activePreset,
    );
  }

  void setAsDefault(String id) {
    final items = state.presets;
    for (var p in items) {
      final updated = p.copyWith(isDefault: p.id == id);
      HiveHelper.presetBox.put(updated.id, updated);
    }
    state = state.copyWith(presets: HiveHelper.presetBox.values.toList());
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
