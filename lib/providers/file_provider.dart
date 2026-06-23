import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_file.dart';
import '../services/storage_service.dart';

class FileState {
  final List<ProjectFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  ProjectFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    return files.cast<ProjectFile?>().firstWhere(
      (f) => f?.id == activeFileId,
      orElse: () => null,
    );
  }

  FileState copyWith({List<ProjectFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final StorageService _storage;
  Timer? _debounceTimer;

  FileNotifier(this._storage) : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = _storage.filesBox;
    List<ProjectFile> loadedFiles = box.values.toList();

    if (loadedFiles.isEmpty) {
      final defaultFile = ProjectFile.create(
        name: 'main.dart',
        content: "void main() {\n  print('Hello, DartMini!');\n}\n",
      );
      box.put(defaultFile.id, defaultFile);
      loadedFiles = [defaultFile];
    }

    final activeId = _storage.settingsBox.get('activeFileId') as String?;
    final validActiveId = loadedFiles.any((f) => f.id == activeId) ? activeId : loadedFiles.first.id;

    state = FileState(files: loadedFiles, activeFileId: validActiveId);
  }

  void setActiveFile(String id) {
    _storage.settingsBox.put('activeFileId', id);
    state = state.copyWith(activeFileId: id);
  }

  void createNewFile() {
    final newFile = ProjectFile.create();
    _storage.filesBox.put(newFile.id, newFile);

    final updatedFiles = List<ProjectFile>.from(state.files)..add(newFile);
    state = state.copyWith(files: updatedFiles, activeFileId: newFile.id);
    _storage.settingsBox.put('activeFileId', newFile.id);
  }

  void importFile(String name, String content) {
    final newFile = ProjectFile.create(name: name, content: content);
    _storage.filesBox.put(newFile.id, newFile);

    final updatedFiles = List<ProjectFile>.from(state.files)..add(newFile);
    state = state.copyWith(files: updatedFiles, activeFileId: newFile.id);
    _storage.settingsBox.put('activeFileId', newFile.id);
  }

  void updateActiveFileContent(String newContent) {
    final active = state.activeFile;
    if (active == null || active.content == newContent) return;

    final updatedFile = active.copyWith(content: newContent, lastModified: DateTime.now());

    final index = state.files.indexWhere((f) => f.id == active.id);
    if (index != -1) {
      final updatedFiles = List<ProjectFile>.from(state.files);
      updatedFiles[index] = updatedFile;
      state = state.copyWith(files: updatedFiles);

      // Debounce save to Hive
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        _storage.filesBox.put(updatedFile.id, updatedFile);
      });
    }
  }

  void deleteFile(String id) {
    _storage.filesBox.delete(id);

    final updatedFiles = List<ProjectFile>.from(state.files)..removeWhere((f) => f.id == id);

    if (updatedFiles.isEmpty) {
      final defaultFile = ProjectFile.create();
      _storage.filesBox.put(defaultFile.id, defaultFile);
      updatedFiles.add(defaultFile);
    }

    String? newActiveId = state.activeFileId;
    if (newActiveId == id) {
      newActiveId = updatedFiles.last.id;
    }

    state = FileState(files: updatedFiles, activeFileId: newActiveId);
    _storage.settingsBox.put('activeFileId', newActiveId);
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier(StorageService());
});
