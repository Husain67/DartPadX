import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/code_file.dart';
import '../data/hive_repository.dart';
import '../data/shared_prefs_repository.dart';
import '../core/constants.dart';

final sharedPrefsProvider = Provider<SharedPrefsRepository>((ref) => throw UnimplementedError());
final hiveRepoProvider = Provider<HiveRepository>((ref) => HiveRepository());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier(ref.watch(hiveRepoProvider), ref.watch(sharedPrefsProvider));
});

class FileState {
  final List<CodeFile> files;
  final String? currentFileId;

  FileState({this.files = const [], this.currentFileId});

  CodeFile? get currentFile {
    if (currentFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((file) => file.id == currentFileId);
    } catch (_) {
      return files.first;
    }
  }

  FileState copyWith({List<CodeFile>? files, String? currentFileId}) {
    return FileState(
      files: files ?? this.files,
      currentFileId: currentFileId ?? this.currentFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final HiveRepository _hiveRepo;
  final SharedPrefsRepository _prefsRepo;
  Timer? _debounceTimer;

  FileNotifier(this._hiveRepo, this._prefsRepo) : super(FileState()) {
    _loadFiles();
  }

  void _loadFiles() {
    List<CodeFile> loadedFiles = _hiveRepo.getFiles();
    if (loadedFiles.isEmpty) {
      final newFile = CodeFile(
        id: const Uuid().v4(),
        name: AppConstants.defaultFileName,
        content: AppConstants.defaultCode,
      );
      _hiveRepo.saveFile(newFile);
      loadedFiles = [newFile];
    }

    String? savedCurrentId = _prefsRepo.getCurrentFileId();
    if (savedCurrentId == null || !loadedFiles.any((f) => f.id == savedCurrentId)) {
      savedCurrentId = loadedFiles.first.id;
      _prefsRepo.setCurrentFileId(savedCurrentId);
    }

    state = FileState(files: loadedFiles, currentFileId: savedCurrentId);
  }

  void selectFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      _prefsRepo.setCurrentFileId(id);
      state = state.copyWith(currentFileId: id);
    }
  }

  void createFile([String name = 'untitled.dart', String content = '']) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    _hiveRepo.saveFile(newFile);

    final newFiles = List<CodeFile>.from(state.files)..add(newFile);
    _prefsRepo.setCurrentFileId(newFile.id);

    state = FileState(files: newFiles, currentFileId: newFile.id);
  }

  void updateCurrentFileContent(String newContent) {
    final current = state.currentFile;
    if (current == null) return;

    final updatedFile = current.copyWith(content: newContent, lastModified: DateTime.now());

    final updatedFiles = state.files.map((f) => f.id == current.id ? updatedFile : f).toList();
    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive (every 2 seconds)
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _hiveRepo.saveFile(updatedFile);
    });
  }

  void renameCurrentFile(String newName) {
    final current = state.currentFile;
    if (current == null) return;

    final updatedFile = current.copyWith(name: newName, lastModified: DateTime.now());

    final updatedFiles = state.files.map((f) => f.id == current.id ? updatedFile : f).toList();
    state = state.copyWith(files: updatedFiles);
    _hiveRepo.saveFile(updatedFile);
  }

  void deleteCurrentFile() {
    final currentId = state.currentFileId;
    if (currentId == null) return;

    deleteFileById(currentId);
  }

  void deleteFileById(String id) {
    _hiveRepo.deleteFile(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    if (remainingFiles.isEmpty) {
      createFile();
    } else {
      String nextId = state.currentFileId ?? remainingFiles.last.id;

      // If we are deleting the currently active file, switch to another one
      if (state.currentFileId == id) {
         final index = state.files.indexWhere((f) => f.id == id);
         if (index > 0) {
            nextId = state.files[index - 1].id;
         } else {
            nextId = remainingFiles.first.id;
         }
      }

      _prefsRepo.setCurrentFileId(nextId);
      state = FileState(files: remainingFiles, currentFileId: nextId);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
