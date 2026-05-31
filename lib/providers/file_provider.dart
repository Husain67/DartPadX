import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../services/storage_service.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<FileModel>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _saveTimer;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final boxFiles = StorageService.filesBox.values.toList();
    if (boxFiles.isEmpty) {
      final defaultFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello, DartMini!');\n}",
      );
      StorageService.filesBox.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: boxFiles, activeFileId: boxFiles.first.id);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void createFile(String name, [String content = '']) {
    final newFile = FileModel(id: _uuid.v4(), name: name, content: content);
    StorageService.filesBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateContent(String id, String newContent) {
    final index = state.files.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final updatedFile = state.files[index].copyWith(content: newContent, lastModified: DateTime.now());

    final newFiles = List<FileModel>.from(state.files);
    newFiles[index] = updatedFile;

    state = state.copyWith(files: newFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      StorageService.filesBox.put(updatedFile.id, updatedFile);
    });
  }

  void forceUpdateContent(String id, String newContent) {
    final index = state.files.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final updatedFile = state.files[index].copyWith(content: newContent, lastModified: DateTime.now());

    final newFiles = List<FileModel>.from(state.files);
    newFiles[index] = updatedFile;

    state = state.copyWith(files: newFiles);
    StorageService.filesBox.put(updatedFile.id, updatedFile);
  }

  void deleteFile(String id) {
    StorageService.filesBox.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();

    if (newFiles.isEmpty) {
      final newFile = FileModel(id: _uuid.v4(), name: 'untitled.dart', content: '');
      StorageService.filesBox.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      final newActiveId = state.activeFileId == id ? newFiles.first.id : state.activeFileId;
      state = state.copyWith(files: newFiles, activeFileId: newActiveId);
    }
  }

  FileModel? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
