import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool useDefaultOneCompiler;

  SettingsState({this.useDefaultOneCompiler = true});

  SettingsState copyWith({bool? useDefaultOneCompiler}) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final useDefault = _prefs.getBool('useDefaultOneCompiler') ?? true;
    state = SettingsState(useDefaultOneCompiler: useDefault);
  }

  Future<void> toggleUseDefaultOneCompiler(bool value) async {
    await _prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
