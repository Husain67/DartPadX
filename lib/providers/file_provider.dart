import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../utils/constants.dart';

final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>((ref) {
  return FilesNotifier();
});

class FilesState {
  final List<CodeFile> files;
  final String? activeFileId;

  FilesState({required this.files, this.activeFileId});

  FilesState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FilesState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  CodeFile? get activeFile =>
      files.cast<CodeFile?>().firstWhere((f) => f?.id == activeFileId, orElse: () => null);
}

class FilesNotifier extends StateNotifier<FilesState> {
  FilesNotifier() : super(FilesState(files: [])) {
    _loadFiles();
  }

  final _uuid = const Uuid();
  late Box<CodeFile> _box;
  Timer? _debounce;
  String? _currentActiveId; // Keep track locally for force save

  void _loadFiles() {
    _box = Hive.box<CodeFile>(AppConstants.hiveBoxFiles);
    List<CodeFile> loadedFiles = _box.values.toList();

    if (loadedFiles.isEmpty) {
      final initialFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: AppConstants.initialCode,
      );
      _box.put(initialFile.id, initialFile);
      loadedFiles.add(initialFile);
    }

    _currentActiveId = loadedFiles.first.id;
    state = FilesState(files: loadedFiles, activeFileId: _currentActiveId);
  }

  void setActiveFile(String id) {
    if (id == state.activeFileId) return;
    forceSaveCurrent(); // Force save previous before switching
    _currentActiveId = id;
    state = state.copyWith(activeFileId: id);
  }

  void createFile([String? content]) {
    forceSaveCurrent();
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: 'untitled.dart',
      content: content ?? '',
    );
    _box.put(newFile.id, newFile);
    _currentActiveId = newFile.id;
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remaining = state.files.where((f) => f.id != id).toList();
    String? nextActiveId;

    if (remaining.isNotEmpty) {
      if (state.activeFileId == id) {
        nextActiveId = remaining.last.id;
      } else {
        nextActiveId = state.activeFileId;
      }
    } else {
      // Auto create if last file is deleted
      final newFile = CodeFile(id: _uuid.v4(), name: 'untitled.dart', content: '');
      _box.put(newFile.id, newFile);
      remaining.add(newFile);
      nextActiveId = newFile.id;
    }

    _currentActiveId = nextActiveId;
    state = FilesState(files: remaining, activeFileId: nextActiveId);
  }

  void updateContent(String id, String content) {
    final idx = state.files.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final file = state.files[idx];
      file.content = content;
      // Note: we update state instantly for UI (though Riverpod might not deep-diff mutable lists well,
      // but CodeField mostly manages its own state via controller, we rely on Hive saving).

      if (_debounce?.isActive ?? false) _debounce?.cancel();
      // Use a shorter delay if in test environment (or bypass entirely, here we'll just check if it's safe)
      if (const bool.fromEnvironment('dart.vm.product') || !const bool.hasEnvironment('FLUTTER_TEST')) {
        _debounce = Timer(const Duration(seconds: 2), () {
          _box.put(id, file);
        });
      } else {
        _box.put(id, file); // instant save in tests
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void forceSaveCurrent() {
    if (_currentActiveId != null) {
      final file = state.files.cast<CodeFile?>().firstWhere((f) => f?.id == _currentActiveId, orElse: () => null);
      if (file != null) {
        _box.put(file.id, file);
      }
    }
  }

  void updateName(String id, String newName) {
    final idx = state.files.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final file = state.files[idx];
      file.name = newName;
      _box.put(id, file);
      // Trigger state update
      state = state.copyWith(files: List.from(state.files));
    }
  }

  void addFile(CodeFile file) {
    forceSaveCurrent();
    _box.put(file.id, file);
    _currentActiveId = file.id;
    state = state.copyWith(
      files: [...state.files, file],
      activeFileId: file.id,
    );
  }
}
