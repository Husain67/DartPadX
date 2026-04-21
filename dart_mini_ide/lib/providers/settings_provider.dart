import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final useDefaultOneCompilerProvider = StateNotifierProvider<UseDefaultOneCompilerNotifier, bool>((ref) {
  return UseDefaultOneCompilerNotifier(ref.watch(sharedPreferencesProvider));
});

class UseDefaultOneCompilerNotifier extends StateNotifier<bool> {
  final SharedPreferences prefs;
  UseDefaultOneCompilerNotifier(this.prefs) : super(prefs.getBool('useDefaultOneCompiler') ?? true);

  void toggle() {
    state = !state;
    prefs.setBool('useDefaultOneCompiler', state);
  }
}
