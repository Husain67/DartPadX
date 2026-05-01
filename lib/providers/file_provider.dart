import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../services/hive_service.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({
    required this.files,
    this.activeFileId,
  });

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    return files.firstWhere((f) => f.id == activeFileId, orElse: () => files.first);
  }

  FileState copyWith({
    List<CodeFile>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late final Box<CodeFile> _box;

  FileNotifier() : super(FileState(files: [])) {
    _box = HiveService.filesBox;
    _loadFiles();
  }

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final initialFile = CodeFile(
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Hello DartMini!');
}
''',
      );
      _box.put(initialFile.id, initialFile);
      files.add(initialFile);
    }
    state = state.copyWith(
      files: files,
      activeFileId: files.first.id,
    );
  }

  void createNewFile() {
    final newFile = CodeFile(
      name: 'untitled.dart',
      content: '// New File',
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void switchFile(String id) {
    if (state.activeFileId != id) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String newContent) {
    final active = state.activeFile;
    if (active != null && active.content != newContent) {
      final updatedFile = active.copyWith(content: newContent);
      _box.put(updatedFile.id, updatedFile);
      final newFiles = state.files.map((f) => f.id == updatedFile.id ? updatedFile : f).toList();
      state = state.copyWith(files: newFiles);
    }
  }

  void forceUpdateFile(CodeFile updatedFile) {
    _box.put(updatedFile.id, updatedFile);
    final newFiles = state.files.map((f) => f.id == updatedFile.id ? updatedFile : f).toList();
    state = state.copyWith(files: newFiles);
  }

  void deleteActiveFile() {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    _box.delete(activeId);
    final updatedFiles = state.files.where((f) => f.id != activeId).toList();

    if (updatedFiles.isEmpty) {
      final newFile = CodeFile(
        name: 'untitled.dart',
        content: '// New File',
      );
      _box.put(newFile.id, newFile);
      updatedFiles.add(newFile);
    }

    state = state.copyWith(
      files: updatedFiles,
      activeFileId: updatedFiles.first.id,
    );
  }
}
