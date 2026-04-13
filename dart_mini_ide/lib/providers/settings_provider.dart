import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activeCustomPresetId;

  SettingsState({
    required this.useDefaultOneCompiler,
    this.activeCustomPresetId,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? activeCustomPresetId,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activeCustomPresetId: activeCustomPresetId ?? this.activeCustomPresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs)
      : super(SettingsState(
          useDefaultOneCompiler: prefs.getBool('useDefaultOneCompiler') ?? true,
          activeCustomPresetId: prefs.getString('activeCustomPresetId'),
        ));

  void toggleUseDefaultOneCompiler(bool value) {
    prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActiveCustomPreset(String id) {
    prefs.setString('activeCustomPresetId', id);
    state = state.copyWith(activeCustomPresetId: id);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});
