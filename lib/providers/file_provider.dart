import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<FileModel>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<FileModel> _box = Hive.box<FileModel>('files');
  final Uuid _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  void _init() {
    List<FileModel> savedFiles = _box.values.toList();

    if (savedFiles.isEmpty) {
      final initialFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Enter your name:');
  String? userName = stdin.readLineSync();
  print('Hello, \$userName!');
}
''',
        language: 'dart',
      );
      _box.put(initialFile.id, initialFile);
      savedFiles = [initialFile];
    }

    state = FileState(files: savedFiles, activeFileId: savedFiles.first.id);
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void addFile(String name, String content, String language) {
    final newFile = FileModel(
      id: _uuid.v4(),
      name: name,
      content: content,
      language: language,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateFileContent(String id, String newContent) {
    final index = state.files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final updatedFile = state.files[index].copyWith(content: newContent);
      _box.put(id, updatedFile);

      final newFiles = List<FileModel>.from(state.files);
      newFiles[index] = updatedFile;
      state = state.copyWith(files: newFiles);
    }
  }

  void updateFileName(String id, String newName) {
      final index = state.files.indexWhere((f) => f.id == id);
      if (index != -1) {
        final updatedFile = state.files[index].copyWith(name: newName);
        _box.put(id, updatedFile);

        final newFiles = List<FileModel>.from(state.files);
        newFiles[index] = updatedFile;
        state = state.copyWith(files: newFiles);
      }
    }

  void deleteFile(String id) {
    _box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      newActiveId = remainingFiles.isNotEmpty ? remainingFiles.first.id : null;
    }

    if (remainingFiles.isEmpty) {
        final newUntitled = FileModel(
          id: _uuid.v4(),
          name: 'untitled.dart',
          content: '',
          language: 'dart',
        );
        _box.put(newUntitled.id, newUntitled);
        remainingFiles.add(newUntitled);
        newActiveId = newUntitled.id;
    }

    state = state.copyWith(files: remainingFiles, activeFileId: newActiveId);
  }

  FileModel? get activeFile {
      if (state.activeFileId == null) return null;
      try {
        return state.files.firstWhere((f) => f.id == state.activeFileId);
      } catch (_) {
          return null;
      }
  }

  void forceUpdate() {
      state = state.copyWith(files: List.from(state.files));
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
