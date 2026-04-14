import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/code_file.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  CodeFile? get activeFile {
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (e) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final StorageService storageService;
  Timer? _debounce;

  FileNotifier(this.storageService) : super(FileState(files: [], activeFileId: '')) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = storageService.getFiles();
    state = FileState(files: files, activeFileId: files.isNotEmpty ? files.first.id : '');
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      // Force save previous file if needed
      state = state.copyWith(activeFileId: id);
    }
  }

  void addFile(String name, {String content = ''}) {
    final newFile = CodeFile(name: name, content: content);
    storageService.saveFile(newFile);
    final newFiles = [...state.files, newFile];
    state = FileState(files: newFiles, activeFileId: newFile.id);
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId.isEmpty) return;

    final updatedFiles = state.files.map((file) {
      if (file.id == state.activeFileId) {
        final updated = file.copyWith(content: newContent);
        _scheduleSave(updated);
        return updated;
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);
  }

  void _scheduleSave(CodeFile file) {
    if (const bool.hasEnvironment('FLUTTER_TEST')) {
        storageService.saveFile(file);
        return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      storageService.saveFile(file);
    });
  }

  void forceSaveActive() {
     final file = state.activeFile;
     if (file != null) {
       storageService.saveFile(file);
     }
  }

  void deleteFile(String id) {
    storageService.deleteFile(id);
    final newFiles = state.files.where((f) => f.id != id).toList();

    String newActiveId = state.activeFileId;
    if (id == state.activeFileId) {
      if (newFiles.isNotEmpty) {
        newActiveId = newFiles.last.id;
      } else {
        // Auto-create untitled if empty
        final untitled = CodeFile(name: 'untitled.dart', content: '');
        storageService.saveFile(untitled);
        newFiles.add(untitled);
        newActiveId = untitled.id;
      }
    }

    state = FileState(files: newFiles, activeFileId: newActiveId);
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier(ref.read(storageServiceProvider));
});
