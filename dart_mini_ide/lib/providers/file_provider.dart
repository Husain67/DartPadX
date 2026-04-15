import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({
    required this.files,
    this.activeFileId,
  });

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((file) => file.id == activeFileId);
    } catch (_) {
      return null;
    }
  }

  FileState copyWith({
    List<CodeFile>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  final _uuid = const Uuid();
  Timer? _debounceTimer;

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CodeFile>('code_files');
    if (_box.isEmpty) {
      _createDefaultFile();
    } else {
      final files = _box.values.toList();
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void _createDefaultFile() {
    final defaultFile = CodeFile(
      id: _uuid.v4(),
      name: 'main.dart',
      content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
      lastModified: DateTime.now(),
    );
    _box.put(defaultFile.id, defaultFile);
    state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
  }

  void createFile([String? name, String? content]) {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name ?? 'untitled.dart',
      content: content ?? '',
      lastModified: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: _box.values.toList(),
      activeFileId: newFile.id,
    );
  }

  void setActiveFile(String id) {
    // Flush current active file before switching
    if (state.activeFile != null) {
      forceSave(state.activeFileId!);
    }
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    // Update local state immediately for UI responsiveness
    final files = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return f.copyWith(content: content, lastModified: DateTime.now());
      }
      return f;
    }).toList();
    state = state.copyWith(files: files);

    // Debounce save to Hive
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      forceSave(state.activeFileId!);
    });
  }

  void forceSave(String id) {
    try {
      final file = state.files.firstWhere((f) => f.id == id);
      _box.put(id, file);
    } catch (_) {}
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remainingFiles = _box.values.toList();

    if (remainingFiles.isEmpty) {
      _createDefaultFile();
    } else {
      String? newActiveId = state.activeFileId;
      if (state.activeFileId == id) {
        newActiveId = remainingFiles.first.id;
      }
      state = state.copyWith(files: remainingFiles, activeFileId: newActiveId);
    }
  }
}
