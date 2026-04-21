import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import 'settings_provider.dart';

final compilerPresetProvider = StateNotifierProvider<CompilerPresetNotifier, List<CompilerPreset>>((ref) {
  return CompilerPresetNotifier();
});

final activePresetIdProvider = StateNotifierProvider<ActivePresetNotifier, String?>((ref) {
  return ActivePresetNotifier(ref.watch(sharedPreferencesProvider));
});

class ActivePresetNotifier extends StateNotifier<String?> {
  void set(String id) => state = id;
  final prefs;
  ActivePresetNotifier(this.prefs) : super(prefs.getString('activePresetId')) {
    addListener((state) {
      if (state != null) {
        prefs.setString('activePresetId', state);
      } else {
        prefs.remove('activePresetId');
      }
    });
  }
}

class CompilerPresetNotifier extends StateNotifier<List<CompilerPreset>> {
  late Box<CompilerPreset> _box;
  final _uuid = const Uuid();

  CompilerPresetNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CompilerPreset>('compiler_presets');
    if (_box.isEmpty) {
      _loadDefaultPresets();
    } else {
      state = _box.values.toList();
    }
  }

  void _loadDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: _uuid.v4(),
        name: 'OneCompiler',
        url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: [
          const MapEntry('X-RapidAPI-Key', 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
          const MapEntry('X-RapidAPI-Host', 'onecompiler-apis.p.rapidapi.com'),
          const MapEntry('Content-Type', 'application/json')
        ],
        queryParams: [],
        bodyTemplate: '{"language": "{language}", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": {code}}]}',
        responseMappings: {
          'stdout': 'stdout',
          'stderr': 'stderr',
          'error': 'exception',
          'executionTime': 'executionTime',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'JDoodle',
        url: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: [const MapEntry('Content-Type', 'application/json')],
        queryParams: [],
        bodyTemplate: '{"script": {code}, "language": "dart", "versionIndex": "0", "clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET"}',
        responseMappings: {
          'stdout': 'output',
          'stderr': '',
          'error': 'error',
          'executionTime': 'cpuTime',
          'memory': 'memory'
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Piston',
        url: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: [const MapEntry('Content-Type', 'application/json')],
        queryParams: [],
        bodyTemplate: '{"language": "{language}", "version": "*", "files": [{"content": {code}}], "stdin": "{stdin}"}',
        responseMappings: {
          'stdout': 'run.stdout',
          'stderr': 'run.stderr',
          'error': '',
          'executionTime': '',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Replit',
        url: 'https://replit.com/api/v1/execute',
        method: 'POST',
        authType: 'Bearer Token',
        authValue: 'YOUR_TOKEN',
        headers: [const MapEntry('Content-Type', 'application/json')],
        queryParams: [],
        bodyTemplate: '{"language": "dart", "code": {code}}',
        responseMappings: {
          'stdout': 'stdout',
          'stderr': 'stderr',
          'error': 'error',
          'executionTime': 'time',
          'memory': 'memory'
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'CodeX',
        url: 'https://api.codex.jaagrav.in',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: [const MapEntry('Content-Type', 'application/json')],
        queryParams: [],
        bodyTemplate: '{"code": {code}, "language": "dart", "input": "{stdin}"}',
        responseMappings: {
          'stdout': 'output',
          'stderr': 'error',
          'error': '',
          'executionTime': 'time',
          'memory': ''
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'HackerEarth',
        url: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        method: 'POST',
        authType: 'API-Key Header',
        authValue: 'YOUR_SECRET',
        headers: [const MapEntry('client-secret', 'YOUR_SECRET'), const MapEntry('Content-Type', 'application/json')],
        queryParams: [],
        bodyTemplate: '{"source": {code}, "lang": "DART", "input": "{stdin}"}',
        responseMappings: {
          'stdout': 'result.run_status.output',
          'stderr': 'result.run_status.stderr',
          'error': 'result.compile_status',
          'executionTime': 'result.run_status.time_used',
          'memory': 'result.run_status.memory_used'
        },
      ),
      CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank',
        url: 'https://api.example.com/execute',
        method: 'POST',
        authType: 'None',
        authValue: '',
        headers: [],
        queryParams: [],
        bodyTemplate: '{}',
        responseMappings: {},
      ),
    ];
    for (final p in defaultPresets) {
      _box.put(p.id, p);
    }
    state = _box.values.toList();
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = [...state, preset];
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = [for (final p in state) if (p.id == preset.id) preset else p];
  }

  void deletePreset(String id) {
    _box.delete(id);
    state = state.where((p) => p.id != id).toList();
  }

  void duplicatePreset(CompilerPreset preset) {
    final newId = const Uuid().v4();
    final newPreset = preset.copyWith(id: newId, name: '${preset.name} (Copy)');
    addPreset(newPreset);
  }

  String exportPresets() {
    final list = state.map((p) => {
      'id': p.id,
      'name': p.name,
      'url': p.url,
      'method': p.method,
      'authType': p.authType,
      'authValue': p.authValue,
      'headers': p.headers.map((e) => {'k': e.key, 'v': e.value}).toList(),
      'queryParams': p.queryParams.map((e) => {'k': e.key, 'v': e.value}).toList(),
      'bodyTemplate': p.bodyTemplate,
      'responseMappings': p.responseMappings,
    }).toList();
    return jsonEncode(list);
  }

  void importPresets(String jsonStr) {
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      for (final item in list) {
        final headersList = (item['headers'] as List).map((e) => MapEntry<String, String>(e['k'], e['v'])).toList();
        final queryParamsList = (item['queryParams'] as List).map((e) => MapEntry<String, String>(e['k'], e['v'])).toList();
        final preset = CompilerPreset(
          id: const Uuid().v4(),
          name: item['name'],
          url: item['url'],
          method: item['method'],
          authType: item['authType'],
          authValue: item['authValue'],
          headers: headersList,
          queryParams: queryParamsList,
          bodyTemplate: item['bodyTemplate'],
          responseMappings: Map<String, String>.from(item['responseMappings']),
        );
        addPreset(preset);
      }
    } catch (e) {
      // ignore
    }
  }
}
