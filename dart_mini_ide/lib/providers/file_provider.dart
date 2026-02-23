import 'package:dart_mini_ide/models/code_file.dart';
import 'package:dart_mini_ide/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FileNotifier(storage);
});

class FileState {
  final List<CodeFile> files;
  final CodeFile? activeFile;
  final bool isLoading;

  FileState({
    this.files = const [],
    this.activeFile,
    this.isLoading = true,
  });

  FileState copyWith({
    List<CodeFile>? files,
    CodeFile? activeFile,
    bool? isLoading,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFile: activeFile ?? this.activeFile,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final StorageService _storage;

  FileNotifier(this._storage) : super(FileState()) {
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final files = await _storage.getAllFiles();
    final activeId = _storage.activeFileId;
    CodeFile? activeFile;
    if (files.isNotEmpty) {
      if (activeId != null) {
        activeFile = files.firstWhere((f) => f.id == activeId, orElse: () => files.first);
      } else {
        activeFile = files.first;
      }
    }
    state = FileState(files: files, activeFile: activeFile, isLoading: false);
  }

  Future<void> createFile(String name, String content) async {
    final newFile = CodeFile(name: name, content: content);
    await _storage.saveFile(newFile);
    await _loadFiles();
    setActiveFile(newFile);
  }

  Future<void> deleteActiveFile() async {
    if (state.activeFile == null) return;
    final fileToDelete = state.activeFile!;
    await _storage.deleteFile(fileToDelete);
    await _loadFiles();
    // After reload, active file might be reset by _loadFiles logic, but let's ensure it.
  }

  Future<void> updateActiveFileContent(String content) async {
    if (state.activeFile == null) return;
    // We modify the object in place because it's a HiveObject and we want to keep the reference if possible,
    // but state immutability suggests we should replace it.
    // However, Hive objects are mutable.
    // For Riverpod to detect change, we need a new state object.

    // We should create a copy, save it (which updates Hive if ID matches), and update state.
    // Actually, HiveObject `save()` updates the record in the box.
    // But `state.activeFile` is a reference.
    state.activeFile!.content = content;
    state.activeFile!.lastModified = DateTime.now();
    await state.activeFile!.save();

    // Trigger state update
    state = state.copyWith();
  }

  Future<void> setActiveFile(CodeFile file) async {
    await _storage.setActiveFileId(file.id);
    state = state.copyWith(activeFile: file);
  }
}
