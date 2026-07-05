import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/file_model.dart';
import '../core/constants.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;
  final bool isSaving;

  FileState({
    required this.files,
    this.activeFileId,
    this.isSaving = false,
  });

  FileModel? get activeFile => files.where((f) => f.id == activeFileId).firstOrNull;

  FileState copyWith({
    List<FileModel>? files,
    String? activeFileId,
    bool? isSaving,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<FileModel> _box;
  Timer? _saveTimer;

  FileNotifier(this._box) : super(FileState(files: _box.values.toList())) {
    if (state.files.isEmpty) {
      _createNewDefaultFile();
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  void _createNewDefaultFile() {
    final file = FileModel(
      name: 'main.dart',
      content: AppConstants.defaultMainContent,
    );
    _box.put(file.id, file);
    state = FileState(files: [file], activeFileId: file.id);
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String content) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == activeId) {
        return f.copyWith(content: content, lastModified: DateTime.now());
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles, isSaving: true);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      final activeFile = state.files.firstWhere((f) => f.id == activeId);
      _box.put(activeId, activeFile);
      state = state.copyWith(isSaving: false);
    });
  }

  void addNewFile({String name = 'untitled.dart', String content = ''}) {
    String finalName = name;
    int counter = 1;
    while(state.files.any((f) => f.name == finalName)) {
      finalName = 'untitled_$counter.dart';
      counter++;
    }

    final file = FileModel(name: finalName, content: content);
    _box.put(file.id, file);
    state = state.copyWith(
      files: [...state.files, file],
      activeFileId: file.id,
    );
  }

  void deleteActiveFile() {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    _box.delete(activeId);

    final updatedFiles = state.files.where((f) => f.id != activeId).toList();
    if (updatedFiles.isEmpty) {
      _createNewDefaultFile();
    } else {
      state = state.copyWith(
        files: updatedFiles,
        activeFileId: updatedFiles.first.id,
      );
    }
  }
}

final fileBoxProvider = Provider<Box<FileModel>>((ref) {
  return Hive.box<FileModel>(AppConstants.hiveFileBox);
});

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileNotifier(box);
});
