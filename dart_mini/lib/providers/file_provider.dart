import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../core/constants.dart';
import 'hive_provider.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({
    required this.files,
    this.activeFileId,
  });

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
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _autoSaveTimer;

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
    _startAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _loadFiles() {
    final box = HiveService.filesBox;
    List<FileModel> loadedFiles = box.values.toList();

    if (loadedFiles.isEmpty) {
      final initialFile = FileModel(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: AppConstants.initialMainDartContent,
        lastModified: DateTime.now(),
      );
      box.put(initialFile.id, initialFile);
      loadedFiles = [initialFile];
    }

    // Sort by last modified
    loadedFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    state = state.copyWith(
      files: loadedFiles,
      activeFileId: loadedFiles.first.id,
    );
  }

  void _startAutoSave() {
    // Only run if not in test env to avoid timeout issues
    if (const bool.hasEnvironment('FLUTTER_TEST')) return;

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _saveCurrentStateToHive();
    });
  }

  void _saveCurrentStateToHive() {
    final box = HiveService.filesBox;
    for (var file in state.files) {
      box.put(file.id, file);
    }
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      // Force save previous file before switching
      _saveCurrentStateToHive();
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return f.copyWith(
          content: newContent,
          lastModified: DateTime.now(),
        );
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);
  }

  void createNewFile([String? name, String? content]) {
    final fileName = name ?? 'untitled_${state.files.length}.dart';
    final newFile = FileModel(
      id: const Uuid().v4(),
      name: fileName,
      content: content ?? '',
      lastModified: DateTime.now(),
    );

    final updatedFiles = List<FileModel>.from(state.files)..add(newFile);
    HiveService.filesBox.put(newFile.id, newFile);

    state = state.copyWith(
      files: updatedFiles,
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    HiveService.filesBox.delete(id);

    final updatedFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId;
    if (updatedFiles.isNotEmpty) {
       newActiveId = updatedFiles.last.id;
    }

    state = state.copyWith(
      files: updatedFiles,
      activeFileId: newActiveId,
    );

    if (updatedFiles.isEmpty) {
        createNewFile('main.dart', AppConstants.initialMainDartContent);
    }
  }

  void forceUpdate() {
     state = state.copyWith(files: List.from(state.files));
  }
}
