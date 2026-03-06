import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  CodeFile? get activeFile => files.cast<CodeFile?>().firstWhere(
        (f) => f?.id == activeFileId,
        orElse: () => null,
      );

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

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CodeFile>('code_files');
    if (_box.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');

  // Example of simple loop
  for (int i = 0; i < 3; i++) {
    print('Iteration $i');
  }
}''',
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );
      await _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      final files = _box.values.toList();
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void createNewFile() {
    int count = state.files.where((f) => f.name.startsWith('untitled')).length;
    final name = count == 0 ? 'untitled.dart' : 'untitled$count.dart';

    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: '',
      lastModified: DateTime.now().millisecondsSinceEpoch,
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
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );

    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    final activeId = state.activeFileId;
    final files = [...state.files];
    final index = files.indexWhere((f) => f.id == activeId);

    if (index != -1) {
      final updatedFile = files[index].copyWith(
        content: content,
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );
      files[index] = updatedFile;
      _box.put(updatedFile.id, updatedFile); // Save to Hive
      state = state.copyWith(files: files);
    }
  }

  void deleteFileById(String id) {
    _box.delete(id);
    final files = [...state.files]..removeWhere((f) => f.id == id);

    if (files.isEmpty) {
      // Auto-create untitled if empty
      final newFile = CodeFile(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );
      _box.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      // Switch to adjacent tab
      final newActiveId = id == state.activeFileId ? files.last.id : state.activeFileId;
      state = state.copyWith(files: files, activeFileId: newActiveId);
    }
  }
}
