import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import '../models/file_model.dart';

class FileState {
  final List<FileModel> files;
  final int activeIndex;

  FileState({required this.files, required this.activeIndex});

  FileModel? get activeFile => files.isNotEmpty && activeIndex < files.length ? files[activeIndex] : null;

  FileState copyWith({List<FileModel>? files, int? activeIndex}) {
    return FileState(
      files: files ?? this.files,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [], activeIndex: 0)) {
    _loadFiles();
  }

  Box<FileModel>? _box;
  Timer? _autoSaveTimer;

  Future<void> _loadFiles() async {
    _box = await Hive.openBox<FileModel>('files');
    if (_box!.isEmpty) {
      final mainFile = FileModel(
        name: 'main.dart',
        content: '''void main() {
  print("Hello, DartMini IDE!");
  print("This is a beta version.");
}''',
        lastModified: DateTime.now(),
      );
      await _box!.add(mainFile);
    }
    state = FileState(files: _box!.values.toList(), activeIndex: 0);
  }

  Future<void> addFile(String name, [String? content]) async {
    final newFile = FileModel(
      name: name,
      content: content ?? '',
      lastModified: DateTime.now(),
    );
    await _box!.add(newFile);
    state = state.copyWith(files: _box!.values.toList(), activeIndex: _box!.length - 1);
  }

  Future<void> deleteFile(int index) async {
    if (index >= 0 && index < state.files.length) {
      await state.files[index].delete();
      final newFiles = _box!.values.toList();
      int newIndex = state.activeIndex;

      if (newIndex >= newFiles.length) {
        newIndex = newFiles.length - 1;
      }

      if (newFiles.isEmpty) {
         await addFile('untitled.dart');
         return;
      }

      state = state.copyWith(files: newFiles, activeIndex: newIndex);
    }
  }

  void setActiveFile(int index) {
    if (index >= 0 && index < state.files.length) {
      state = state.copyWith(activeIndex: index);
    }
  }

  void updateFileContent(String content) {
    final currentFile = state.activeFile;
    if (currentFile != null) {
      currentFile.content = content;
      currentFile.lastModified = DateTime.now();

      // Auto-save logic
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        currentFile.save();
      });
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
