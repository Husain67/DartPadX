import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../core/hive_setup.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({
    List<FileModel>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<FileModel> _box;
  Timer? _saveTimer;

  FileNotifier(this._box) : super(FileState(files: _box.values.toList(), activeFileId: _box.values.firstOrNull?.id));

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final activeIndex = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (activeIndex == -1) return;

    final updatedFile = state.files[activeIndex].copyWith(content: content);
    final updatedFiles = List<FileModel>.from(state.files);
    updatedFiles[activeIndex] = updatedFile;

    state = state.copyWith(files: updatedFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(updatedFile.id, updatedFile);
    });
  }

  void createFile(String name, {String content = ''}) {
    const uuid = Uuid();
    final newFile = FileModel(
      id: uuid.v4(),
      name: name,
      content: content,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    if (remainingFiles.isEmpty) {
        state = state.copyWith(files: remainingFiles, activeFileId: null);
        createFile('untitled.dart');
        return;
    }

    state = state.copyWith(
      files: remainingFiles,
      activeFileId: remainingFiles.last.id,
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<FileModel>(HiveSetup.filesBoxName);
  return FileNotifier(box);
});
