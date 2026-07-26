import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/file_model.dart';
import 'models/compiler_preset.dart';
import '../core/constants.dart';
import 'package:uuid/uuid.dart';

class HiveService {
  static const String filesBoxName = 'filesBox';
  static const String presetsBoxName = 'presetsBox';

  static late Box<FileModel> filesBox;
  static late Box<CompilerPreset> presetsBox;
  static late SharedPreferences prefs;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters manually to avoid build_runner issues
    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    filesBox = await Hive.openBox<FileModel>(filesBoxName);
    presetsBox = await Hive.openBox<CompilerPreset>(presetsBoxName);
    prefs = await SharedPreferences.getInstance();

    _seedInitialData();
  }

  static void _seedInitialData() {
    if (filesBox.isEmpty) {
      final id = const Uuid().v4();
      filesBox.put(
          id,
          FileModel(
            id: id,
            name: AppConstants.defaultFileName,
            content: AppConstants.defaultCode,
            lastModified: DateTime.now().millisecondsSinceEpoch,
          ));
    }
  }
}
