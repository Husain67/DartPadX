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

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  late Box<CodeFile> _fileBox;
  Timer? _saveTimer;
  final _uuid = const Uuid();

  Future<void> _loadFiles() async {
    _fileBox = Hive.box<CodeFile>('codeFiles');
    final files = _fileBox.values.toList();

    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
      );
      await _fileBox.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }

    state = FileState(
      files: files,
      activeFileId: files.first.id,
    );
  }

  void setActiveFile(String id) {
    _forceSaveCurrent();
    state = state.copyWith(activeFileId: id);
  }

  void _forceSaveCurrent() {
    final currentFile = state.activeFile;
    if (currentFile != null) {
      currentFile.save();
    }
  }

  void createNewFile([String? name, String? content]) {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name ?? 'untitled.dart',
      content: content ?? '',
    );
    _fileBox.put(newFile.id, newFile);

    final updatedFiles = List<CodeFile>.from(state.files)..add(newFile);
    state = FileState(files: updatedFiles, activeFileId: newFile.id);
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null) return;

    active.content = content;

    // Auto-save logic
    _saveTimer?.cancel();
    if (const bool.hasEnvironment('FLUTTER_TEST')) {
      active.save();
    } else {
      _saveTimer = Timer(const Duration(seconds: 2), () {
        active.save();
      });
    }
  }

  void updateActiveFileName(String name) {
    final active = state.activeFile;
    if (active == null) return;

    active.name = name;
    active.save();

    // trigger rebuild
    state = state.copyWith(files: List.from(state.files));
  }

  void deleteFile(String id) {
    _fileBox.delete(id);

    final updatedFiles = state.files.where((f) => f.id != id).toList();
    String? newActiveId;

    if (updatedFiles.isNotEmpty) {
      newActiveId = updatedFiles.first.id;
    } else {
      // Auto create untitled if we deleted the last file
      final newFile = CodeFile(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
      );
      _fileBox.put(newFile.id, newFile);
      updatedFiles.add(newFile);
      newActiveId = newFile.id;
    }

    state = FileState(files: updatedFiles, activeFileId: newActiveId);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
