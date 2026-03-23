import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile => files.where((f) => f.id == activeFileId).firstOrNull;

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>('files');
    var files = _box.values.toList();

    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
        lastModified: DateTime.now(),
      );
      await _box.put(defaultFile.id, defaultFile);
      files = [defaultFile];
    }

    state = FileState(files: files, activeFileId: files.first.id);
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  Future<void> createFile(String name, {String content = ''}) async {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    await _box.put(newFile.id, newFile);
    state = FileState(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  Future<void> deleteFile(String id) async {
    await _box.delete(id);
    final remaining = state.files.where((f) => f.id != id).toList();

    if (remaining.isEmpty) {
      // Create new untitled if none left
      await createFile('untitled.dart');
    } else {
      String? nextActiveId = state.activeFileId;
      if (id == state.activeFileId) {
        final index = state.files.indexWhere((f) => f.id == id);
        if (index > 0) {
          nextActiveId = state.files[index - 1].id;
        } else {
          nextActiveId = remaining.first.id;
        }
      }
      state = FileState(files: remaining, activeFileId: nextActiveId);
    }
  }

  Future<void> updateActiveContent(String content) async {
    final active = state.activeFile;
    if (active != null) {
      active.content = content;
      active.lastModified = DateTime.now();
      await _box.put(active.id, active);

      final index = state.files.indexWhere((f) => f.id == active.id);
      final newFiles = List<CodeFile>.from(state.files);
      newFiles[index] = active;
      state = state.copyWith(files: newFiles);
    }
  }
}
