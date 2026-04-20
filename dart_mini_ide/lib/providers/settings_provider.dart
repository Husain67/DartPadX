import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.read(sharedPreferencesProvider));
});

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
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(SettingsState(
    useDefaultOneCompiler: _prefs.getBool('useDefaultOneCompiler') ?? true,
    activePresetId: _prefs.getString('activePresetId'),
  ));

  void toggleUseDefaultOneCompiler(bool value) {
    _prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePresetId(String id) {
    _prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }
}
