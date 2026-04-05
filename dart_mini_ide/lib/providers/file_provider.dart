import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../utils/constants.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _debounce;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = Hive.box<CodeFile>('filesBox');
    List<CodeFile> files = box.values.toList();
    String? activeId;

    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: Constants.defaultDartCode,
      );
      box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
      activeId = defaultFile.id;
    } else {
      activeId = files.first.id; // Just pick the first one on startup
    }

    state = state.copyWith(files: files, activeFileId: activeId);
  }

  void switchFile(String id) {
    if (state.activeFileId != id) {
      state = state.copyWith(activeFileId: id);
    }
  }

  Future<void> createNewFile(String name, [String content = '']) async {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: content,
    );
    final box = Hive.box<CodeFile>('filesBox');
    await box.put(newFile.id, newFile);

    final updatedFiles = List<CodeFile>.from(state.files)..add(newFile);
    state = state.copyWith(files: updatedFiles, activeFileId: newFile.id);
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null || active.content == content) return;

    final updated = active.copyWith(content: content);

    final index = state.files.indexWhere((f) => f.id == active.id);
    final updatedList = List<CodeFile>.from(state.files);
    updatedList[index] = updated;

    state = state.copyWith(files: updatedList);

    // Auto-save logic
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final box = Hive.box<CodeFile>('filesBox');
      box.put(updated.id, updated);
    });
  }

  Future<void> forceSaveActive() async {
    final active = state.activeFile;
    if (active != null) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      final box = Hive.box<CodeFile>('filesBox');
      await box.put(active.id, active);
    }
  }

  Future<void> deleteFile(String id) async {
    final box = Hive.box<CodeFile>('filesBox');
    await box.delete(id);

    final updatedList = state.files.where((f) => f.id != id).toList();
    String? newActiveId;

    if (updatedList.isEmpty) {
      final newFile = CodeFile(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
      );
      await box.put(newFile.id, newFile);
      updatedList.add(newFile);
      newActiveId = newFile.id;
    } else if (state.activeFileId == id) {
      newActiveId = updatedList.first.id;
    } else {
      newActiveId = state.activeFileId;
    }

    state = state.copyWith(files: updatedList, activeFileId: newActiveId);
  }
}
