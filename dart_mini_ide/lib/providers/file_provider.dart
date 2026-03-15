import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../models/preloaded_data.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  CodeFile? get activeFile => files.cast<CodeFile?>().firstWhere((f) => f?.id == activeFileId, orElse: () => null);

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  final Uuid _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>('filesBox');
    if (_box.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: PreloadedData.defaultCode,
      );
      await _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      final files = _box.values.toList();
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id && state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
    }
  }

  Future<void> addFile(String name, String content) async {
    final newFile = CodeFile(id: _uuid.v4(), name: name, content: content);
    await _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  Future<void> updateActiveFileContent(String newContent) async {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      final updatedFile = activeFile.copyWith(content: newContent);
      await _box.put(updatedFile.id, updatedFile);
      final newFiles = state.files.map((f) => f.id == updatedFile.id ? updatedFile : f).toList();
      state = state.copyWith(files: newFiles);
    }
  }

  Future<void> deleteFile(String id) async {
    await _box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    if (remainingFiles.isEmpty) {
      final newFile = CodeFile(id: _uuid.v4(), name: 'untitled.dart', content: '// New file');
      await _box.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      final nextId = remainingFiles.first.id;
      state = FileState(files: remainingFiles, activeFileId: nextId);
    }
  }
}
