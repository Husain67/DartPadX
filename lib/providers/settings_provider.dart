import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

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
  SettingsNotifier() : super(SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final useDefault = prefs.getBool('useDefaultOneCompiler') ?? true;
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  Future<void> setUseDefaultOneCompiler(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }
}
