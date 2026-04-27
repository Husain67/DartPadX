import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

class SettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  SettingsState({required this.presets, required this.activePresetId});

  SettingsState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }

  CompilerPreset? get activePreset {
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return presets.isNotEmpty ? presets.first : null;
    }
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Box<CompilerPreset> _box = Hive.box<CompilerPreset>('presets');
  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  SettingsNotifier(this._prefs) : super(SettingsState(presets: [], activePresetId: '')) {
    _initPresets();
  }

  void _initPresets() {
    List<CompilerPreset> presets = _box.values.toList();
    if (presets.isEmpty) {
      final defaultPreset = CompilerPreset(
        id: 'onecompiler_default',
        name: 'OneCompiler (Default)',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'X-RapidAPI-Key',
        authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        queryParams: {},
        bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isReadOnly: true,
      );

      final blankPreset = CompilerPreset(
        id: _uuid.v4(),
        name: 'Blank Custom API',
        endpointUrl: '',
        method: 'POST',
        authType: 'None',
        authKey: '',
        authValue: '',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
        isReadOnly: false,
      );

      _box.put(defaultPreset.id, defaultPreset);
      _box.put(blankPreset.id, blankPreset);
      presets = [defaultPreset, blankPreset];
    }

    final savedActiveId = _prefs.getString('activePresetId') ?? 'onecompiler_default';
    state = SettingsState(presets: presets, activePresetId: savedActiveId);
  }

  void setActivePreset(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final updatedPresets = _box.values.toList();
    state = state.copyWith(presets: updatedPresets);
  }

  void deletePreset(String id) {
    if (id == 'onecompiler_default') return; // Cannot delete default
    _box.delete(id);
    final updatedPresets = _box.values.toList();
    String nextId = state.activePresetId;
    if (state.activePresetId == id) {
       nextId = 'onecompiler_default';
       _prefs.setString('activePresetId', nextId);
    }
    state = state.copyWith(presets: updatedPresets, activePresetId: nextId);
  }

  void duplicatePreset(String id) {
     final presetToDuplicate = state.presets.firstWhere((p) => p.id == id);
     final newPreset = presetToDuplicate.copyWith(
       id: _uuid.v4(),
       name: '${presetToDuplicate.name} (Copy)',
       isReadOnly: false,
     );
     savePreset(newPreset);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});
