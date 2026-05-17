import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/code_file.dart';

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
  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = Hive.box<CodeFile>('files');
    final files = box.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        name: 'main.dart',
        content: '''import 'dart:io';

void main() {
  print("Hello DartMini!");
  print("Enter something in stdin:");
  String? input = stdin.readLineSync();
  print("You entered: \$input");
}
''',
      );
      box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
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
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void addFile(String name, String content) {
    final newFile = CodeFile(name: name, content: content);
    final box = Hive.box<CodeFile>('files');
    box.put(newFile.id, newFile);
    final updatedFiles = List<CodeFile>.from(state.files)..add(newFile);
    state = state.copyWith(files: updatedFiles, activeFileId: newFile.id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        final updatedFile = f.copyWith(content: content);
        final box = Hive.box<CodeFile>('files');
        box.put(f.id, updatedFile); // Save to Hive immediately
        return updatedFile;
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);
  }

  void forceSaveActiveFile() {
      // Intentionally exposed for manual forced saves if necessary
      if (state.activeFileId == null) return;
      final file = state.files.firstWhere((f) => f.id == state.activeFileId);
      final box = Hive.box<CodeFile>('files');
      box.put(file.id, file);
  }

  void deleteFile(String id) {
    final box = Hive.box<CodeFile>('files');
    box.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId;
    if (updatedFiles.isNotEmpty) {
      if (state.activeFileId == id) {
        newActiveId = updatedFiles.first.id;
      } else {
        newActiveId = state.activeFileId;
      }
    } else {
      // Auto-create new untitled if all are deleted
      final untitled = CodeFile(name: 'untitled.dart', content: '');
      box.put(untitled.id, untitled);
      updatedFiles.add(untitled);
      newActiveId = untitled.id;
    }

    state = state.copyWith(files: updatedFiles, activeFileId: newActiveId);
  }

  void triggerRebuild() {
     state = state.copyWith(files: List.from(state.files));
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
