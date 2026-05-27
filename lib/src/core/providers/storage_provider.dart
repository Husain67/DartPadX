import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dartmini_ide/src/features/editor/domain/file_model.dart';
import 'package:dartmini_ide/src/features/settings/domain/compiler_preset.dart';

final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in ProviderScope');
});

class StorageService {
  late Box<FileModel> fileBox;
  late Box<CompilerPreset> presetBox;

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(FileModelAdapter());
    Hive.registerAdapter(CompilerPresetAdapter());

    fileBox = await Hive.openBox<FileModel>('files_box');
    presetBox = await Hive.openBox<CompilerPreset>('presets_box');
  }
}
