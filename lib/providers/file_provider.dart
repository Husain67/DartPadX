import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  CodeFile? get activeFile {
    if (activeFileId.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CodeFile>('code_files');
    if (_box.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
      );
      await _box.put(defaultFile.id, defaultFile);
    }

    final files = _box.values.toList();
    final activeId = files.isNotEmpty ? files.first.id : '';
    state = FileState(files: files, activeFileId: activeId);
  }

  void newFile() {
    final newId = _uuid.v4();
    final newFile = CodeFile(
      id: newId,
      name: 'untitled.dart',
      content: '// New file\n',
    );
    _box.put(newId, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newId,
    );
  }

  void addFile(String name, String content) {
    final newId = _uuid.v4();
    final newFile = CodeFile(
      id: newId,
      name: name,
      content: content,
    );
    _box.put(newId, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newId,
    );
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId.isEmpty) return;

    final currentFile = state.activeFile;
    if (currentFile != null && currentFile.content != newContent) {
      currentFile.content = newContent;
      _box.put(currentFile.id, currentFile);

      // Keep state in sync without losing reference
      // We don't recreate the entire list to avoid UI jumps, but we trigger notify.
      state = state.copyWith(files: List.from(state.files));
    }
  }

  void updateActiveFileName(String newName) {
    if (state.activeFileId.isEmpty) return;

    final currentFile = state.activeFile;
    if (currentFile != null && currentFile.name != newName) {
      currentFile.name = newName;
      _box.put(currentFile.id, currentFile);
      state = state.copyWith(files: List.from(state.files));
    }
  }

  void deleteFileById(String id) {
    _box.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();

    String newActiveId = state.activeFileId;
    if (id == state.activeFileId) {
      if (newFiles.isNotEmpty) {
        newActiveId = newFiles.last.id;
      } else {
        // If empty, create a new one
        final newId = _uuid.v4();
        final newFile = CodeFile(
          id: newId,
          name: 'untitled.dart',
          content: '',
        );
        _box.put(newId, newFile);
        newFiles.add(newFile);
        newActiveId = newId;
      }
    }

    state = FileState(files: newFiles, activeFileId: newActiveId);
  }
}
