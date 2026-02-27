import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/code_file.dart';

class FileRepository {
  final Box<CodeFile> _box;

  FileRepository(this._box);

  // Get all files from Hive, sorted by last modified (descending)
  List<CodeFile> getAllFiles() {
    if (_box.isEmpty) {
      // Create a default file if the box is empty
      final defaultFile = CodeFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'main.dart',
        content: '''void main() {
  print("Hello, DartMini IDE!");
}''',
        lastModified: DateTime.now(),
      );
      _box.put(defaultFile.id, defaultFile);
      return [defaultFile];
    }

    final files = _box.values.toList();
    files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return files;
  }

  // Create a new file
  Future<CodeFile> createFile({String? name, String? content}) async {
    final file = CodeFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name ?? 'untitled.dart',
      content: content ?? '',
      lastModified: DateTime.now(),
    );
    await _box.put(file.id, file);
    return file;
  }

  // Update an existing file
  Future<void> updateFile(CodeFile file) async {
    file.lastModified = DateTime.now();
    await _box.put(file.id, file);
  }

  // Delete a file by ID
  Future<void> deleteFile(String id) async {
    await _box.delete(id);
  }
}

// Provider for the FileRepository
final fileRepositoryProvider = Provider<FileRepository>((ref) {
  final box = Hive.box<CodeFile>('files');
  return FileRepository(box);
});

// State class for Files
class FilesState {
  final List<CodeFile> files;
  final CodeFile? activeFile;

  FilesState({
    required this.files,
    this.activeFile,
  });

  FilesState copyWith({
    List<CodeFile>? files,
    CodeFile? activeFile,
  }) {
    return FilesState(
      files: files ?? this.files,
      activeFile: activeFile ?? this.activeFile, // Can be null if we want to deselect
    );
  }
}

// StateNotifier for managing files
class FilesNotifier extends StateNotifier<FilesState> {
  final FileRepository _repository;

  FilesNotifier(this._repository) : super(FilesState(files: [])) {
    _loadInitialData();
  }

  void _loadInitialData() {
    final files = _repository.getAllFiles();
    state = FilesState(
      files: files,
      activeFile: files.isNotEmpty ? files.first : null,
    );
  }

  // Select a file to be active
  void setActiveFile(CodeFile file) {
    state = state.copyWith(activeFile: file);
  }

  // Update content of the active file (in memory for fast editing)
  void updateActiveFileContent(String newContent) {
    final currentFile = state.activeFile;
    if (currentFile != null) {
      // Update the object in memory.
      // Note: This mutates the object which is generally okay with Hive objects if careful,
      // but for Riverpod immutability, we should ideally treat it as immutable.
      // However, Hive objects are mutable. We'll update the content property.
      currentFile.content = newContent;

      // We don't save to Hive here to avoid disk I/O on every keystroke.
      // Auto-save logic will call saveActiveFile().
    }
  }

  // Persist the active file to Hive (Auto-save)
  Future<void> saveActiveFile() async {
    final currentFile = state.activeFile;
    if (currentFile != null) {
      await _repository.updateFile(currentFile);
      // No need to reload list as order might change only if we care about modified time immediately
      // But let's keep the list fresh if needed.
      // Actually, re-sorting might be distracting if the file jumps around.
      // Let's just save.
    }
  }

  // Create a new file
  Future<void> createNewFile() async {
    final newFile = await _repository.createFile(name: 'untitled_\${DateTime.now().millisecondsSinceEpoch}.dart');
    final files = _repository.getAllFiles();
    state = FilesState(files: files, activeFile: newFile);
  }

  // Import a file
  Future<void> importFile(String name, String content) async {
    final newFile = await _repository.createFile(name: name, content: content);
    final files = _repository.getAllFiles();
    state = FilesState(files: files, activeFile: newFile);
  }

  // Delete the active file
  Future<void> deleteActiveFile() async {
    final currentFile = state.activeFile;
    if (currentFile != null) {
      await _repository.deleteFile(currentFile.id);
      final files = _repository.getAllFiles();

      // Select the next available file or creating a new default one happens in getAllFiles if empty
      state = FilesState(
        files: files,
        activeFile: files.isNotEmpty ? files.first : null,
      );
    }
  }
}

// The main provider for files
final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>((ref) {
  final repo = ref.watch(fileRepositoryProvider);
  return FilesNotifier(repo);
});
