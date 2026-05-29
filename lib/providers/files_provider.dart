import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_model.dart';
import '../utils/hive_setup.dart';

class FilesState {
  final List<FileModel> files;
  final String? activeFileId;

  FilesState({required this.files, this.activeFileId});

  FilesState copyWith({
    List<FileModel>? files,
    String? activeFileId,
  }) {
    return FilesState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FilesNotifier extends StateNotifier<FilesState> {
  Timer? _debounceTimer;

  FilesNotifier() : super(FilesState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = HiveSetup.filesBox;
    final List<FileModel> loadedFiles = box.values.toList();

    if (loadedFiles.isEmpty) {
      final defaultFile = FileModel(
        name: 'main.dart',
        content: "import 'dart:io';\n\nvoid main() {\n  print('Hello, DartMini IDE!');\n  // String? input = stdin.readLineSync();\n  // print('You typed: \$input');\n}\n",
      );
      box.put(defaultFile.id, defaultFile);
      loadedFiles.add(defaultFile);
    }

    final settingsBox = HiveSetup.settingsBox;
    String? lastActiveId = settingsBox.get('activeFileId');

    if (lastActiveId == null || !loadedFiles.any((f) => f.id == lastActiveId)) {
      lastActiveId = loadedFiles.first.id;
    }

    state = FilesState(files: loadedFiles, activeFileId: lastActiveId);
  }

  FileModel? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void setActiveFile(String id) {
    HiveSetup.settingsBox.put('activeFileId', id);
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId == null) return;

    final files = List<FileModel>.from(state.files);
    final index = files.indexWhere((f) => f.id == state.activeFileId);

    if (index != -1) {
      files[index] = files[index].copyWith(
        content: newContent,
        lastModified: DateTime.now(),
      );

      state = state.copyWith(files: files);

      // Auto-save logic
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        HiveSetup.filesBox.put(files[index].id, files[index]);
      });
    }
  }

  void updateActiveFileName(String newName) {
    if (state.activeFileId == null) return;

    final files = List<FileModel>.from(state.files);
    final index = files.indexWhere((f) => f.id == state.activeFileId);

    if (index != -1) {
      files[index] = files[index].copyWith(name: newName, lastModified: DateTime.now());
      state = state.copyWith(files: files);
      HiveSetup.filesBox.put(files[index].id, files[index]);
    }
  }

  void createNewFile({String name = 'untitled.dart', String content = ''}) {
    final newFile = FileModel(name: name, content: content);
    HiveSetup.filesBox.put(newFile.id, newFile);

    final newFiles = List<FileModel>.from(state.files)..add(newFile);
    state = state.copyWith(files: newFiles, activeFileId: newFile.id);
    HiveSetup.settingsBox.put('activeFileId', newFile.id);
  }

  void deleteFile(String id) {
    HiveSetup.filesBox.delete(id);

    final newFiles = List<FileModel>.from(state.files)..removeWhere((f) => f.id == id);

    if (newFiles.isEmpty) {
      state = state.copyWith(files: [], activeFileId: null);
      createNewFile(); // Auto-create untitled
    } else {
      final newActiveId = id == state.activeFileId ? newFiles.first.id : state.activeFileId;
      state = state.copyWith(files: newFiles, activeFileId: newActiveId);
      HiveSetup.settingsBox.put('activeFileId', newActiveId);
    }
  }
}

final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>((ref) {
  return FilesNotifier();
});
