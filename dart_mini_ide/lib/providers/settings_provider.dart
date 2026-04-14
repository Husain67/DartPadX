import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool useDefaultOneCompiler;
  final String activePresetId;

  SettingsState({
    required this.useDefaultOneCompiler,
    required this.activePresetId,
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
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs) : super(SettingsState(
    useDefaultOneCompiler: prefs.getBool('useDefaultOneCompiler') ?? true,
    activePresetId: prefs.getString('activePresetId') ?? '',
  ));

  void toggleUseDefault(bool value) {
    prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }
}

// Provider needs to be initialized with actual SharedPreferences instance in main
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider not initialized');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.read(sharedPrefsProvider));
});
