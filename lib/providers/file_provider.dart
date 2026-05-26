import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../services/storage_service.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

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
  Timer? _autoSaveTimer;
  String? _pendingSaveContent;

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final loadedFiles = StorageService.getFiles();
    if (loadedFiles.isEmpty) {
      final defaultFile = FileModel(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: "import 'dart:io';

void main() {
  print('Hello DartMini IDE!');

  // Example stdin reading
  // var input = stdin.readLineSync();
  // print('You entered: \$input');
}
",
      );
      StorageService.saveFile(defaultFile);
      state = state.copyWith(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = state.copyWith(
        files: loadedFiles,
        activeFileId: loadedFiles.first.id,
      );
    }
  }

  void createFile() {
    final newFile = FileModel(
      id: const Uuid().v4(),
      name: 'untitled.dart',
      content: '// Start coding here
',
    );
    StorageService.saveFile(newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void addFile(FileModel file) {
    StorageService.saveFile(file);
    state = state.copyWith(
      files: [...state.files, file],
      activeFileId: file.id,
    );
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;
    final index = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (index != -1) {
      _pendingSaveContent = content;
      // Update state immediately for UI, but don't hit disk yet
      final newFiles = List<FileModel>.from(state.files);
      newFiles[index] = newFiles[index].copyWith(content: content);
      state = state.copyWith(files: newFiles);

      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        if (_pendingSaveContent != null) {
          final updatedFile = state.files[index].copyWith(content: _pendingSaveContent);
          StorageService.saveFile(updatedFile);
          _pendingSaveContent = null;
        }
      });
    }
  }

  void forceUpdate() {
      state = state.copyWith(files: List.from(state.files));
  }

  Future<void> deleteActiveFile() async {
    if (state.activeFileId == null) return;
    await StorageService.deleteFile(state.activeFileId!);
    final newFiles = state.files.where((f) => f.id != state.activeFileId).toList();

    if (newFiles.isEmpty) {
      final defaultFile = FileModel(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '// Start coding here
',
      );
      await StorageService.saveFile(defaultFile);
      state = state.copyWith(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = state.copyWith(files: newFiles, activeFileId: newFiles.last.id);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  FileModel? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }
}
