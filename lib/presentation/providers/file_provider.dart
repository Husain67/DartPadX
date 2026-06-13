import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/file_entity.dart';
import '../../data/repositories/local_storage.dart';
import '../../core/constants/app_constants.dart';

class FileState {
  final List<FileEntity> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<FileEntity>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _debounce;
  final Uuid _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final boxFiles = LocalStorage.filesBox.values.toList();
    if (boxFiles.isEmpty) {
      // Create default main.dart
      final newFile = FileEntity(
        id: _uuid.v4(),
        name: 'main.dart',
        content: AppConstants.defaultCode,
        lastModified: DateTime.now(),
      );
      LocalStorage.filesBox.put(newFile.id, newFile);
      boxFiles.add(newFile);
    }

    final activeId = LocalStorage.prefs.getString(AppConstants.activeFileIdKey) ?? boxFiles.first.id;
    state = state.copyWith(files: boxFiles, activeFileId: activeId);
  }

  void createNewFile() {
    final newFile = FileEntity(
      id: _uuid.v4(),
      name: 'untitled.dart',
      content: '',
      lastModified: DateTime.now(),
    );
    LocalStorage.filesBox.put(newFile.id, newFile);
    LocalStorage.prefs.setString(AppConstants.activeFileIdKey, newFile.id);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void setActiveFile(String id) {
    LocalStorage.prefs.setString(AppConstants.activeFileIdKey, id);
    state = state.copyWith(activeFileId: id);
  }

  void deleteActiveFile() {
    if (state.activeFileId == null) return;
    LocalStorage.filesBox.delete(state.activeFileId);

    final remainingFiles = state.files.where((f) => f.id != state.activeFileId).toList();
    if (remainingFiles.isEmpty) {
      // Create a new untitled to replace it
      final newFile = FileEntity(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
        lastModified: DateTime.now(),
      );
      LocalStorage.filesBox.put(newFile.id, newFile);
      LocalStorage.prefs.setString(AppConstants.activeFileIdKey, newFile.id);
      state = state.copyWith(files: [newFile], activeFileId: newFile.id);
    } else {
      LocalStorage.prefs.setString(AppConstants.activeFileIdKey, remainingFiles.first.id);
      state = state.copyWith(files: remainingFiles, activeFileId: remainingFiles.first.id);
    }
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId == null) return;

    final fileIndex = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (fileIndex == -1) return;

    final updatedFile = state.files[fileIndex].copyWith(
      content: newContent,
      lastModified: DateTime.now(),
    );

    final newFilesList = List<FileEntity>.from(state.files);
    newFilesList[fileIndex] = updatedFile;

    // Update State Instantly for UI
    state = state.copyWith(files: newFilesList);

    // Debounce save to Hive
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      LocalStorage.filesBox.put(updatedFile.id, updatedFile);
    });
  }

  void updateActiveFileName(String newName) {
    if (state.activeFileId == null) return;

    final fileIndex = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (fileIndex == -1) return;

    final updatedFile = state.files[fileIndex].copyWith(
      name: newName,
      lastModified: DateTime.now(),
    );

    final newFilesList = List<FileEntity>.from(state.files);
    newFilesList[fileIndex] = updatedFile;

    state = state.copyWith(files: newFilesList);
    LocalStorage.filesBox.put(updatedFile.id, updatedFile);
  }

  void importFile(String name, String content) {
    final newFile = FileEntity(
      id: _uuid.v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    LocalStorage.filesBox.put(newFile.id, newFile);
    LocalStorage.prefs.setString(AppConstants.activeFileIdKey, newFile.id);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
