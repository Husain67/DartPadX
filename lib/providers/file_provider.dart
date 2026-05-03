import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../core/constants.dart';

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
    if (files.isEmpty) return null;
    return files.firstWhere(
      (f) => f.id == activeFileId,
      orElse: () => files.first,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  Timer? _autoSaveTimer;

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>(AppConstants.hiveFileBox);
    final files = _box.values.toList();

    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: AppConstants.defaultDartCode,
      );
      await _box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }

    state = FileState(files: files, activeFileId: files.first.id);
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void createNewFile() {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: 'untitled_${state.files.length + 1}.dart',
      content: '',
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void importFile(String name, String content) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    final activeFile = state.activeFile;
    if (activeFile == null) return;

    final updatedFile = activeFile.copyWith(content: content);

    final newFiles = state.files.map((f) {
      return f.id == updatedFile.id ? updatedFile : f;
    }).toList();

    // We update state immediately for UI, but debounce Hive save
    state = state.copyWith(files: newFiles);
    _scheduleAutoSave(updatedFile);
  }

  void renameActiveFile(String newName) {
    final activeFile = state.activeFile;
    if (activeFile == null) return;

    final updatedFile = activeFile.copyWith(name: newName);
    _box.put(updatedFile.id, updatedFile);

    final newFiles = state.files.map((f) {
      return f.id == updatedFile.id ? updatedFile : f;
    }).toList();

    state = state.copyWith(files: newFiles);
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    if (remainingFiles.isEmpty) {
      final newFile = CodeFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
      );
      _box.put(newFile.id, newFile);
      remainingFiles.add(newFile);
    }

    final newActiveId = (state.activeFileId == id)
        ? remainingFiles.last.id
        : state.activeFileId;

    state = state.copyWith(files: remainingFiles, activeFileId: newActiveId);
  }

  void _scheduleAutoSave(CodeFile file) {
    if (const bool.hasEnvironment('FLUTTER_TEST')) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(file.id, file);
    });
  }

  void forceSaveActiveFile() {
      final activeFile = state.activeFile;
      if (activeFile != null) {
          _box.put(activeFile.id, activeFile);
      }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
