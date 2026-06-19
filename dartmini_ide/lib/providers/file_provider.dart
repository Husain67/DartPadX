import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/code_file.dart';
import '../services/hive_service.dart';

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> _box;
  Timer? _saveTimer;

  FileNotifier(this._box) : super(FileState(files: [])) {
    _loadFiles();
  }

  FileState get currentState => state;

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isNotEmpty) {
      files.sort((a, b) => a.lastModified.compareTo(b.lastModified));
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void addFile(CodeFile file) {
    _box.put(file.id, file);
    final updatedFiles = [...state.files, file];
    state = state.copyWith(files: updatedFiles, activeFileId: file.id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final index = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (index != -1) {
      final file = state.files[index];
      final updatedFile = file.copyWith(
        content: content,
        lastModified: DateTime.now(),
      );

      final updatedFiles = List<CodeFile>.from(state.files);
      updatedFiles[index] = updatedFile;

      state = state.copyWith(files: updatedFiles);

      // Debounce save to Hive
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), () {
        _box.put(updatedFile.id, updatedFile);
      });
    }
  }

  void updateFileName(String id, String newName) {
    final index = state.files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final file = state.files[index];
      final updatedFile = file.copyWith(name: newName);
      _box.put(updatedFile.id, updatedFile);

      final updatedFiles = List<CodeFile>.from(state.files);
      updatedFiles[index] = updatedFile;

      state = state.copyWith(files: updatedFiles);
    }
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void deleteFile(String id) {
    _box.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId;
    if (updatedFiles.isNotEmpty) {
      newActiveId = updatedFiles.last.id;
    }

    state = FileState(files: updatedFiles, activeFileId: newActiveId);
  }

  CodeFile? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (e) {
      return null;
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<CodeFile>(HiveService.filesBoxName);
  return FileNotifier(box);
});
