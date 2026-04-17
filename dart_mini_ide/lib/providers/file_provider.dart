import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

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
  final _uuid = const Uuid();

  FileNotifier(this._box) : super(FileState(files: _box.values.toList())) {
    if (state.files.isEmpty) {
      _createDefaultFile();
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  void _createDefaultFile() {
    final file = CodeFile(
      id: _uuid.v4(),
      name: 'main.dart',
      content: "void main() {\n  print('Hello, DartMini IDE!');\n}\n",
    );
    _box.put(file.id, file);
    state = FileState(files: [file], activeFileId: file.id);
  }

  CodeFile? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateContent(String content) {
    final file = activeFile;
    if (file != null) {
      file.content = content;
      file.save(); // HiveObject save

      final newFiles = state.files.map((f) => f.id == file.id ? file : f).toList();
      state = state.copyWith(files: newFiles);
    }
  }

  void createFile(String name, {String content = ''}) {
    final file = CodeFile(id: _uuid.v4(), name: name, content: content);
    _box.put(file.id, file);
    state = state.copyWith(
      files: [...state.files, file],
      activeFileId: file.id,
    );
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remaining = state.files.where((f) => f.id != id).toList();

    String? nextId;
    if (remaining.isNotEmpty) {
      if (state.activeFileId == id) {
        nextId = remaining.first.id;
      } else {
        nextId = state.activeFileId;
      }
    }

    state = state.copyWith(files: remaining, activeFileId: nextId);

    if (remaining.isEmpty) {
      _createDefaultFile();
    }
  }
}

final fileBoxProvider = Provider<Box<CodeFile>>((ref) => Hive.box<CodeFile>('files'));

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier(ref.read(fileBoxProvider));
});
