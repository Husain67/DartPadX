import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({
    this.files = const [],
    this.activeFileId,
  });

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
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
  FileNotifier() : super(FileState()) {
    _loadFiles();
  }

  late Box<CodeFile> _fileBox;
  Timer? _debounceTimer;

  void _loadFiles() {
    _fileBox = Hive.box<CodeFile>('files');
    if (_fileBox.isEmpty) {
      final initialFile = CodeFile.create(
        name: 'main.dart',
        content: '''void main() {
  print('Welcome to DartMini IDE!');
  print('Everything runs perfectly on mobile.');
}''',
      );
      _fileBox.put(initialFile.id, initialFile);
    }

    final files = _fileBox.values.toList();
    state = state.copyWith(
      files: files,
      activeFileId: files.isNotEmpty ? files.first.id : null,
    );
  }

  void setActiveFile(String id) {
    if (state.activeFileId == id) return;
    _forceSave(); // Save current before switching
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String newContent) {
    final active = state.activeFile;
    if (active == null) return;

    // Update local state immediately for fast typing
    final updatedFile = active.copyWith(content: newContent);
    final newFiles = state.files.map((f) => f.id == active.id ? updatedFile : f).toList();
    state = state.copyWith(files: newFiles);

    // Debounce save to Hive
    _debounceTimer?.cancel();
    if (const bool.hasEnvironment('FLUTTER_TEST')) {
      _fileBox.put(updatedFile.id, updatedFile); // Synchronous for tests
    } else {
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        _fileBox.put(updatedFile.id, updatedFile);
      });
    }
  }

  void _forceSave() {
    _debounceTimer?.cancel();
    final active = state.activeFile;
    if (active != null) {
      _fileBox.put(active.id, active);
    }
  }

  void createNewFile() {
    final newFile = CodeFile.create();
    _fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void importFile(String name, String content) {
    final newFile = CodeFile.create(name: name, content: content);
    _fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    _fileBox.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId = state.activeFileId;
    if (newActiveId == id) {
      newActiveId = newFiles.isNotEmpty ? newFiles.last.id : null;
    }

    if (newFiles.isEmpty) {
      final newFile = CodeFile.create();
      _fileBox.put(newFile.id, newFile);
      newFiles.add(newFile);
      newActiveId = newFile.id;
    }

    state = state.copyWith(files: newFiles, activeFileId: newActiveId);
  }
}
