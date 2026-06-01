import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_model.dart';
import '../utils/hive_helper.dart';

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

  FileModel? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _saveTimer;

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = HiveHelper.fileBox;
    final files = box.values.toList();

    if (files.isEmpty) {
      final defaultFile = FileModel(
        name: 'main.dart',
        content: '''void main() {
  print('Hello DartMini IDE!');
}''',
      );
      box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void createNewFile(String name) {
    final newFile = FileModel(name: name, content: '');
    HiveHelper.fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null || active.content == content) return;

    final updated = active.copyWith(content: content, updatedAt: DateTime.now());

    final newFiles = state.files.map((f) => f.id == updated.id ? updated : f).toList();
    state = state.copyWith(files: newFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      HiveHelper.fileBox.put(updated.id, updated);
    });
  }

  void forceSyncState(FileState newState) {
    state = newState;
  }

  void deleteActiveFile() {
    final active = state.activeFile;
    if (active == null) return;

    HiveHelper.fileBox.delete(active.id);
    final remaining = state.files.where((f) => f.id != active.id).toList();

    if (remaining.isEmpty) {
       final newFile = FileModel(name: 'untitled.dart', content: '');
       HiveHelper.fileBox.put(newFile.id, newFile);
       state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
       state = FileState(files: remaining, activeFileId: remaining.first.id);
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
