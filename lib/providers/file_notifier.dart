import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<FileModel>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _saveTimer;
  late Box<FileModel> _box;

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  FileState get currentState => state;

  Future<void> _init() async {
    _box = Hive.box<FileModel>('files');
    final files = _box.values.toList();

    if (files.isEmpty) {
      final defaultFile = FileModel(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');

  // Example of reading stdin
  // print("Enter your name:");
  // String? name = stdin.readLineSync();
  // print("Hello, \$name!");
}
''',
      );
      await _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final updatedFiles = state.files.map((file) {
      if (file.id == state.activeFileId) {
        return file.copyWith(content: content);
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      final activeFile = state.files.firstWhere((f) => f.id == state.activeFileId);
      _box.put(activeFile.id, activeFile);
    });
  }

  void createNewFile() {
    int index = 1;
    String newName = 'untitled.dart';
    while (state.files.any((f) => f.name == newName)) {
      newName = 'untitled_$index.dart';
      index++;
    }

    final newFile = FileModel(
      id: const Uuid().v4(),
      name: newName,
      content: '// \$newName\n\nvoid main() {\n  \n}\n',
    );

    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void importFile(String name, String content) {
    final newFile = FileModel(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    _box.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    if (updatedFiles.isEmpty) {
      final newFile = FileModel(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
      );
      _box.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      final newActiveId = id == state.activeFileId ? updatedFiles.first.id : state.activeFileId;
      state = FileState(files: updatedFiles, activeFileId: newActiveId);
    }
  }

  void renameFile(String id, String newName) {
     final updatedFiles = state.files.map((file) {
      if (file.id == id) {
        final renamed = file.copyWith(name: newName);
        _box.put(id, renamed);
        return renamed;
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
