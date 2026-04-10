import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  CodeFile? get activeFile =>
      files.cast<CodeFile?>().firstWhere((f) => f?.id == activeFileId, orElse: () => null);
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  Timer? _autoSaveTimer;

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CodeFile>('code_files');
    if (_box.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
      );
      await _box.put(defaultFile.id, defaultFile);
    }

    final files = _box.values.toList();
    state = FileState(files: files, activeFileId: files.isNotEmpty ? files.first.id : null);
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      forceSaveCurrent();
      state = state.copyWith(activeFileId: id);
    }
  }

  void addFile({String name = 'untitled.dart', String content = ''}) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      activeFile.content = content;

      // Auto-save debounce
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        _box.put(activeFile.id, activeFile);
      });

      // Update state without full re-render
      // We rely on activeFile mutation for editor, but state update triggers listeners
      state = state.copyWith(files: [...state.files]);
    }
  }

  void forceSaveCurrent() {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      _autoSaveTimer?.cancel();
      _box.put(activeFile.id, activeFile);
    }
  }

  void renameActiveFile(String newName) {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      activeFile.name = newName;
      _box.put(activeFile.id, activeFile);
      state = state.copyWith(files: [...state.files]);
    }
  }

  void deleteFile(String id) {
    _box.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();
    String? newActiveId = state.activeFileId;

    if (id == state.activeFileId) {
      newActiveId = newFiles.isNotEmpty ? newFiles.last.id : null;
    }

    if (newFiles.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
      );
      _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: newFiles, activeFileId: newActiveId);
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
