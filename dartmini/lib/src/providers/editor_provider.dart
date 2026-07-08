import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/editor_file.dart';

const String _editorFilesBoxName = 'editor_files';
const String _activeFileIdKey = 'active_file_id';

class EditorState {
  final List<EditorFile> files;
  final String? activeFileId;

  EditorState({required this.files, this.activeFileId});

  EditorFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (e) {
      return null;
    }
  }

  EditorState copyWith({List<EditorFile>? files, String? activeFileId}) {
    return EditorState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  final Box<EditorFile> _filesBox = Hive.box<EditorFile>(_editorFilesBoxName);
  final Box _settingsBox = Hive.box('settings');
  Timer? _debounceTimer;

  EditorNotifier() : super(EditorState(files: [])) {
    _init();
  }

  void _init() {
    List<EditorFile> loadedFiles = _filesBox.values.toList();
    String? activeId = _settingsBox.get(_activeFileIdKey);

    if (loadedFiles.isEmpty) {
      final defaultFile = EditorFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: "import 'dart:io';\n\nvoid main() {\n  print('Enter your name:');\n  String? name = stdin.readLineSync();\n  print('Hello, $name! Welcome to DartMini IDE!');\n}\n",
      );
      _filesBox.put(defaultFile.id, defaultFile);
      loadedFiles = [defaultFile];
      activeId = defaultFile.id;
      _settingsBox.put(_activeFileIdKey, activeId);
    }

    if (activeId != null && !loadedFiles.any((f) => f.id == activeId)) {
      activeId = loadedFiles.first.id;
      _settingsBox.put(_activeFileIdKey, activeId);
    }

    state = EditorState(files: loadedFiles, activeFileId: activeId);
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      _settingsBox.put(_activeFileIdKey, id);
      state = state.copyWith(activeFileId: id);
    }
  }

  void addFile(String name, String content) {
    final newFile = EditorFile(id: const Uuid().v4(), name: name, content: content);
    _filesBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
    _settingsBox.put(_activeFileIdKey, newFile.id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return f.copyWith(content: content);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      final activeFile = state.activeFile;
      if (activeFile != null) {
        _filesBox.put(activeFile.id, activeFile);
      }
    });
  }

  void deleteFile(String id) {
    _filesBox.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      if (updatedFiles.isNotEmpty) {
        newActiveId = updatedFiles.first.id;
      } else {
        newActiveId = null;
      }
    }

    if (updatedFiles.isEmpty) {
      final newFile = EditorFile(id: const Uuid().v4(), name: 'untitled.dart', content: '');
      _filesBox.put(newFile.id, newFile);
      updatedFiles.add(newFile);
      newActiveId = newFile.id;
    }

    state = state.copyWith(files: updatedFiles, activeFileId: newActiveId);
    if (newActiveId != null) {
      _settingsBox.put(_activeFileIdKey, newActiveId);
    }
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});
