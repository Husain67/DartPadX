import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activePresetId;

  SettingsState({
    required this.useDefaultOneCompiler,
    this.activePresetId,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? activePresetId,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(useDefaultOneCompiler: true)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useDefault = prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = prefs.getString('activePresetId');
    state = state.copyWith(
      useDefaultOneCompiler: useDefault,
      activePresetId: activeId,
    );
  }

  Future<void> setUseDefaultOneCompiler(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  Future<void> setActivePresetId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
