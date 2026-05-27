import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dartmini_ide/src/features/editor/domain/file_model.dart';
import 'package:dartmini_ide/src/core/providers/storage_provider.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({this.files = const [], this.activeFileId});

  FileState copyWith({List<FileModel>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  FileModel? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final StorageService _storage;
  Timer? _debounce;
  final _uuid = const Uuid();

  FileNotifier(this._storage) : super(FileState()) {
    _loadFiles();
  }

  void _loadFiles() {
    final boxFiles = _storage.fileBox.values.toList();
    if (boxFiles.isEmpty) {
      final defaultFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello, DartMini!');\n}\n",
        lastModified: DateTime.now(),
      );
      _storage.fileBox.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: boxFiles, activeFileId: boxFiles.first.id);
    }
  }

  void createFile() {
    final newFile = FileModel(
      id: _uuid.v4(),
      name: 'untitled.dart',
      content: '',
      lastModified: DateTime.now(),
    );
    _storage.fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId == null) return;

    final updatedFiles = state.files.map((file) {
      if (file.id == state.activeFileId) {
        return file.copyWith(content: newContent, lastModified: DateTime.now());
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final fileToSave = state.files.firstWhere((f) => f.id == state.activeFileId);
      _storage.fileBox.put(fileToSave.id, fileToSave);
    });
  }

  void deleteActiveFile() {
    if (state.activeFileId == null) return;
    final idToDelete = state.activeFileId!;
    _storage.fileBox.delete(idToDelete);

    final remainingFiles = state.files.where((f) => f.id != idToDelete).toList();

    if (remainingFiles.isEmpty) {
      final newFile = FileModel(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
        lastModified: DateTime.now(),
      );
      _storage.fileBox.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      state = FileState(files: remainingFiles, activeFileId: remainingFiles.first.id);
    }
  }

  void importFile(String name, String content) {
    final newFile = FileModel(
      id: _uuid.v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    _storage.fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier(ref.read(storageProvider));
});
