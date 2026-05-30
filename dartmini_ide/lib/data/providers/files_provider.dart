import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/code_file.dart';
import '../services/hive_service.dart';
import '../../core/constants/app_constants.dart';


class FilesState {
  final List<CodeFile> files;
  final String? activeFileId;

  FilesState({required this.files, this.activeFileId});

  FilesState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FilesState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return files.first;
    }
  }
}

class FilesNotifier extends StateNotifier<FilesState> {
  Timer? _debounceTimer;

  FilesNotifier() : super(FilesState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final boxFiles = HiveService.filesBox.values.toList();
    if (boxFiles.isEmpty) {
      final defaultFile = CodeFile(
        name: AppConstants.defaultFileName,
        content: AppConstants.defaultFileContent,
      );
      HiveService.filesBox.put(defaultFile.id, defaultFile);
      state = FilesState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      final activeId = HiveService.settingsBox.get('activeFileId', defaultValue: boxFiles.first.id);
      state = FilesState(files: boxFiles, activeFileId: activeId);
    }
  }

  void setActiveFile(String id) {
    HiveService.settingsBox.put('activeFileId', id);
    state = state.copyWith(activeFileId: id);
  }

  void addFile(String name, String content) {
    final newFile = CodeFile(name: name, content: content);
    HiveService.filesBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
    HiveService.settingsBox.put('activeFileId', newFile.id);
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null) return;

    final updated = active.copyWith(content: content, lastModified: DateTime.now());

    // Update local state immediately for fast UI
    final newFiles = state.files.map((f) => f.id == active.id ? updated : f).toList();
    state = state.copyWith(files: newFiles);

    // Debounce save to Hive
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      HiveService.filesBox.put(updated.id, updated);
    });
  }

  void deleteActiveFile() {
    final active = state.activeFile;
    if (active == null) return;

    HiveService.filesBox.delete(active.id);

    final newFiles = state.files.where((f) => f.id != active.id).toList();

    if (newFiles.isEmpty) {
      final defaultFile = CodeFile(name: 'untitled.dart', content: '');
      HiveService.filesBox.put(defaultFile.id, defaultFile);
      state = FilesState(files: [defaultFile], activeFileId: defaultFile.id);
      HiveService.settingsBox.put('activeFileId', defaultFile.id);
    } else {
      state = FilesState(files: newFiles, activeFileId: newFiles.last.id);
      HiveService.settingsBox.put('activeFileId', newFiles.last.id);
    }
  }

  void renameActiveFile(String newName) {
    final active = state.activeFile;
    if (active == null) return;

    final updated = active.copyWith(name: newName);
    HiveService.filesBox.put(updated.id, updated);

    final newFiles = state.files.map((f) => f.id == active.id ? updated : f).toList();
    state = state.copyWith(files: newFiles);
  }
}

final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>((ref) {
  return FilesNotifier();
});
