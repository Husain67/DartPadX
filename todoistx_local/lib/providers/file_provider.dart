import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

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
  late Box<CodeFile> _box;
  Timer? _saveTimer;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  void _init() {
    _box = Hive.box<CodeFile>('code_files');
    final files = _box.values.toList();

    if (files.isEmpty) {
      // Create default main.dart
      final newFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
      );
      _box.put(newFile.id, newFile);
      files.add(newFile);
    }

    state = FileState(files: files, activeFileId: files.first.id);
  }

  CodeFile? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void createNewFile(String name) {
    final newFile = CodeFile(id: _uuid.v4(), name: name, content: '');
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void importFile(String name, String content) {
    final newFile = CodeFile(id: _uuid.v4(), name: name, content: content);
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    // Update state immediately for UI
    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return f.copyWith(content: content);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      final fileToSave =
          updatedFiles.firstWhere((f) => f.id == state.activeFileId);
      _box.put(fileToSave.id, fileToSave);
    });
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId;
    if (remainingFiles.isNotEmpty) {
      newActiveId = remainingFiles.first.id;
    } else {
      // If empty, create untitled
      final newFile =
          CodeFile(id: _uuid.v4(), name: 'untitled.dart', content: '');
      _box.put(newFile.id, newFile);
      remainingFiles.add(newFile);
      newActiveId = newFile.id;
    }

    state = FileState(files: remainingFiles, activeFileId: newActiveId);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
