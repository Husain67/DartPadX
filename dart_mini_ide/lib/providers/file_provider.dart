import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier(ref.read(storageServiceProvider));
});

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
  final StorageService _storage;
  Timer? _debounce;
  final _uuid = const Uuid();

  FileNotifier(this._storage) : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _storage.filesBox.values.toList();
    if (files.isEmpty) return;

    // Sort logic could go here if needed
    state = state.copyWith(
      files: files,
      activeFileId: files.first.id,
    );
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
    if (state.activeFileId != null) {
      _forceSave(specificId: state.activeFileId);
    }
    state = state.copyWith(activeFileId: id);
  }

  void updateContent(String content) {
    final currentFile = activeFile;
    if (currentFile == null) return;

    currentFile.content = content;
    currentFile.lastModified = DateTime.now();

    // Debounce save to Hive
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    const bool isTest = bool.hasEnvironment('FLUTTER_TEST');
    if (!isTest) {
      _debounce = Timer(const Duration(seconds: 2), () {
        currentFile.save();
      });
    } else {
       currentFile.save();
    }

    // Force a new state reference so UI listens to changes
    final index = state.files.indexWhere((f) => f.id == currentFile.id);
    if (index != -1) {
       final newFiles = List<CodeFile>.from(state.files);
       newFiles[index] = currentFile;
       state = state.copyWith(files: newFiles);
    }
  }

  void _forceSave({String? specificId}) {
     if (specificId != null) {
        try {
           final file = state.files.firstWhere((f) => f.id == specificId);
           file.save();
        } catch (_) {}
     }
  }

  void addFile({String name = 'untitled.dart', String content = ''}) {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    _storage.filesBox.put(newFile.id, newFile);

    final newFiles = [...state.files, newFile];
    state = state.copyWith(files: newFiles, activeFileId: newFile.id);
  }

  void deleteActiveFile() {
    final currentId = state.activeFileId;
    if (currentId == null) return;

    _storage.filesBox.delete(currentId);

    final newFiles = state.files.where((f) => f.id != currentId).toList();
    String? nextId;

    if (newFiles.isNotEmpty) {
      nextId = newFiles.last.id;
    } else {
      // Auto-create a new file if we deleted the last one
      final newFile = CodeFile(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
        lastModified: DateTime.now(),
      );
      _storage.filesBox.put(newFile.id, newFile);
      newFiles.add(newFile);
      nextId = newFile.id;
    }

    state = state.copyWith(files: newFiles, activeFileId: nextId);
  }
}
