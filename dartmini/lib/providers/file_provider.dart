import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

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
  FileNotifier() : super(FileState(files: []));

  Box<CodeFile>? _box;
  Timer? _saveTimer;

  FileState get currentState => state;

  Future<void> init() async {
    _box = Hive.box<CodeFile>('filesBox');
    List<CodeFile> initialFiles = _box!.values.toList();

    if (initialFiles.isEmpty) {
      final defaultFile = CodeFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'main.dart',
        content: "import 'dart:io';\n\nvoid main() {\n  print('Hello, DartMini!');\n  \n  // Example of reading input:\n  // String? input = stdin.readLineSync();\n  // print('You typed: \$input');\n}\n",
        lastModified: DateTime.now(),
      );
      _box!.put(defaultFile.id, defaultFile);
      initialFiles.add(defaultFile);
    }

    state = state.copyWith(files: initialFiles, activeFileId: initialFiles.first.id);
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId == null || _box == null) return;

    final currentFile = state.files.firstWhere((f) => f.id == state.activeFileId);
    if (currentFile.content == newContent) return;

    final updatedFile = currentFile.copyWith(
      content: newContent,
      lastModified: DateTime.now(),
    );

    final updatedList = state.files.map((f) => f.id == updatedFile.id ? updatedFile : f).toList();
    state = state.copyWith(files: updatedList);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box!.put(updatedFile.id, updatedFile);
    });
  }

  void createNewFile(String name) {
    if (_box == null) return;
    final newFile = CodeFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      content: '// $name\nvoid main() {\n  \n}\n',
      lastModified: DateTime.now(),
    );

    _box!.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void importFile(String name, String content) {
    if (_box == null) return;
    final newFile = CodeFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );

    _box!.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteActiveFile() {
    if (state.activeFileId == null || _box == null) return;

    _box!.delete(state.activeFileId);
    final remainingFiles = state.files.where((f) => f.id != state.activeFileId).toList();

    if (remainingFiles.isEmpty) {
      final defaultFile = CodeFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'untitled.dart',
        content: "void main() {\n  \n}\n",
        lastModified: DateTime.now(),
      );
      _box!.put(defaultFile.id, defaultFile);
      state = state.copyWith(
        files: [defaultFile],
        activeFileId: defaultFile.id,
      );
    } else {
      state = state.copyWith(
        files: remainingFiles,
        activeFileId: remainingFiles.last.id,
      );
    }
  }
}
