import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/preset_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PresetState {
  final List<PresetModel> presets;
  final String? activePresetId;
  final bool useOneCompiler; // true if using default OneCompiler, false if using a custom preset

  PresetState({
    required this.presets,
    this.activePresetId,
    this.useOneCompiler = true,
  });

  PresetState copyWith({
    List<PresetModel>? presets,
    String? activePresetId,
    bool? useOneCompiler,
  }) {
    return PresetState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useOneCompiler: useOneCompiler ?? this.useOneCompiler,
    );
  }
}

class PresetNotifier extends StateNotifier<PresetState> {
  final Box<PresetModel> _box;
  final SharedPreferences _prefs;

  PresetNotifier(this._box, this._prefs) : super(PresetState(presets: _box.values.toList())) {
    _loadState();
  }

  PresetState get currentState => state;

  void _loadState() {
    final activeId = _prefs.getString('activePresetId');
    final useOneCompiler = _prefs.getBool('useOneCompiler') ?? true;

    if (state.presets.isEmpty) {
      _loadDefaultPresets();
    } else {
      state = state.copyWith(
        activePresetId: activeId ?? (state.presets.isNotEmpty ? state.presets.first.id : null),
        useOneCompiler: useOneCompiler,
      );
    }
  }

  void _loadDefaultPresets() {
    final jdoodle = PresetModel(
      name: 'JDoodle',
      url: 'https://api.jdoodle.com/v1/execute',
      method: 'POST',
      bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}',
      responseMappings: {'stdout': 'output', 'stderr': 'error', 'executionTime': 'cpuTime', 'memory': 'memory'},
    );
    final piston = PresetModel(
      name: 'Piston',
      url: 'https://emacs.ranna.dev/api/v2/execute', // Example Piston endpoint
      method: 'POST',
      bodyTemplate: '{"language": "dart", "version": "3.1.0", "files": [{"content": "{code}"}]}',
      responseMappings: {'stdout': 'run.stdout', 'stderr': 'run.stderr'},
    );
    final replit = PresetModel(
      name: 'Replit',
      url: 'https://replit.com/api/v1/...', // Placeholder
      method: 'POST',
      bodyTemplate: '{"code": "{code}"}',
    );
    final codex = PresetModel(
      name: 'CodeX',
      url: 'https://api.codex.jaagrav.in',
      method: 'POST',
      bodyTemplate: '{"code": "{code}", "language": "dart"}',
      responseMappings: {'stdout': 'output', 'stderr': 'error'},
    );
    final hackerearth = PresetModel(
      name: 'HackerEarth',
      url: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
      method: 'POST',
      headers: {'client-secret': 'YOUR_CLIENT_SECRET'},
      bodyTemplate: '{"source": "{code}", "lang": "DART"}',
    );
    final blank = PresetModel(
      name: 'Blank',
      url: '',
      method: 'POST',
    );

    for (var p in [jdoodle, piston, replit, codex, hackerearth, blank]) {
      _box.put(p.id, p);
    }

    state = PresetState(
      presets: [jdoodle, piston, replit, codex, hackerearth, blank],
      activePresetId: jdoodle.id,
      useOneCompiler: true,
    );
    _prefs.setString('activePresetId', jdoodle.id);
    _prefs.setBool('useOneCompiler', true);
  }

  void addPreset(PresetModel preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(PresetModel preset) {
    _box.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final newPresets = List<PresetModel>.from(state.presets);
      newPresets[index] = preset;
      state = state.copyWith(presets: newPresets);
    }
  }

  void deletePreset(String id) {
    _box.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = newPresets.isNotEmpty ? newPresets.first.id : null;
      _prefs.setString('activePresetId', newActiveId ?? '');
    }
    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    _prefs.setBool('useOneCompiler', false);
    state = state.copyWith(activePresetId: id, useOneCompiler: false);
  }

  void setUseOneCompiler(bool use) {
    _prefs.setBool('useOneCompiler', use);
    state = state.copyWith(useOneCompiler: use);
  }

  PresetModel? get activePreset {
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (e) {
      return null;
    }
  }
}

final presetBoxProvider = Provider<Box<PresetModel>>((ref) => throw UnimplementedError());
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final presetProvider = StateNotifierProvider<PresetNotifier, PresetState>((ref) {
  final box = ref.watch(presetBoxProvider);
  final prefs = ref.watch(sharedPrefsProvider);
  return PresetNotifier(box, prefs);
});
