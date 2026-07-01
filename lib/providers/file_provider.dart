import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../services/hive_service.dart';

class FileState {
  final List<FileModel> openFiles;
  final String? activeFileId;

  FileState({
    required this.openFiles,
    required this.activeFileId,
  });

  FileState copyWith({
    List<FileModel>? openFiles,
    String? activeFileId,
  }) {
    return FileState(
      openFiles: openFiles ?? this.openFiles,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(openFiles: [], activeFileId: null)) {
    _loadInitialFiles();
  }

  FileState get currentState => state;
  Timer? _debounceTimer;

  void _loadInitialFiles() {
    final box = HiveService.filesBox;
    final files = box.values.toList();
    if (files.isNotEmpty) {
      state = state.copyWith(
        openFiles: files,
        activeFileId: files.first.id,
      );
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void createNewFile() {
    int count = state.openFiles.where((f) => f.name.startsWith('untitled')).length;
    final newFile = FileModel(
      id: const Uuid().v4(),
      name: count == 0 ? 'untitled.dart' : 'untitled${count}.dart',
      content: '',
    );

    HiveService.filesBox.put(newFile.id, newFile);

    state = state.copyWith(
      openFiles: [...state.openFiles, newFile],
      activeFileId: newFile.id,
    );
  }

  void addOrOpenFile(FileModel file) {
    final exists = state.openFiles.any((f) => f.id == file.id);
    if (!exists) {
      HiveService.filesBox.put(file.id, file);
      state = state.copyWith(
        openFiles: [...state.openFiles, file],
        activeFileId: file.id,
      );
    } else {
      setActiveFile(file.id);
    }
  }

  void updateActiveFileContent(String content) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final openFiles = List<FileModel>.from(state.openFiles);
    final index = openFiles.indexWhere((f) => f.id == activeId);

    if (index != -1) {
      final updatedFile = openFiles[index].copyWith(content: content);
      openFiles[index] = updatedFile;

      state = state.copyWith(openFiles: openFiles);

      // Debounce saving to Hive
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        HiveService.filesBox.put(activeId, updatedFile);
      });
    }
  }

  void deleteActiveFile() {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    HiveService.filesBox.delete(activeId);

    final openFiles = List<FileModel>.from(state.openFiles)..removeWhere((f) => f.id == activeId);

    String? newActiveId;
    if (openFiles.isNotEmpty) {
      newActiveId = openFiles.last.id;
    }

    state = state.copyWith(
      openFiles: openFiles,
      activeFileId: newActiveId,
    );

    if (openFiles.isEmpty) {
      createNewFile();
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
