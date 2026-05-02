import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

const String _defaultCode = '''
void main() {
  print("Hello from DartMini IDE!");
}
''';

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  CodeFile? get activeFile {
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> _box;
  final _uuid = const Uuid();
  Timer? _autoSaveTimer;

  FileNotifier(this._box) : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  void _init() {
    final storedFiles = _box.values.toList();
    if (storedFiles.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: _defaultCode,
      );
      _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: storedFiles, activeFileId: storedFiles.first.id);
    }

    _autoSaveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _saveCurrentToHive();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _saveCurrentToHive() {
    final active = state.activeFile;
    if (active != null) {
      _box.put(active.id, active);
    }
  }

  void forceSave(String specificId) {
    final fileToSave = state.files.cast<CodeFile?>().firstWhere(
          (f) => f?.id == specificId,
          orElse: () => null,
        );
    if (fileToSave != null) {
      _box.put(fileToSave.id, fileToSave);
    }
  }

  void setActiveFile(String id) {
    forceSave(state.activeFileId);
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    final files = List<CodeFile>.from(state.files);
    final index = files.indexWhere((f) => f.id == state.activeFileId);
    if (index != -1) {
      files[index] = files[index].copyWith(content: content);
      state = state.copyWith(files: files);
    }
  }

  void createNewFile() {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: 'untitled_${state.files.length}.dart',
      content: '// New Dart file\n',
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void importFile(String name, String content) {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: content,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFileById(String id) {
    _box.delete(id);
    final files = state.files.where((f) => f.id != id).toList();
    if (files.isEmpty) {
      final newFile = CodeFile(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '// New Dart file\n',
      );
      _box.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      final newActiveId =
          id == state.activeFileId ? files.last.id : state.activeFileId;
      state = FileState(files: files, activeFileId: newActiveId);
    }
  }

  void renameActiveFile(String newName) {
    final files = List<CodeFile>.from(state.files);
    final index = files.indexWhere((f) => f.id == state.activeFileId);
    if (index != -1) {
      files[index] = files[index].copyWith(name: newName);
      state = state.copyWith(files: files);
      _box.put(files[index].id, files[index]);
    }
  }
}

final fileBoxProvider = Provider<Box<CodeFile>>((ref) {
  throw UnimplementedError('fileBoxProvider must be overridden');
});

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileNotifier(box);
});
