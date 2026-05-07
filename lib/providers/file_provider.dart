import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_file.dart';

class FileState {
  final List<AppFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({
    List<AppFile>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  AppFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  static const String _boxName = 'dartmini_files';
  static const String _activeIdKey = 'active_file_id';
  late Box _box;
  Timer? _debounceTimer;

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox(_boxName);

    List<AppFile> loadedFiles = [];
    for (var key in _box.keys) {
      if (key == _activeIdKey) continue;
      final map = _box.get(key);
      if (map != null && map is Map) {
        loadedFiles.add(AppFile.fromMap(map));
      }
    }

    if (loadedFiles.isEmpty) {
      final defaultFile = AppFile(
        name: 'main.dart',
        content: '''void main() {
  print("Hello from DartMini IDE!");
}''',
      );
      loadedFiles.add(defaultFile);
      await _box.put(defaultFile.id, defaultFile.toMap());
    }

    final activeId = _box.get(_activeIdKey) as String?;

    // Validate activeId
    String? validActiveId;
    if (activeId != null && loadedFiles.any((f) => f.id == activeId)) {
      validActiveId = activeId;
    } else if (loadedFiles.isNotEmpty) {
      validActiveId = loadedFiles.first.id;
    }

    state = FileState(files: loadedFiles, activeFileId: validActiveId);
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
      _box.put(_activeIdKey, id);
    }
  }

  void addFile(AppFile file) {
    final newFiles = [...state.files, file];
    state = state.copyWith(files: newFiles, activeFileId: file.id);
    _box.put(file.id, file.toMap());
    _box.put(_activeIdKey, file.id);
  }

  void updateActiveFileContent(String content) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == activeId) {
        return f.copyWith(content: content);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      final activeFile = state.activeFile;
      if (activeFile != null) {
        _box.put(activeFile.id, activeFile.toMap());
      }
    });
  }

  void forceSaveActiveFile() {
     _debounceTimer?.cancel();
     final activeFile = state.activeFile;
     if (activeFile != null) {
        _box.put(activeFile.id, activeFile.toMap());
     }
  }

  void deleteFile(String id) {
    final newFiles = state.files.where((f) => f.id != id).toList();

    if (newFiles.isEmpty) {
      final newFile = AppFile(name: 'untitled.dart', content: '');
      newFiles.add(newFile);
      _box.put(newFile.id, newFile.toMap());
    }

    String? newActiveId;
    if (state.activeFileId == id) {
      newActiveId = newFiles.last.id;
    } else {
      newActiveId = state.activeFileId;
    }

    state = FileState(files: newFiles, activeFileId: newActiveId);

    _box.delete(id);
    _box.put(_activeIdKey, newActiveId);
  }

  void triggerUIRefresh() {
    state = state.copyWith(files: List.from(state.files));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
