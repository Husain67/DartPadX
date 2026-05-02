import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class SettingsState {
  final bool useDefaultOneCompiler;
  SettingsState({required this.useDefaultOneCompiler});
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs)
      : super(SettingsState(
            useDefaultOneCompiler:
                prefs.getBool('useDefaultOneCompiler') ?? true));

  void toggleUseDefaultOneCompiler(bool value) {
    prefs.setBool('useDefaultOneCompiler', value);
    state = SettingsState(useDefaultOneCompiler: value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
