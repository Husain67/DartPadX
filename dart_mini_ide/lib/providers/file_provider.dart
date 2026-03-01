import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../services/storage_service.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile =>
      files.where((f) => f.id == activeFileId).firstOrNull;

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  final _uuid = const Uuid();
  final _box = StorageService.filesBox;

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final initialFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
        lastModified: DateTime.now(),
      );
      _box.put(initialFile.id, initialFile);
      files.add(initialFile);
    }
    state = FileState(files: files, activeFileId: files.first.id);
  }

  void createFile(String name) {
    String finalName = name;
    if (!name.endsWith('.dart')) finalName += '.dart';

    final newFile = CodeFile(
      id: _uuid.v4(),
      name: finalName,
      content: '',
      lastModified: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId == null) return;
    final file = _box.get(state.activeFileId);
    if (file != null) {
      file.content = newContent;
      file.lastModified = DateTime.now();
      file.save();

      final updatedFiles = state.files.map((f) => f.id == file.id ? file : f).toList();
      state = state.copyWith(files: updatedFiles);
    }
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void deleteFile(String id) {
    _box.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      newActiveId = updatedFiles.isNotEmpty ? updatedFiles.first.id : null;
    }

    if (updatedFiles.isEmpty) {
      final newFile = CodeFile(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
        lastModified: DateTime.now(),
      );
      _box.put(newFile.id, newFile);
      updatedFiles.add(newFile);
      newActiveId = newFile.id;
    }

    state = state.copyWith(files: updatedFiles, activeFileId: newActiveId);
  }
}
