import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import 'file_provider.dart';
import 'settings_provider.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier(ref);
});

class CompilerState {
  final List<CompilerPreset> presets;

  CompilerState({required this.presets});
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Ref _ref;
  final _uuid = const Uuid();

  CompilerNotifier(this._ref) : super(CompilerState(presets: [])) {
    _loadPresets();
  }

  void _loadPresets() {
    final storage = _ref.read(storageServiceProvider);
    state = CompilerState(presets: storage.getAllPresets());
  }

  CompilerPreset? get activePreset {
    final activeId = _ref.read(settingsProvider).activePresetId;
    if (activeId == null || state.presets.isEmpty) return null;
    try {
      return state.presets.firstWhere((p) => p.id == activeId);
    } catch (_) {
      return state.presets.first;
    }
  }

  void addPreset(CompilerPreset preset) {
    final storage = _ref.read(storageServiceProvider);
    storage.presetsBox.put(preset.id, preset);
    _loadPresets();
  }

  void updatePreset(CompilerPreset preset) {
    preset.save();
    _loadPresets();
  }

  void deletePreset(String id) {
    final storage = _ref.read(storageServiceProvider);
    storage.presetsBox.delete(id);
    _loadPresets();

    final activeId = _ref.read(settingsProvider).activePresetId;
    if (activeId == id && state.presets.isNotEmpty) {
       _ref.read(settingsProvider.notifier).setActivePresetId(state.presets.first.id);
    }
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: _uuid.v4(),
      name: '${preset.name} (Copy)',
    );
    addPreset(newPreset);
  }
}
