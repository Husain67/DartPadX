import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'models/file_model.dart';
import 'models/compiler_preset.dart';

class HiveRegistrar {
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<FileModel>('files');
    await Hive.openBox<CompilerPreset>('presets');
  }
}
