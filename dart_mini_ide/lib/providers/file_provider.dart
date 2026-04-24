import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

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
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> _box;
  Timer? _debounce;
  final _uuid = const Uuid();

  FileNotifier(this._box) : super(FileState(files: _box.values.toList())) {
    if (state.files.isEmpty) {
      _createNewDefaultFile();
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  void _createNewDefaultFile() {
    final id = _uuid.v4();
    final defaultFile = CodeFile(
      id: id,
      name: 'main.dart',
      content: '''void main() {
  print('Hello, DartMini!');
}
''',
    );
    _box.put(id, defaultFile);
    state = FileState(files: [defaultFile], activeFileId: id);
  }

  void createNewFile() {
    _forceSave(specificId: state.activeFileId);
    final id = _uuid.v4();
    final newFile = CodeFile(
      id: id,
      name: 'untitled_${state.files.length}.dart',
      content: '// New file\n',
    );
    _box.put(id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: id,
    );
  }

  void setActiveFile(String id) {
    _forceSave(specificId: state.activeFileId);
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((file) {
      if (file.id == activeId) {
        return file.copyWith(content: content);
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    if (_debounce?.isActive ?? false) _debounce?.cancel();
    // Bypass timer in tests
    if (const bool.hasEnvironment('FLUTTER_TEST')) {
      _forceSave(specificId: activeId);
    } else {
      _debounce = Timer(const Duration(seconds: 2), () {
        _forceSave(specificId: activeId);
      });
    }
  }

  void renameActiveFile(String newName) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((file) {
      if (file.id == activeId) {
        return file.copyWith(name: newName);
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);
    _forceSave(specificId: activeId);
  }

  void _forceSave({String? specificId}) {
    if (specificId == null) return;
    final file = state.files.firstWhere(
      (f) => f.id == specificId,
      orElse: () => CodeFile(id: '', name: '', content: ''),
    );
    if (file.id.isNotEmpty) {
      _box.put(file.id, file);
    }
  }

  void deleteFileById(String id) {
    _forceSave(specificId: state.activeFileId);
    _box.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();
    String? newActiveId;
    if (updatedFiles.isNotEmpty) {
      if (state.activeFileId == id) {
        newActiveId = updatedFiles.last.id;
      } else {
        newActiveId = state.activeFileId;
      }
      state = state.copyWith(files: updatedFiles, activeFileId: newActiveId);
    } else {
      _createNewDefaultFile();
    }
  }

  CodeFile? get activeFile {
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void forceUiUpdate() {
    state = state.copyWith(files: List.from(state.files));
  }
}

final fileBoxProvider = Provider<Box<CodeFile>>((ref) => throw UnimplementedError());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileNotifier(box);
});
