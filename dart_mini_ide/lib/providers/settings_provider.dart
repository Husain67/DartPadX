import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compiler_preset.dart';

class SettingsState {
  final List<CompilerPreset> presets;
  final CompilerPreset selectedPreset;

  SettingsState({required this.presets, required this.selectedPreset});
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Box<CompilerPreset> _box;

  static final CompilerPreset _defaultPreset = CompilerPreset(
    name: 'OneCompiler',
    platform: 'OneCompiler',
    endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
    method: 'POST',
    authType: 'API-Key Header',
    headers: {
      'content-type': 'application/json',
      'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
      'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
    },
    bodyTemplate: '{"language": "{language}", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
    responseMapping: {
      'stdout': 'stdout',
      'stderr': 'stderr',
      'error': 'exception',
      'executionTime': 'executionTime',
    },
  );

  SettingsNotifier(this._box) : super(SettingsState(presets: [], selectedPreset: _defaultPreset)) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if default exists in box
    if (_box.isEmpty) {
      await _box.add(_defaultPreset);
    } else {
       // Ensure OneCompiler is always available or updated if needed?
       // For now, assume if box has items, we are good.
       // But if user deleted OneCompiler? Maybe we should restore it or prevent deletion.
    }

    final presets = _box.values.toList();
    final selectedName = prefs.getString('selected_preset') ?? 'OneCompiler';

    final selected = presets.firstWhere(
      (p) => p.name == selectedName,
      orElse: () => presets.isNotEmpty ? presets.first : _defaultPreset,
    );

    state = SettingsState(presets: presets, selectedPreset: selected);
  }

  Future<void> selectPreset(CompilerPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_preset', preset.name);
    state = SettingsState(presets: state.presets, selectedPreset: preset);
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _box.add(preset);
    // Refresh list from box to be sure
    state = SettingsState(presets: _box.values.toList(), selectedPreset: state.selectedPreset);
  }

  Future<void> deletePreset(CompilerPreset preset) async {
    if (preset.name == 'OneCompiler') return; // Protect default

    await preset.delete();
    final presets = _box.values.toList();

    // If deleted was selected, switch to default
    CompilerPreset nextSelected = state.selectedPreset;
    if (state.selectedPreset == preset || state.selectedPreset.key == preset.key) {
      nextSelected = presets.firstWhere((p) => p.name == 'OneCompiler', orElse: () => presets.first);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_preset', nextSelected.name);
    }

    state = SettingsState(presets: presets, selectedPreset: nextSelected);
  }

  Future<void> updatePreset(CompilerPreset oldPreset, CompilerPreset newPreset) async {
     // If HiveObject, we can save() it, but here we are replacing logic potentially.
     // newPreset is likely a copy.
     // If we are editing, we should copy properties to oldPreset and save.

     // Finding the object in box corresponding to oldPreset
     final key = oldPreset.key;
     if (key != null) {
       await _box.put(key, newPreset);
     } else {
       // fallback
       await _box.add(newPreset);
     }

     state = SettingsState(presets: _box.values.toList(), selectedPreset: state.selectedPreset.name == oldPreset.name ? newPreset : state.selectedPreset);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final box = Hive.box<CompilerPreset>('compiler_presets');
  return SettingsNotifier(box);
});
