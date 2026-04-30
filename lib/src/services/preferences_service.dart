import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const String _useDefaultOneCompilerKey = 'use_default_one_compiler';
  static const String _selectedPresetIdKey = 'selected_preset_id';

  static bool get useDefaultOneCompiler => _prefs.getBool(_useDefaultOneCompilerKey) ?? true;

  static Future<void> setUseDefaultOneCompiler(bool value) async {
    await _prefs.setBool(_useDefaultOneCompilerKey, value);
  }

  static String? get selectedPresetId => _prefs.getString(_selectedPresetIdKey);

  static Future<void> setSelectedPresetId(String id) async {
    await _prefs.setString(_selectedPresetIdKey, id);
  }
}
