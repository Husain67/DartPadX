import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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

  FileNotifier() : super(FileState(files: [])) {
    _box = Hive.box<CodeFile>('code_files');
    _loadFiles();
  }

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile.create(
        name: 'main.dart',
        content: 'void main() {\n  print("Hello, DartMini!");\n}\n',
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
    final newFile = CodeFile.create(name: name, content: content);
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    _box.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId;
    if (newFiles.isNotEmpty) {
      if (state.activeFileId == id) {
        newActiveId = newFiles.last.id;
      } else {
        newActiveId = state.activeFileId;
      }
    } else {
      // Auto-create untitled if empty
      final untitled = CodeFile.create(name: 'untitled.dart', content: '');
      _box.put(untitled.id, untitled);
      newFiles.add(untitled);
      newActiveId = untitled.id;
    }

    state = state.copyWith(files: newFiles, activeFileId: newActiveId);
  }

  void updateFileContent(String id, String newContent) {
    final file = _box.get(id);
    if (file != null) {
      file.content = newContent;
      file.save(); // Hive auto-save
      // We don't necessarily need to update state.files for every keystroke if UI uses controller,
      // but for consistency we can sync it or rely on Hive.
      final newFiles = state.files.map((f) => f.id == id ? file : f).toList();
      state = state.copyWith(files: newFiles);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  CodeFile? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }
}
