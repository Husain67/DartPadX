import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({
    required this.files,
    required this.activeFileId,
  });

  CodeFile? get activeFile {
    if (files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return files.first;
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
  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _loadFiles();
  }

  Box<CodeFile>? _box;
  Timer? _debounce;
  final _uuid = const Uuid();

  Future<void> _loadFiles() async {
    _box = Hive.box<CodeFile>('code_files');

    if (_box!.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini!');
}''',
      );
      await _box!.put(defaultFile.id, defaultFile);
    }

    final files = _box!.values.toList();
    state = FileState(files: files, activeFileId: files.first.id);
  }

  void setActiveFile(String id) {
    if (state.activeFileId == id) return;

    // Force save current before switching
    if (state.activeFile != null) {
      _forceSave(state.activeFile!);
    }

    state = state.copyWith(activeFileId: id);
  }

  void updateContent(String newContent) {
    if (state.activeFile == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        f.content = newContent;
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    if (const bool.hasEnvironment('FLUTTER_TEST')) {
        _forceSave(state.activeFile!);
    } else {
        _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 2), () {
          if (state.activeFile != null) {
            _forceSave(state.activeFile!);
          }
        });
    }
  }

  void _forceSave(CodeFile file) {
      _box?.put(file.id, file);
  }

  void createNewFile([String name = 'untitled.dart', String content = '']) {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: content,
    );
    _box?.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFileById(String id) {
    _box?.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    if (remainingFiles.isEmpty) {
      createNewFile();
      return;
    }

    String newActiveId = state.activeFileId;
    if (id == state.activeFileId) {
      newActiveId = remainingFiles.first.id;
    }

    state = state.copyWith(
      files: remainingFiles,
      activeFileId: newActiveId,
    );
  }

  void renameFile(String id, String newName) {
    final file = state.files.firstWhere((f) => f.id == id);
    file.name = newName;
    _box?.put(id, file);

    state = state.copyWith(
      files: state.files.map((f) => f.id == id ? file : f).toList(),
    );
  }
}
