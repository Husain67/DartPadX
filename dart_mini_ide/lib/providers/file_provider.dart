import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/code_file.dart';
import '../services/storage_service.dart';

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile =>
      files.firstWhere((f) => f.id == activeFileId, orElse: () => files.first);
}

final storageServiceProvider = Provider((ref) => StorageService());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FileNotifier(storage);
});

class FileNotifier extends StateNotifier<FileState> {
  final StorageService _storage;
  Timer? _autoSaveTimer;

  FileNotifier(this._storage) : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _storage.getAllFiles();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        name: 'main.dart',
        content: "void main() {\n  print('Hello, DartMini!');\n}",
      );
      _storage.saveFile(defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void createNewFile() {
    int count = state.files.where((f) => f.name.startsWith('untitled')).length;
    final newFile = CodeFile(
      name: 'untitled${count > 0 ? count + 1 : ""}.dart',
      content: "void main() {\n  \n}",
    );
    _storage.saveFile(newFile);
    state = FileState(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void importFile(String name, String content) {
    final newFile = CodeFile(name: name, content: content);
    _storage.saveFile(newFile);
    state = FileState(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active != null) {
      final updated = active.copyWith(content: content, lastModified: DateTime.now());

      // Update state immediately
      state = FileState(
        files: state.files.map((f) => f.id == updated.id ? updated : f).toList(),
        activeFileId: state.activeFileId,
      );

      // Debounce save to storage
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        _storage.saveFile(updated);
      });
    }
  }

  // Force save immediately (e.g. before run)
  Future<void> saveActiveFile(String content) async {
      _autoSaveTimer?.cancel();
      final active = state.activeFile;
      if (active != null) {
          final updated = active.copyWith(content: content, lastModified: DateTime.now());
          await _storage.saveFile(updated);
          state = FileState(
            files: state.files.map((f) => f.id == updated.id ? updated : f).toList(),
            activeFileId: state.activeFileId,
          );
      }
  }

  void setActiveFile(String id) {
    state = FileState(files: state.files, activeFileId: id);
  }

  Future<void> deleteActiveFile() async {
    final activeId = state.activeFileId;
    if (activeId != null) {
      await _storage.deleteFile(activeId);
      final remaining = state.files.where((f) => f.id != activeId).toList();

      if (remaining.isEmpty) {
         final defaultFile = CodeFile(
          name: 'main.dart',
          content: "void main() {\n  print('Hello, DartMini!');\n}",
        );
        await _storage.saveFile(defaultFile);
        state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
      } else {
        state = FileState(files: remaining, activeFileId: remaining.last.id);
      }
    }
  }
}
