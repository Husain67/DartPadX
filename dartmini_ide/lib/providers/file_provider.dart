import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/app_file.dart';

class FileState {
  final List<AppFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<AppFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<AppFile> _fileBox = Hive.box<AppFile>('files');

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  FileState get currentState => state;

  void _loadFiles() {
    final files = _fileBox.values.toList();
    if (files.isEmpty) {
      final defaultFile = AppFile(
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print("Hello, DartMini IDE!");
  print("Enter your name:");
  String? name = stdin.readLineSync();
  print("Welcome, \$name!");
}
''',
      );
      _fileBox.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }
    state = state.copyWith(
      files: files,
      activeFileId: files.first.id,
    );
  }

  void addFile(String name, {String content = ''}) {
    final newFile = AppFile(name: name, content: content);
    _fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final activeIndex = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (activeIndex != -1) {
      final activeFile = state.files[activeIndex];
      final updatedFile = activeFile.copyWith(content: content);

      _fileBox.put(updatedFile.id, updatedFile);

      final newFiles = List<AppFile>.from(state.files);
      newFiles[activeIndex] = updatedFile;

      state = state.copyWith(files: newFiles);
    }
  }

  void deleteFile(String id) {
    _fileBox.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();

    if (newFiles.isEmpty) {
      final newFile = AppFile(name: 'untitled.dart');
      _fileBox.put(newFile.id, newFile);
      newFiles.add(newFile);
    }

    state = state.copyWith(
      files: newFiles,
      activeFileId: state.activeFileId == id ? newFiles.last.id : state.activeFileId,
    );
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
