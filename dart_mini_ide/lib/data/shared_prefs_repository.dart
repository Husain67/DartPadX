import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsRepository {
  static const String currentFileIdKey = 'current_file_id';
  static const String currentPresetIdKey = 'current_preset_id';
  static const String useDefaultOneCompilerKey = 'use_default_one_compiler';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? getCurrentFileId() {
    return _prefs.getString(currentFileIdKey);
  }

  Future<void> setCurrentFileId(String id) async {
    await _prefs.setString(currentFileIdKey, id);
  }

  String? getCurrentPresetId() {
    return _prefs.getString(currentPresetIdKey);
  }

  Future<void> setCurrentPresetId(String id) async {
    await _prefs.setString(currentPresetIdKey, id);
  }

  bool getUseDefaultOneCompiler() {
    return _prefs.getBool(useDefaultOneCompilerKey) ?? true;
  }

  Future<void> setUseDefaultOneCompiler(bool useDefault) async {
    await _prefs.setBool(useDefaultOneCompilerKey, useDefault);
  }
}
