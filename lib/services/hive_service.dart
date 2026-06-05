import 'package:hive/hive.dart';
import '../models/editor_file.dart';
import '../models/compiler_preset.dart';

class HiveService {
  late Box<EditorFile> _filesBox;
  late Box<CompilerPreset> _presetsBox;

  Future<void> init() async {
    _filesBox = await Hive.openBox<EditorFile>('editor_files');
    _presetsBox = await Hive.openBox<CompilerPreset>('compiler_presets');
  }

  // --- File Methods ---

  List<EditorFile> getFiles() {
    return _filesBox.values.toList();
  }

  void saveFile(EditorFile file) {
    _filesBox.put(file.id, file);
  }

  void deleteFile(String id) {
    _filesBox.delete(id);
  }

  // --- Compiler Preset Methods ---

  List<CompilerPreset> getPresets() {
    return _presetsBox.values.toList();
  }

  void savePreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
  }

  void deletePreset(String id) {
    _presetsBox.delete(id);
  }
}
