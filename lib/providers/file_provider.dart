import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/app_file.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';

class FileState {
  final List<AppFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  FileState copyWith({List<AppFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  AppFile? get activeFile {
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = HiveService.filesBox;
    List<AppFile> loadedFiles = box.values.toList();

    if (loadedFiles.isEmpty) {
      final newFile = AppFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: Constants.defaultDartCode,
      );
      box.put(newFile.id, newFile);
      loadedFiles = [newFile];
    }

    state = FileState(files: loadedFiles, activeFileId: loadedFiles.first.id);
  }

  void setActiveFile(String id) {
    if (state.activeFileId == id) return;

    // Save current active file explicitly before switching
    if (state.activeFile != null) {
      updateFileContent(state.activeFile!.id, state.activeFile!.content);
    }
    state = state.copyWith(activeFileId: id);
  }

  void addFile([String? name, String? content]) {
    final newFile = AppFile(
      id: const Uuid().v4(),
      name: name ?? 'untitled.dart',
      content: content ?? '',
    );
    HiveService.filesBox.put(newFile.id, newFile);

    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateFileContent(String id, String content) {
    final fileIndex = state.files.indexWhere((f) => f.id == id);
    if (fileIndex != -1) {
      final updatedFile = state.files[fileIndex].copyWith(content: content);

      // Update Hive
      HiveService.filesBox.put(updatedFile.id, updatedFile);

      // Update state without changing activeFileId
      final newFiles = List<AppFile>.from(state.files);
      newFiles[fileIndex] = updatedFile;
      state = state.copyWith(files: newFiles);
    }
  }

  void forceUpdate() {
      state = state.copyWith(files: List.from(state.files));
  }

  void renameFile(String id, String newName) {
    final fileIndex = state.files.indexWhere((f) => f.id == id);
    if (fileIndex != -1) {
      final updatedFile = state.files[fileIndex].copyWith(name: newName);
      HiveService.filesBox.put(updatedFile.id, updatedFile);

      final newFiles = List<AppFile>.from(state.files);
      newFiles[fileIndex] = updatedFile;
      state = state.copyWith(files: newFiles);
    }
  }

  void deleteFile(String id) {
    HiveService.filesBox.delete(id);

    final newFiles = state.files.where((f) => f.id != id).toList();
    if (newFiles.isEmpty) {
      // Create new untitled if empty
      final newFile = AppFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
      );
      HiveService.filesBox.put(newFile.id, newFile);
      newFiles.add(newFile);
    }

    String nextActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      nextActiveId = newFiles.last.id;
    }

    state = FileState(files: newFiles, activeFileId: nextActiveId);
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) => FileNotifier());
