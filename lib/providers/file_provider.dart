import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

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
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> _box;
  Timer? _debounceTimer;

  FileNotifier(this._box) : super(FileState(files: [], activeFileId: '')) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''import 'dart:io';

void main() {
  print('Hello, DartMini!');

  // Read from stdin example
  String? name = stdin.readLineSync();
  if (name != null && name.isNotEmpty) {
    print('Welcome, \$name!');
  }
}''',
      );
      _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  CodeFile? get activeFile {
    if (state.activeFileId.isEmpty) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      forceSaveCurrent(); // Flush previous before switching
      state = state.copyWith(activeFileId: id);
    }
  }

  void addFile({String? name, String? content}) {
    forceSaveCurrent(); // Flush before adding new
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name ?? 'untitled.dart',
      content: content ?? '',
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content, {bool forceSave = false}) {
    if (state.activeFileId.isEmpty) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return f.copyWith(content: content);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    if (forceSave) {
      _debounceTimer?.cancel();
      final currentFile = updatedFiles.firstWhere((f) => f.id == state.activeFileId);
      _box.put(currentFile.id, currentFile);
    } else {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        final currentFile = updatedFiles.firstWhere((f) => f.id == state.activeFileId);
        _box.put(currentFile.id, currentFile);
      });
    }
  }

  void forceSaveCurrent() {
     _debounceTimer?.cancel();
     if (activeFile != null) {
       _box.put(activeFile!.id, activeFile!);
     }
  }

  void renameFile(String id, String newName) {
    final updatedFiles = state.files.map((f) {
      if (f.id == id) {
        final updated = f.copyWith(name: newName);
        _box.put(id, updated);
        return updated;
      }
      return f;
    }).toList();
    state = state.copyWith(files: updatedFiles);
  }

  void deleteFile(String id) {
    _box.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    String newActiveId = '';
    if (updatedFiles.isNotEmpty) {
      // Find the adjacent file
      final index = state.files.indexWhere((f) => f.id == id);
      if (index > 0) {
        newActiveId = updatedFiles[index - 1].id;
      } else {
        newActiveId = updatedFiles[0].id;
      }
    }

    state = state.copyWith(files: updatedFiles, activeFileId: newActiveId);

    if (updatedFiles.isEmpty) {
      addFile(name: 'untitled.dart');
    }
  }
}

final fileBoxProvider = Provider<Box<CodeFile>>((ref) => throw UnimplementedError());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileNotifier(box);
});
