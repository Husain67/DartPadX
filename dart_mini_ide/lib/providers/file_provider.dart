import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

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
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _debounceTimer;

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _initFiles();
  }

  Future<void> _initFiles() async {
    final box = Hive.box<CodeFile>('files');
    if (box.isEmpty) {
      final initialFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello DartMini IDE!');\n}\n",
        lastModified: DateTime.now(),
      );
      await box.put(initialFile.id, initialFile);
    }
    final files = box.values.toList();
    state = FileState(files: files, activeFileId: files.first.id);
  }

  void switchFile(String id) {
    if (state.activeFileId == id) return;
    _forceSave();
    state = state.copyWith(activeFileId: id);
  }

  void updateFileContent(String id, String newContent) {
    final files = List<CodeFile>.from(state.files);
    final index = files.indexWhere((f) => f.id == id);
    if (index != -1) {
      files[index] = files[index].copyWith(
        content: newContent,
        lastModified: DateTime.now(),
      );
      state = state.copyWith(files: files);
      _debounceSave(files[index]);
    }
  }

  void _debounceSave(CodeFile file) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      Hive.box<CodeFile>('files').put(file.id, file);
    });
  }

  void _forceSave() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      final activeFile = state.files.firstWhere((f) => f.id == state.activeFileId);
      Hive.box<CodeFile>('files').put(activeFile.id, activeFile);
    }
  }

  void addFile(String name, String content) {
    _forceSave();
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    Hive.box<CodeFile>('files').put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    if (state.files.length <= 1) {
      final newFile = CodeFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '// New File\n',
        lastModified: DateTime.now(),
      );
      Hive.box<CodeFile>('files').put(newFile.id, newFile);
      state = state.copyWith(files: [newFile], activeFileId: newFile.id);
      Hive.box<CodeFile>('files').delete(id);
      return;
    }
    final index = state.files.indexWhere((f) => f.id == id);
    String nextId = state.activeFileId;
    if (state.activeFileId == id) {
      nextId = state.files[index > 0 ? index - 1 : index + 1].id;
    }
    Hive.box<CodeFile>('files').delete(id);
    state = state.copyWith(
      files: state.files.where((f) => f.id != id).toList(),
      activeFileId: nextId,
    );
  }

  CodeFile? get activeFile {
    if (state.files.isEmpty) return null;
    return state.files.firstWhere(
      (f) => f.id == state.activeFileId,
      orElse: () => state.files.first,
    );
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
