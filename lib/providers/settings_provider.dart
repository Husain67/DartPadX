import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool isDarkMode;
  final bool useDefaultOneCompiler;

  SettingsState({
    this.isDarkMode = true,
    this.useDefaultOneCompiler = true,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? useDefaultOneCompiler,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      isDarkMode: prefs.getBool('isDarkMode') ?? true,
      useDefaultOneCompiler: prefs.getBool('useDefaultOneCompiler') ?? true,
    );
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newMode = !state.isDarkMode;
    await prefs.setBool('isDarkMode', newMode);
    state = state.copyWith(isDarkMode: newMode);
  }

  Future<void> setUseDefaultOneCompiler(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }
}
