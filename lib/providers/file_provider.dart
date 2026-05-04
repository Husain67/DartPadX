import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/dart_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<DartFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  FileState copyWith({List<DartFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [], activeFileId: ''));
  late Box _box;
  Timer? _autoSaveTimer;

  Future<void> init() async {
    _box = await Hive.openBox('dart_files');
    List<DartFile> loadedFiles = [];

    for (var key in _box.keys) {
      final map = Map<String, dynamic>.from(_box.get(key));
      loadedFiles.add(DartFile.fromMap(map));
    }

    if (loadedFiles.isEmpty) {
      final newFile = DartFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello, DartMini IDE!');\n}\n",
      );
      loadedFiles.add(newFile);
      await _box.put(newFile.id, newFile.toMap());
    }

    state = FileState(files: loadedFiles, activeFileId: loadedFiles.first.id);

    // Auto-save timer
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _saveActiveFile();
    });
  }

  void setActiveFile(String id) {
    _saveActiveFile(); // Force save before switching
    state = state.copyWith(activeFileId: id);
  }

  DartFile? get activeFile {
    if (state.activeFileId.isEmpty) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId.isEmpty) return;
    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return f.copyWith(content: content);
      }
      return f;
    }).toList();
    state = state.copyWith(files: updatedFiles);
  }

  Future<void> _saveActiveFile() async {
    final currentFile = activeFile;
    if (currentFile != null) {
      await _box.put(currentFile.id, currentFile.toMap());
    }
  }

  Future<void> createNewFile() async {
    final newFile = DartFile(
      id: const Uuid().v4(),
      name: 'untitled_\${state.files.length}.dart',
      content: '// New Dart file\nvoid main() {\n  \n}\n',
    );
    final updatedFiles = [...state.files, newFile];
    await _box.put(newFile.id, newFile.toMap());
    state = FileState(files: updatedFiles, activeFileId: newFile.id);
  }

  Future<void> importFile(String name, String content) async {
    final newFile = DartFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    final updatedFiles = [...state.files, newFile];
    await _box.put(newFile.id, newFile.toMap());
    state = FileState(files: updatedFiles, activeFileId: newFile.id);
  }

  Future<void> deleteActiveFile() async {
    if (state.activeFileId.isEmpty) return;

    await _box.delete(state.activeFileId);

    final remainingFiles = state.files.where((f) => f.id != state.activeFileId).toList();

    if (remainingFiles.isEmpty) {
      // Auto create new if empty
      final newFile = DartFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '// New Dart file\nvoid main() {\n  \n}\n',
      );
      remainingFiles.add(newFile);
      await _box.put(newFile.id, newFile.toMap());
    }

    state = FileState(
      files: remainingFiles,
      activeFileId: remainingFiles.last.id,
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
