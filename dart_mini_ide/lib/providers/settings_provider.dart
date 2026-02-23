import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/providers/file_provider.dart';
import 'package:dart_mini_ide/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});

class SettingsState {
  final List<CompilerPreset> presets;
  final CompilerPreset? activePreset;
  final bool useCustomPreset;
  final bool isLoading;

  SettingsState({
    this.presets = const [],
    this.activePreset,
    this.useCustomPreset = false,
    this.isLoading = true,
  });

  SettingsState copyWith({
    List<CompilerPreset>? presets,
    CompilerPreset? activePreset,
    bool? useCustomPreset,
    bool? isLoading,
  }) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePreset: activePreset ?? this.activePreset,
      useCustomPreset: useCustomPreset ?? this.useCustomPreset,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final presets = _storage.getAllPresets();
    final activeId = _storage.activePresetId;
    final useCustom = _storage.useCustomPreset;

    CompilerPreset? activePreset;
    if (presets.isNotEmpty) {
      if (activeId != null) {
        activePreset = presets.firstWhere((p) => p.id == activeId, orElse: () => presets.first);
      } else {
        activePreset = presets.first;
      }
    }

    state = SettingsState(
      presets: presets,
      activePreset: activePreset,
      useCustomPreset: useCustom,
      isLoading: false,
    );
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _storage.savePreset(preset);
    await _loadSettings();
    setActivePreset(preset);
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await _storage.savePreset(preset);
    await _loadSettings();
  }

  Future<void> deletePreset(CompilerPreset preset) async {
    await _storage.deletePreset(preset);
    await _loadSettings();
  }

  Future<void> setActivePreset(CompilerPreset preset) async {
    await _storage.setActivePresetId(preset.id);
    state = state.copyWith(activePreset: preset);
  }

  Future<void> setUseCustomPreset(bool value) async {
    await _storage.setUseCustomPreset(value);
    state = state.copyWith(useCustomPreset: value);
  }
}
