import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/editor_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<EditorFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<EditorFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  EditorFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  late Box _box;
  Timer? _saveTimer;

  static const String _defaultCode = '''import 'dart:io';

void main() {
  print('Hello, DartMini!');

  // Example reading from stdin
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Welcome, \$name!');
}''';

  Future<void> _loadFiles() async {
    _box = Hive.box('filesBox');

    List<EditorFile> loadedFiles = [];
    final keys = _box.keys;
    for (var key in keys) {
      final map = Map<String, dynamic>.from(_box.get(key));
      loadedFiles.add(EditorFile.fromMap(map));
    }

    if (loadedFiles.isEmpty) {
      final defaultFile = EditorFile(name: 'main.dart', content: _defaultCode);
      loadedFiles.add(defaultFile);
      _box.put(defaultFile.id, defaultFile.toMap());
    }

    String? activeId = Hive.box('settingsBox').get('activeFileId');
    if (activeId == null || !loadedFiles.any((f) => f.id == activeId)) {
      activeId = loadedFiles.first.id;
    }

    state = FileState(files: loadedFiles, activeFileId: activeId);
  }

  void addFile(EditorFile file) {
    final newFiles = [...state.files, file];
    _box.put(file.id, file.toMap());
    Hive.box('settingsBox').put('activeFileId', file.id);
    state = state.copyWith(files: newFiles, activeFileId: file.id);
  }

  void importFile(String name, String content) {
    final file = EditorFile(name: name, content: content);
    addFile(file);
  }

  void deleteFile(String id) {
    _box.delete(id);
    final newFiles = state.files.where((f) => f.id != id).toList();

    if (newFiles.isEmpty) {
      final defaultFile = EditorFile(name: 'untitled.dart', content: '');
      newFiles.add(defaultFile);
      _box.put(defaultFile.id, defaultFile.toMap());
    }

    String? newActiveId;
    if (state.activeFileId == id) {
      newActiveId = newFiles.last.id;
    } else {
      newActiveId = state.activeFileId;
    }

    Hive.box('settingsBox').put('activeFileId', newActiveId);
    state = state.copyWith(files: newFiles, activeFileId: newActiveId);
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      Hive.box('settingsBox').put('activeFileId', id);
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String newContent) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == activeId) {
        return f.copyWith(content: newContent, isSaved: false);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);
    _debounceSave(activeId, newContent);
  }

  void updateActiveFileName(String newName) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == activeId) {
        final updated = f.copyWith(name: newName);
        _box.put(updated.id, updated.toMap());
        return updated;
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);
  }

  void _debounceSave(String id, String content) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      final file = state.files.firstWhere((f) => f.id == id);
      final savedFile = file.copyWith(content: content, isSaved: true);

      _box.put(savedFile.id, savedFile.toMap());

      if (state.activeFileId == id) { // ensure active file hasn't changed
         final updatedFiles = state.files.map((f) {
            if (f.id == id) return savedFile;
            return f;
         }).toList();
         state = state.copyWith(files: updatedFiles);
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
