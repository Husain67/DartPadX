import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../services/hive_service.dart';

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

  FileModel? get activeFile => files.where((f) => f.id == activeFileId).firstOrNull;
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  Timer? _autoSaveTimer;

  FileState get currentState => state;

  void _loadFiles() {
    List<FileModel> loadedFiles = HiveService.getFiles();
    String? activeId = HiveService.getActiveFileId();

    if (loadedFiles.isEmpty) {
      final newFile = FileModel(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');

  // Example of reading input
  // String? name = stdin.readLineSync();
  // print('Welcome \$name');
}
''',
      );
      HiveService.saveFile(newFile);
      loadedFiles = [newFile];
      activeId = newFile.id;
      HiveService.saveActiveFileId(activeId);
    }

    if (activeId == null || !loadedFiles.any((f) => f.id == activeId)) {
      activeId = loadedFiles.first.id;
      HiveService.saveActiveFileId(activeId);
    }

    state = FileState(files: loadedFiles, activeFileId: activeId);
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
    HiveService.saveActiveFileId(id);
  }

  void updateActiveFileContent(String newContent) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((file) {
      if (file.id == activeId) {
        return file.copyWith(content: newContent);
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      final fileToSave = updatedFiles.firstWhere((f) => f.id == activeId);
      HiveService.saveFile(fileToSave);
    });
  }

  void addFile(String name, {String content = ''}) {
    final newFile = FileModel(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    HiveService.saveFile(newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
    HiveService.saveActiveFileId(newFile.id);
  }

  void deleteFile(String id) {
    HiveService.deleteFile(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    if (remainingFiles.isEmpty) {
      final newFile = FileModel(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
      );
      HiveService.saveFile(newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
      HiveService.saveActiveFileId(newFile.id);
    } else {
      String? newActiveId = state.activeFileId;
      if (id == newActiveId) {
        newActiveId = remainingFiles.last.id;
        HiveService.saveActiveFileId(newActiveId);
      }
      state = state.copyWith(files: remainingFiles, activeFileId: newActiveId);
    }
  }

  void renameFile(String id, String newName) {
    final file = state.files.firstWhere((f) => f.id == id);
    final updatedFile = file.copyWith(name: newName);
    HiveService.saveFile(updatedFile);

    final updatedFiles = state.files.map((f) => f.id == id ? updatedFile : f).toList();
    state = state.copyWith(files: updatedFiles);
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
