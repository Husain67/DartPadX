import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final useDefaultOneCompilerProvider = StateNotifierProvider<UseDefaultOneCompilerNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UseDefaultOneCompilerNotifier(prefs);
});

class UseDefaultOneCompilerNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'useDefaultOneCompiler';

  UseDefaultOneCompilerNotifier(this._prefs) : super(_prefs.getBool(_key) ?? true);

  void toggle(bool value) {
    state = value;
    _prefs.setBool(_key, value);
  }
}
