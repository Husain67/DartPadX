import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/file_entity.dart';
import '../models/compiler_preset.dart';

class LocalStorage {
  static late Box<FileEntity> filesBox;
  static late Box<CompilerPreset> presetsBox;
  static late SharedPreferences prefs;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(FileEntityAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    // Open Boxes
    filesBox = await Hive.openBox<FileEntity>(AppConstants.filesBox);
    presetsBox = await Hive.openBox<CompilerPreset>(AppConstants.presetsBox);

    // Init Shared Preferences
    prefs = await SharedPreferences.getInstance();
  }

  static Future<void> clearAll() async {
    await filesBox.clear();
    await presetsBox.clear();
    await prefs.clear();
  }
}
