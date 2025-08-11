import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  final SharedPreferences _prefs;
  static const String _themeKey = 'app_theme_mode';

  void _loadTheme() {
    final themeIndex = _prefs.getInt(_themeKey);
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> setTheme(ThemeMode themeMode) async {
    if (state != themeMode) {
      state = themeMode;
      await _prefs.setInt(_themeKey, themeMode.index);
    }
  }
}
