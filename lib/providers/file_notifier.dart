import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../services/hive_service.dart';
import '../utils/constants.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({
    List<FileModel>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  FileModel? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (e) {
      return files.first;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _debounceTimer;

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  FileState get currentState => state;

  void _loadFiles() {
    final box = HiveService.getFilesBox();
    final settingsBox = HiveService.getSettingsBox();
    List<FileModel> files = box.values.toList();

    if (files.isEmpty) {
      final defaultFile = FileModel(
        name: Constants.defaultFileName,
        content: Constants.defaultFileContent,
      );
      box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }

    // Sort files logically, e.g., by created time or name, if needed
    files.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final lastActiveId = settingsBox.get('active_file_id');
    final activeId = files.any((f) => f.id == lastActiveId)
        ? lastActiveId
        : files.first.id;

    state = state.copyWith(files: files, activeFileId: activeId);
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      HiveService.getSettingsBox().put('active_file_id', id);
      state = state.copyWith(activeFileId: id);
    }
  }

  void createFile(String name, {String content = ''}) {
    final newFile = FileModel(name: name, content: content);
    HiveService.getFilesBox().put(newFile.id, newFile);

    final newFiles = [...state.files, newFile];
    HiveService.getSettingsBox().put('active_file_id', newFile.id);

    state = state.copyWith(files: newFiles, activeFileId: newFile.id);
  }

  void updateFileContent(String id, String newContent) {
    // Update state immediately for UI
    final newFiles = state.files.map((f) {
      if (f.id == id) {
        return f.copyWith(content: newContent, updatedAt: DateTime.now());
      }
      return f;
    }).toList();

    state = state.copyWith(files: newFiles);

    // Debounce save to Hive
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      final fileToSave = newFiles.firstWhere((f) => f.id == id);
      HiveService.getFilesBox().put(id, fileToSave);
    });
  }

  void renameFile(String id, String newName) {
    final newFiles = state.files.map((f) {
      if (f.id == id) {
        return f.copyWith(name: newName, updatedAt: DateTime.now());
      }
      return f;
    }).toList();

    state = state.copyWith(files: newFiles);

    final fileToSave = newFiles.firstWhere((f) => f.id == id);
    HiveService.getFilesBox().put(id, fileToSave);
  }

  void deleteFile(String id) {
    HiveService.getFilesBox().delete(id);

    final newFiles = state.files.where((f) => f.id != id).toList();

    if (newFiles.isEmpty) {
      createFile('untitled.dart');
    } else {
      String nextActiveId = state.activeFileId ?? '';
      if (id == state.activeFileId) {
        nextActiveId = newFiles.last.id;
      }
      HiveService.getSettingsBox().put('active_file_id', nextActiveId);
      state = state.copyWith(files: newFiles, activeFileId: nextActiveId);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
