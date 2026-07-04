import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';

final filesProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

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
  final Box<FileModel> _filesBox = Hive.box<FileModel>('files');
  final Box<String> _settingsBox = Hive.box<String>('settings');
  Timer? _autoSaveTimer;

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _filesBox.values.toList();
    files.sort((a, b) => b.lastModified.compareTo(a.lastModified));

    final lastActiveId = _settingsBox.get('activeFileId');
    String? activeId;

    if (files.isNotEmpty) {
      if (lastActiveId != null && files.any((f) => f.id == lastActiveId)) {
        activeId = lastActiveId;
      } else {
        activeId = files.first.id;
      }
    }

    state = FileState(files: files, activeFileId: activeId);
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      _settingsBox.put('activeFileId', id);
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final activeFile = state.files.firstWhere((f) => f.id == state.activeFileId);
    if (activeFile.content == content) return;

    final updatedFile = activeFile.copyWith(
      content: content,
      lastModified: DateTime.now(),
    );

    final updatedFiles = state.files.map((f) => f.id == state.activeFileId ? updatedFile : f).toList();
    state = state.copyWith(files: updatedFiles);

    _debounceSave(updatedFile);
  }

  void _debounceSave(FileModel file) {
    if (_autoSaveTimer?.isActive ?? false) {
      _autoSaveTimer!.cancel();
    }
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _filesBox.put(file.id, file);
    });
  }

  void createNewFile() {
    final id = const Uuid().v4();
    final name = 'untitled_${state.files.length}.dart';

    final newFile = FileModel(
      id: id,
      name: name,
      content: 'void main() {\n  \n}\n',
      lastModified: DateTime.now(),
    );

    _filesBox.put(id, newFile);

    final updatedFiles = List<FileModel>.from(state.files)..add(newFile);
    state = state.copyWith(files: updatedFiles, activeFileId: id);
    _settingsBox.put('activeFileId', id);
  }

  void deleteActiveFile() {
    if (state.activeFileId == null) return;

    _filesBox.delete(state.activeFileId);

    final updatedFiles = state.files.where((f) => f.id != state.activeFileId).toList();
    String? nextActiveId;

    if (updatedFiles.isNotEmpty) {
      nextActiveId = updatedFiles.first.id;
    } else {
      // Auto-create new file if all deleted
      final id = const Uuid().v4();
      final newFile = FileModel(
        id: id,
        name: 'main.dart',
        content: 'void main() {\n  \n}\n',
        lastModified: DateTime.now(),
      );
      _filesBox.put(id, newFile);
      updatedFiles.add(newFile);
      nextActiveId = id;
    }

    state = state.copyWith(files: updatedFiles, activeFileId: nextActiveId);
    _settingsBox.put('activeFileId', nextActiveId);
  }

  void importFile(String name, String content) {
      final id = const Uuid().v4();

      final newFile = FileModel(
        id: id,
        name: name,
        content: content,
        lastModified: DateTime.now(),
      );

      _filesBox.put(id, newFile);

      final updatedFiles = List<FileModel>.from(state.files)..add(newFile);
      state = state.copyWith(files: updatedFiles, activeFileId: id);
      _settingsBox.put('activeFileId', id);
  }
}
