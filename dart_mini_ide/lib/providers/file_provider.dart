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
  late Box<CodeFile> _box;

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>('code_files');
    if (_box.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello, DartMini IDE!');\n}\n",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _box.put(defaultFile.id, defaultFile);
    }

    final files = _box.values.toList();
    if (files.isNotEmpty) {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  CodeFile? get activeFile {
    if (state.activeFileId.isEmpty) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void addFile({String name = 'untitled.dart', String content = ''}) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    _box.delete(id);
    final files = _box.values.toList();

    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      String newActiveId = state.activeFileId;
      if (id == state.activeFileId) {
        newActiveId = files.first.id;
      }
      state = FileState(files: files, activeFileId: newActiveId);
    }
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId.isEmpty) return;

    final file = _box.get(state.activeFileId);
    if (file != null) {
      file.content = content;
      file.updatedAt = DateTime.now();


      final updatedFiles = state.files.map((f) => f.id == state.activeFileId ? file : f).toList();
      state = state.copyWith(files: updatedFiles);
    }
  }

  void renameActiveFile(String newName) {
    if (state.activeFileId.isEmpty) return;

    final file = _box.get(state.activeFileId);
    if (file != null) {
      file.name = newName;
      file.updatedAt = DateTime.now();


      final updatedFiles = state.files.map((f) => f.id == state.activeFileId ? file : f).toList();
      state = state.copyWith(files: updatedFiles);
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) => FileNotifier());
