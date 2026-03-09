import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
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
  final Box<CodeFile> fileBox;

  FileNotifier(this.fileBox) : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = fileBox.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: 'void main() {\n  print(\'Hello World!\');\n}\n',
      );
      fileBox.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void createFile(String name, [String content = '']) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    if (state.files.length == 1) {
      // Don't delete the last file, just clear it or create a new untitled one
      fileBox.delete(id);
      final newFile = CodeFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
      );
      fileBox.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
      return;
    }

    final index = state.files.indexWhere((f) => f.id == id);
    if (index != -1) {
      fileBox.delete(id);
      final newFiles = List<CodeFile>.from(state.files)..removeAt(index);

      String newActiveId = state.activeFileId!;
      if (id == state.activeFileId) {
        if (index < newFiles.length) {
          newActiveId = newFiles[index].id;
        } else {
          newActiveId = newFiles.last.id;
        }
      }

      state = state.copyWith(
        files: newFiles,
        activeFileId: newActiveId,
      );
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateFileContent(String id, String content) {
    final file = fileBox.get(id);
    if (file != null) {
      file.content = content;
      file.save(); // Hive automatically persists

      // Update state so UI knows
      final newFiles = state.files.map((f) => f.id == id ? file : f).toList();
      state = state.copyWith(files: newFiles);
    }
  }

  void renameFile(String id, String newName) {
    final file = fileBox.get(id);
    if (file != null) {
      file.name = newName;
      file.save();
      final newFiles = state.files.map((f) => f.id == id ? file : f).toList();
      state = state.copyWith(files: newFiles);
    }
  }

  CodeFile? get activeFile {
    if (state.activeFileId == null) return null;
    return state.files.firstWhere(
      (f) => f.id == state.activeFileId,
      orElse: () => state.files.first,
    );
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<CodeFile>('codeFiles');
  return FileNotifier(box);
});
