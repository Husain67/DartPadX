import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_mini_ide/core/models/code_file.dart';
import 'package:uuid/uuid.dart';

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

class EditorState {
  final List<CodeFile> files;
  final String? activeFileId;
  final bool isLoading;

  EditorState({
    this.files = const [],
    this.activeFileId,
    this.isLoading = true,
  });

  CodeFile? get activeFile {
    if (activeFileId == null) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }

  EditorState copyWith({
    List<CodeFile>? files,
    String? activeFileId,
    bool? isLoading,
  }) {
    return EditorState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(EditorState()) {
    _loadFiles();
  }

  late Box<CodeFile> _box;

  Future<void> _loadFiles() async {
    _box = Hive.box<CodeFile>('files');

    if (_box.isEmpty) {
      // Create default file
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, World!');

  // Try editing this code!
  for (var i = 0; i < 5; i++) {
    print('Count: \$i');
  }
}''',
        lastModified: DateTime.now(),
      );
      await _box.put(defaultFile.id, defaultFile);
    }

    final files = _box.values.toList();
    // Sort by name or last modified? Let's just keep insertion order or name for now.

    // Set active file to the first one if none selected
    final activeId = files.isNotEmpty ? files.first.id : null;

    state = state.copyWith(
      files: files,
      activeFileId: activeId,
      isLoading: false,
    );
  }

  Future<void> createNewFile() async {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: 'untitled_\${state.files.length + 1}.dart',
      content: '// New file\nvoid main() {\n  print("New file");\n}',
      lastModified: DateTime.now(),
    );

    await _box.put(newFile.id, newFile);

    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  Future<void> updateFileContent(String id, String newContent) async {
    final fileIndex = state.files.indexWhere((f) => f.id == id);
    if (fileIndex == -1) return;

    final updatedFile = state.files[fileIndex].copyWith(
      content: newContent,
      lastModified: DateTime.now(),
    );

    // Optimistic update
    final newFiles = [...state.files];
    newFiles[fileIndex] = updatedFile;
    state = state.copyWith(files: newFiles);

    // Save to Hive (debouncing could be added here or in the UI)
    await _box.put(id, updatedFile);
  }

  Future<void> renameFile(String id, String newName) async {
    final fileIndex = state.files.indexWhere((f) => f.id == id);
    if (fileIndex == -1) return;

    final updatedFile = state.files[fileIndex].copyWith(
      name: newName,
      lastModified: DateTime.now(),
    );

    final newFiles = [...state.files];
    newFiles[fileIndex] = updatedFile;
    state = state.copyWith(files: newFiles);

    await _box.put(id, updatedFile);
  }

  Future<void> deleteFile(String id) async {
    await _box.delete(id);

    final newFiles = state.files.where((f) => f.id != id).toList();
    String? newActiveId = state.activeFileId;

    if (state.activeFileId == id) {
      if (newFiles.isNotEmpty) {
        newActiveId = newFiles.first.id;
      } else {
        // Create a new file if all deleted
        final defaultFile = CodeFile(
          id: const Uuid().v4(),
          name: 'main.dart',
          content: 'void main() {\n  print("Hello World");\n}',
          lastModified: DateTime.now(),
        );
        await _box.put(defaultFile.id, defaultFile);
        newFiles.add(defaultFile);
        newActiveId = defaultFile.id;
      }
    }

    state = state.copyWith(
      files: newFiles,
      activeFileId: newActiveId,
    );
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  Future<void> importFile(String name, String content) async {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );

    await _box.put(newFile.id, newFile);

    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }
}
