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

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    return files.firstWhere((file) => file.id == activeFileId,
        orElse: () => files.first);
  }

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _debounce;
  Box<CodeFile>? _box;

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>('code_files');
    final savedFiles = _box!.values.toList();

    if (savedFiles.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
      );
      await _box!.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: savedFiles, activeFileId: savedFiles.first.id);
    }
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      _forceSave();
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null) return;

    final updatedFile = active.copyWith(content: content);
    final updatedFiles = state.files.map((f) => f.id == active.id ? updatedFile : f).toList();

    state = state.copyWith(files: updatedFiles);

    if (const bool.hasEnvironment('FLUTTER_TEST')) {
      _box?.put(updatedFile.id, updatedFile);
    } else {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(seconds: 2), () {
        _box?.put(updatedFile.id, updatedFile);
      });
    }
  }

  void _forceSave() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      final active = state.activeFile;
      if (active != null) {
        _box?.put(active.id, active);
      }
    }
  }

  void createNewFile() {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: 'untitled.dart',
      content: '// New Dart file\n',
    );
    _box?.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteActiveFile() {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    _box?.delete(activeId);

    final remainingFiles = state.files.where((f) => f.id != activeId).toList();

    if (remainingFiles.isEmpty) {
      final newFile = CodeFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '// New Dart file\n',
      );
      _box?.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      state = FileState(files: remainingFiles, activeFileId: remainingFiles.last.id);
    }
  }

  void addFile(CodeFile file) {
     _box?.put(file.id, file);
     state = state.copyWith(
       files: [...state.files, file],
       activeFileId: file.id
     );
  }
}
