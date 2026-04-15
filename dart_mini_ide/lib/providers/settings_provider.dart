import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? selectedPresetId;

  SettingsState({
    this.useDefaultOneCompiler = true,
    this.selectedPresetId,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? selectedPresetId,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      selectedPresetId: selectedPresetId ?? this.selectedPresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useDefault = prefs.getBool('useDefaultOneCompiler') ?? true;
    final presetId = prefs.getString('selectedPresetId');
    state = state.copyWith(
      useDefaultOneCompiler: useDefault,
      selectedPresetId: presetId,
    );
  }

  Future<void> setUseDefaultOneCompiler(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  Future<void> setSelectedPresetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedPresetId', id);
    state = state.copyWith(selectedPresetId: id);
  }
}
