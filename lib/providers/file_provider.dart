import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_style/dart_style.dart';
import '../models/models.dart';

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
  Timer? _saveTimer;
  final Box<CodeFile> _box = Hive.box<CodeFile>('files');
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
      );
      _box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }
    state = FileState(
      files: files,
      activeFileId: files.first.id,
    );
  }

  void addFile(String name, String content) {
    final newFile = CodeFile(id: _uuid.v4(), name: name, content: content);
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void setActiveFile(String id) {
    _forceSave();
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    final activeFile = state.activeFile;
    if (activeFile == null) return;

    final updatedFile = activeFile.copyWith(content: content);
    final fileIndex = state.files.indexWhere((f) => f.id == activeFile.id);
    if (fileIndex != -1) {
      final newFiles = List<CodeFile>.from(state.files);
      newFiles[fileIndex] = updatedFile;
      state = state.copyWith(files: newFiles);
      _debouncedSave(updatedFile);
    }
  }

  void _debouncedSave(CodeFile file) {
    if (const bool.hasEnvironment('FLUTTER_TEST')) {
      _box.put(file.id, file);
      return;
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(file.id, file);
    });
  }

  void _forceSave() {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      _box.put(activeFile.id, activeFile);
    }
    _saveTimer?.cancel();
  }

  void deleteFile(String id) {
    _box.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();
    String? nextActiveId;
    if (newFiles.isNotEmpty) {
      if (state.activeFileId == id) {
        nextActiveId = newFiles.last.id;
      } else {
        nextActiveId = state.activeFileId;
      }
    } else {
      // Auto create untitled if empty
      final newFile = CodeFile(id: _uuid.v4(), name: 'untitled.dart', content: '');
      _box.put(newFile.id, newFile);
      newFiles.add(newFile);
      nextActiveId = newFile.id;
    }
    state = state.copyWith(files: newFiles, activeFileId: nextActiveId);
  }

  void formatActiveFile() {
    final activeFile = state.activeFile;
    if (activeFile == null) return;
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formatted = formatter.format(activeFile.content);
      updateActiveFileContent(formatted);
      // Force riverpod rebuild for flutter_code_editor
      state = state.copyWith(files: List.from(state.files));
    } catch (e) {
      // Ignore formatting errors (likely syntax error)
    }
  }

  void forceUpdate() {
     state = state.copyWith(files: List.from(state.files));
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
