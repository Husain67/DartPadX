import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_style/dart_style.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final CodeFile? activeFile;

  FileState({
    required this.files,
    this.activeFile,
  });

  FileState copyWith({
    List<CodeFile>? files,
    CodeFile? activeFile,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFile: activeFile ?? this.activeFile,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _debounce;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [], activeFile: null)) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = Hive.box<CodeFile>('code_files');
    var loadedFiles = box.values.toList();
    if (loadedFiles.isEmpty) {
      final initialFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: 'void main() {\n  print("Hello, DartMini IDE!");\n}\n',
        lastModified: DateTime.now(),
      );
      box.put(initialFile.id, initialFile);
      loadedFiles = [initialFile];
    }

    // Sort files by name
    loadedFiles.sort((a, b) => a.name.compareTo(b.name));

    final activeFileId = Hive.box('settings').get('active_file_id');
    final activeFile = loadedFiles.firstWhere(
      (f) => f.id == activeFileId,
      orElse: () => loadedFiles.first,
    );

    state = FileState(files: loadedFiles, activeFile: activeFile);
  }

  void setActiveFile(CodeFile file) {
    Hive.box('settings').put('active_file_id', file.id);
    state = state.copyWith(activeFile: file);
  }

  void newFile() {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: 'untitled_${state.files.length + 1}.dart',
      content: '',
      lastModified: DateTime.now(),
    );
    Hive.box<CodeFile>('code_files').put(newFile.id, newFile);
    _loadFiles();
    setActiveFile(newFile);
  }

  void deleteFile(CodeFile file) {
    Hive.box<CodeFile>('code_files').delete(file.id);
    _loadFiles();
  }

  void updateActiveFileContent(String content) {
    if (state.activeFile == null) return;

    final updatedFile = state.activeFile!.copyWith(
      content: content,
      lastModified: DateTime.now(),
    );

    // Update state immediately for UI responsiveness
    final index = state.files.indexWhere((f) => f.id == updatedFile.id);
    if (index != -1) {
      final newFiles = List<CodeFile>.from(state.files);
      newFiles[index] = updatedFile;
      state = state.copyWith(activeFile: updatedFile, files: newFiles);
    }

    // Auto-save debounce (2 seconds)
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      Hive.box<CodeFile>('code_files').put(updatedFile.id, updatedFile);
    });
  }

  void importFile(String name, String content) {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    Hive.box<CodeFile>('code_files').put(newFile.id, newFile);
    _loadFiles();
    setActiveFile(newFile);
  }

  void formatActiveFile() {
    if (state.activeFile == null) return;
    try {
      final formatter = DartFormatter();
      final formatted = formatter.format(state.activeFile!.content);
      updateActiveFileContent(formatted);
    } catch (e) {
      // If code cannot be formatted (e.g. syntax error), fail silently or log
      print('Formatting error: $e');
    }
  }
}
