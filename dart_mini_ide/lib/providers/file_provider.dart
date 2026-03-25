import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../utils/constants.dart';

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

  CodeFile? get activeFile {
    if (activeFileId == null) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  Timer? _debounceTimer;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>('files');
    if (_box.isEmpty) {
      final initialFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: AppConstants.defaultDartCode,
      );
      await _box.put(initialFile.id, initialFile);
    }

    final files = _box.values.toList();
    state = FileState(
      files: files,
      activeFileId: files.isNotEmpty ? files.first.id : null,
    );
  }

  void newFile() {
    final newId = _uuid.v4();
    final newFile = CodeFile(
      id: newId,
      name: 'untitled_\${state.files.length + 1}.dart',
      content: 'void main() {\n  \n}',
    );
    _box.put(newId, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newId,
    );
  }

  void openFile(CodeFile file) {
    if (!state.files.any((f) => f.id == file.id)) {
      _box.put(file.id, file);
      state = state.copyWith(
        files: [...state.files, file],
        activeFileId: file.id,
      );
    } else {
      switchFile(file.id);
    }
  }

  void switchFile(String id) {
    if (state.activeFileId == id) return;
    _forceSaveCurrent();
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == activeId) {
        return f.copyWith(content: content);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      final updatedFile = updatedFiles.firstWhere((f) => f.id == activeId);
      _box.put(activeId, updatedFile);
    });
  }

  void renameActiveFile(String newName) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == activeId) {
        final renamed = f.copyWith(name: newName);
        _box.put(activeId, renamed);
        return renamed;
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    if (remainingFiles.isEmpty) {
      final newId = _uuid.v4();
      final newFile = CodeFile(
        id: newId,
        name: 'main.dart',
        content: AppConstants.defaultDartCode,
      );
      _box.put(newId, newFile);
      state = FileState(files: [newFile], activeFileId: newId);
    } else {
      final newActiveId = id == state.activeFileId
          ? remainingFiles.last.id
          : state.activeFileId;
      state = FileState(files: remainingFiles, activeFileId: newActiveId);
    }
  }

  void _forceSaveCurrent() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      final activeFile = state.activeFile;
      if (activeFile != null) {
        _box.put(activeFile.id, activeFile);
      }
    }
  }
}
