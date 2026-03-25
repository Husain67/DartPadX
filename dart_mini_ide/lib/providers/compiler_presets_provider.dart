import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/compiler_preset.dart';
import '../utils/constants.dart';

final compilerPresetsProvider =
    StateNotifierProvider<CompilerPresetsNotifier, CompilerPresetsState>((ref) {
  return CompilerPresetsNotifier();
});

class CompilerPresetsState {
  final List<CompilerPreset> presets;
  final String? selectedPresetId;
  final bool useDefault;

  CompilerPresetsState({
    required this.presets,
    this.selectedPresetId,
    this.useDefault = true,
  });

  CompilerPresetsState copyWith({
    List<CompilerPreset>? presets,
    String? selectedPresetId,
    bool? useDefault,
  }) {
    return CompilerPresetsState(
      presets: presets ?? this.presets,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
      useDefault: useDefault ?? this.useDefault,
    );
  }

  CompilerPreset? get activePreset {
    if (useDefault) {
      return AppConstants.defaultPresets.first;
    }
    if (selectedPresetId == null) return null;
    try {
      return presets.firstWhere((p) => p.id == selectedPresetId);
    } catch (_) {
      return presets.isNotEmpty ? presets.first : null;
    }
  }
}

class CompilerPresetsNotifier extends StateNotifier<CompilerPresetsState> {
  late Box<CompilerPreset> _box;
  late SharedPreferences _prefs;

  CompilerPresetsNotifier() : super(CompilerPresetsState(presets: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CompilerPreset>('presets');
    _prefs = await SharedPreferences.getInstance();

    if (_box.isEmpty) {
      for (var preset in AppConstants.defaultPresets) {
        await _box.put(preset.id, preset);
      }
    }

    final presets = _box.values.toList();
    final useDefault = _prefs.getBool('useDefaultPreset') ?? true;
    final selectedId = _prefs.getString('selectedPresetId') ??
        (presets.isNotEmpty ? presets.first.id : null);

    state = CompilerPresetsState(
      presets: presets,
      selectedPresetId: selectedId,
      useDefault: useDefault,
    );
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(
      presets: state.presets.map((p) => p.id == preset.id ? preset : p).toList(),
    );
  }

  void deletePreset(String id) {
    _box.delete(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    state = state.copyWith(
      presets: newPresets,
      selectedPresetId: state.selectedPresetId == id
          ? (newPresets.isNotEmpty ? newPresets.first.id : null)
          : state.selectedPresetId,
    );
    if (state.selectedPresetId != id && newPresets.isNotEmpty) {
      _prefs.setString('selectedPresetId', state.selectedPresetId!);
    } else {
      _prefs.remove('selectedPresetId');
    }
  }

  void selectPreset(String id) {
    _prefs.setString('selectedPresetId', id);
    _prefs.setBool('useDefaultPreset', false);
    state = state.copyWith(selectedPresetId: id, useDefault: false);
  }

  void toggleUseDefault(bool value) {
    _prefs.setBool('useDefaultPreset', value);
    state = state.copyWith(useDefault: value);
  }

  String exportPresetsJson() {
    final list = state.presets.map((p) => p.toJson()).toList();
    return jsonEncode(list);
  }

  void importPresetsJson(String jsonStr) {
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      for (var item in list) {
        final preset = CompilerPreset.fromJson(Map<String, dynamic>.from(item));
        addPreset(preset); // Will overwrite if ID exists, or add new
      }
    } catch (e) {
      print('Failed to import presets: \$e');
      rethrow; // Let UI handle error toast
    }
  }
}
