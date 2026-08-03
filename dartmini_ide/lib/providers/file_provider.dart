import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/file_model.dart';

class FileState {
  final List<FileModel> files;
  final String activeFileName;

  FileState({required this.files, required this.activeFileName});

  FileModel? get activeFile {
    if (files.isEmpty) return null;
    return files.firstWhere((f) => f.name == activeFileName, orElse: () => files.first);
  }

  FileState copyWith({
    List<FileModel>? files,
    String? activeFileName,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileName: activeFileName ?? this.activeFileName,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<FileModel> _box;

  FileNotifier(this._box) : super(FileState(files: _box.values.toList(), activeFileName: '')) {
    if (state.files.isEmpty) {
      final defaultFile = FileModel(
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Hello, DartMini!');

  // Example reading from stdin
  // String? input = stdin.readLineSync();
  // print("You entered: \$input");
}
''',
        lastSaved: DateTime.now(),
      );
      _box.put(defaultFile.name, defaultFile);
      state = state.copyWith(
        files: [defaultFile],
        activeFileName: defaultFile.name,
      );
    } else {
      state = state.copyWith(activeFileName: state.files.first.name);
    }
  }

  void setActiveFile(String name) {
    if (state.files.any((f) => f.name == name)) {
      state = state.copyWith(activeFileName: name);
    }
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active != null) {
      final updated = active.copyWith(content: content, lastSaved: DateTime.now());
      _box.put(updated.name, updated);
      final newFiles = state.files.map((f) => f.name == updated.name ? updated : f).toList();
      state = state.copyWith(files: newFiles);
    }
  }

  void addNewFile(String name, [String content = '']) {
    if (!state.files.any((f) => f.name == name)) {
      final newFile = FileModel(name: name, content: content, lastSaved: DateTime.now());
      _box.put(name, newFile);
      state = state.copyWith(
        files: [...state.files, newFile],
        activeFileName: name,
      );
    } else {
      setActiveFile(name);
    }
  }

  void deleteFile(String name) {
    _box.delete(name);
    final newFiles = state.files.where((f) => f.name != name).toList();
    if (newFiles.isEmpty) {
      final fallback = FileModel(name: 'untitled.dart', content: '', lastSaved: DateTime.now());
      _box.put(fallback.name, fallback);
      state = state.copyWith(
        files: [fallback],
        activeFileName: fallback.name,
      );
    } else {
      state = state.copyWith(
        files: newFiles,
        activeFileName: state.activeFileName == name ? newFiles.last.name : state.activeFileName,
      );
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<FileModel>('files');
  return FileNotifier(box);
});
