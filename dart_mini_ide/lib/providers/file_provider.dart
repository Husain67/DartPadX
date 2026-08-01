import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/project_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<ProjectFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  ProjectFile? get activeFile => files.isNotEmpty
      ? files.firstWhere((f) => f.id == activeFileId, orElse: () => files.first)
      : null;

  FileState copyWith({
    List<ProjectFile>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<ProjectFile> _box;
  Timer? _saveTimer;

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  void _init() {
    _box = Hive.box<ProjectFile>('projectFiles');
    List<ProjectFile> loadedFiles = _box.values.toList();

    if (loadedFiles.isEmpty) {
      final initialFile = ProjectFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello, DartMini IDE!');\n}\n",
      );
      _box.put(initialFile.id, initialFile);
      loadedFiles = [initialFile];
    }

    state = FileState(files: loadedFiles, activeFileId: loadedFiles.first.id);
  }

  void addFile(String name, [String content = '']) {
    final newFile = ProjectFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      content: content,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void removeFile(String id) {
    if (state.files.length <= 1) {
      // Create an untitled if empty
      _box.delete(id);
      final newFile = ProjectFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'untitled.dart',
        content: '',
      );
      _box.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
      return;
    }

    _box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    String nextActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      nextActiveId = remainingFiles.first.id;
    }

    state = state.copyWith(files: remainingFiles, activeFileId: nextActiveId);
  }

  void switchFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId.isEmpty) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return f.copyWith(content: newContent);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      final activeFile = state.activeFile;
      if (activeFile != null) {
        _box.put(activeFile.id, activeFile);
      }
    });
  }
}
