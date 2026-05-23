import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<CodeFile>('files');
  return FileNotifier(box);
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
  final Box<CodeFile> _box;
  final _uuid = const Uuid();

  FileNotifier(this._box) : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');

  // Read input if available
  // String? input = stdin.readLineSync();
  // if (input != null) {
  //   print('You entered: \$input');
  // }
}
''',
        lastModified: DateTime.now(),
      );
      _box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }

    // Sort files by name
    files.sort((a, b) => a.name.compareTo(b.name));

    state = FileState(
      files: files,
      activeFileId: files.first.id,
    );
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

  void addFile(String name, String content) {
    final file = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    _box.put(file.id, file);

    final updatedFiles = [...state.files, file];
    updatedFiles.sort((a, b) => a.name.compareTo(b.name));

    state = state.copyWith(
      files: updatedFiles,
      activeFileId: file.id,
    );
  }

  void updateActiveFileContent(String content) {
    final file = activeFile;
    if (file == null || file.content == content) return;

    final updatedFile = file.copyWith(
      content: content,
      lastModified: DateTime.now(),
    );

    _box.put(file.id, updatedFile);

    final index = state.files.indexWhere((f) => f.id == file.id);
    final updatedFiles = List<CodeFile>.from(state.files);
    updatedFiles[index] = updatedFile;

    state = state.copyWith(files: updatedFiles);
  }

  void deleteActiveFile() {
    final fileId = state.activeFileId;
    if (fileId == null) return;

    _box.delete(fileId);

    final remainingFiles = state.files.where((f) => f.id != fileId).toList();
    if (remainingFiles.isEmpty) {
      // Create a default untitled file if everything is deleted
      addFile('untitled.dart', '');
    } else {
      state = state.copyWith(
        files: remainingFiles,
        activeFileId: remainingFiles.first.id,
      );
    }
  }
}
