import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_model.dart';
import '../services/hive_service.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({
    this.files = const [],
    this.activeFileId,
  });

  FileState copyWith({
    List<FileModel>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState()) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = HiveService.filesBox;
    final files = box.values.toList();

    if (files.isEmpty) {
      // Create default main.dart if no files exist
      final defaultFile = FileModel(
        name: 'main.dart',
        content: '''import 'dart:io';\n\nvoid main() {\n  print('Hello from DartMini!');\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}''',
      );
      box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }

    // Sort by created date
    files.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    state = state.copyWith(
      files: files,
      activeFileId: files.isNotEmpty ? files.first.id : null,
    );
  }

  FileModel? get activeFile {
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

  void addFile(String name, [String content = '']) {
    final newFile = FileModel(name: name, content: content);
    HiveService.filesBox.put(newFile.id, newFile);

    final updatedFiles = List<FileModel>.from(state.files)..add(newFile);
    state = state.copyWith(
      files: updatedFiles,
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    final active = activeFile;
    if (active != null) {
      active.content = content;
      active.save(); // Save to Hive

      // Force riverpod update
      state = state.copyWith(files: List.from(state.files));
    }
  }

  void deleteFile(String id) {
    HiveService.filesBox.delete(id);
    final updatedFiles = List<FileModel>.from(state.files)..removeWhere((f) => f.id == id);

    String? newActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      newActiveId = updatedFiles.isNotEmpty ? updatedFiles.first.id : null;
    }

    state = state.copyWith(
      files: updatedFiles,
      activeFileId: newActiveId,
    );

    // If we deleted the last file, create a new untitled one automatically
    if (updatedFiles.isEmpty) {
      addFile('untitled.dart');
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
