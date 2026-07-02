import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_file.dart';
import '../models/compiler_preset.dart';

class StorageService {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(AppFileAdapter());
    Hive.registerAdapter(ResponseMappingAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    await Hive.openBox<AppFile>('appFiles');
    await Hive.openBox<CompilerPreset>('compilerPresets');
  }
}
