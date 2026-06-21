import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/project_file.dart';

const String _defaultCode = '''void main() {
  print('Hello DartMini!');
}
''';

class FileState {
  final List<ProjectFile> files;
  final String? activeFileId;

  FileState({this.files = const [], this.activeFileId});

  FileState copyWith({List<ProjectFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  ProjectFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    return files.firstWhere((f) => f.id == activeFileId, orElse: () => files.first);
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<ProjectFile> _box;
  Timer? _saveTimer;

  FileNotifier(this._box) : super(FileState()) {
    _loadFiles();
  }

  FileState get currentState => state;

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final defaultFile = ProjectFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: _defaultCode,
        lastModified: DateTime.now(),
      );
      _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void addFile(String name, [String content = '']) {
    final newFile = ProjectFile(
      id: const Uuid().v4(),
      name: name,
      content: content.isEmpty ? _defaultCode : content,
      lastModified: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remaining = state.files.where((f) => f.id != id).toList();
    if (remaining.isEmpty) {
      final newFile = ProjectFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: _defaultCode,
        lastModified: DateTime.now(),
      );
      _box.put(newFile.id, newFile);
      state = state.copyWith(files: [newFile], activeFileId: newFile.id);
    } else {
      final newActiveId = state.activeFileId == id ? remaining.last.id : state.activeFileId;
      state = state.copyWith(files: remaining, activeFileId: newActiveId);
    }
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null) return;

    final updated = active.copyWith(content: content, lastModified: DateTime.now());

    final newFiles = state.files.map((f) => f.id == active.id ? updated : f).toList();
    state = state.copyWith(files: newFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(updated.id, updated);
    });
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void renameActiveFile(String newName) {
    final active = state.activeFile;
    if (active == null) return;
    final updated = active.copyWith(name: newName, lastModified: DateTime.now());
    _box.put(updated.id, updated);
    state = state.copyWith(
      files: state.files.map((f) => f.id == active.id ? updated : f).toList(),
    );
  }
}

final fileBoxProvider = Provider<Box<ProjectFile>>((ref) {
  return Hive.box<ProjectFile>('project_files');
});

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier(ref.watch(fileBoxProvider));
});
