import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/compiler_preset.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool isReady;

  SettingsState({
    required this.presets,
    required this.activePresetId,
    this.isReady = false,
  });

  CompilerPreset get activePreset {
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return CompilerPreset.oneCompilerDefault;
    }
  }

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? isReady,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      isReady: isReady ?? this.isReady,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  Future<void> exportPresets() async {

    // The actual exporting logic is best handled in the UI with path_provider/Clipboard
    // We can just return it.
    return;
  }

  String exportPresetsJson() {
    return jsonEncode(state.presets.map((p) => p.toJson()).toList());
  }

  Future<void> importPresetsJson(String jsonString) async {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      for (var item in list) {
        final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
        await _presetBox.put(preset.id, preset);
      }
      state = state.copyWith(presets: _presetBox.values.toList());
      Fluttertoast.showToast(msg: "Imported ${list.length} presets successfully.");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to import presets: Invalid JSON");
    }
  }

  SettingsNotifier() : super(SettingsState(presets: [], activePresetId: '')) {
    _init();
  }

  late Box<CompilerPreset> _presetBox;
  late Box _prefsBox;

  Future<void> _init() async {
    _presetBox = Hive.box<CompilerPreset>('presets');
    _prefsBox = Hive.box('prefs');

    var storedPresets = _presetBox.values.toList();
    if (storedPresets.isEmpty) {
      for (final p in CompilerPreset.defaultPresets) {
        await _presetBox.put(p.id, p);
        storedPresets.add(p);
      }
    }

    final activeId = _prefsBox.get('activePresetId', defaultValue: CompilerPreset.oneCompilerDefault.id);

    state = state.copyWith(
      presets: storedPresets,
      activePresetId: activeId,
      isReady: true,
    );
  }

  Future<void> setActivePreset(String id) async {
    await _prefsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  Future<void> savePreset(CompilerPreset preset) async {
    await _presetBox.put(preset.id, preset);
    final updated = _presetBox.values.toList();
    state = state.copyWith(presets: updated);
  }

  Future<void> deletePreset(String id) async {
    if (id == CompilerPreset.oneCompilerDefault.id) return; // Cannot delete default
    await _presetBox.delete(id);
    final updated = _presetBox.values.toList();

    if (state.activePresetId == id) {
      await setActivePreset(CompilerPreset.oneCompilerDefault.id);
    }

    state = state.copyWith(presets: updated);
  }
}
