import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/dart_file.dart';

class FileState {
  final List<DartFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<DartFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<DartFile> _box = Hive.box<DartFile>('dart_files');
  Timer? _debounceTimer;

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final initialFile = DartFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
        lastModified: DateTime.now(),
      );
      _box.put(initialFile.id, initialFile);
      state = FileState(files: [initialFile], activeFileId: initialFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  DartFile? get activeFile {
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

  void createFile(String name, {String content = ''}) {
    final newFile = DartFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateFileContent(String id, String content) {
    final index = state.files.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final updatedFile = DartFile(
      id: state.files[index].id,
      name: state.files[index].name,
      content: content,
      lastModified: DateTime.now(),
    );

    final newFiles = List<DartFile>.from(state.files);
    newFiles[index] = updatedFile;

    state = state.copyWith(files: newFiles);

    // Auto-save debounce
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _box.put(id, updatedFile);
    });
  }

  void deleteFile(String id) {
    _box.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();
    String? newActiveId;
    if (newFiles.isNotEmpty) {
      newActiveId = newFiles.last.id;
    } else {
      // Auto-create a new file if none are left
      final newFile = DartFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
        lastModified: DateTime.now(),
      );
      _box.put(newFile.id, newFile);
      newFiles.add(newFile);
      newActiveId = newFile.id;
    }
    state = state.copyWith(files: newFiles, activeFileId: newActiveId);
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
