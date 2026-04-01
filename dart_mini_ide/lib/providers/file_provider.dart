import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/code_file.dart';
import '../utils/constants.dart';

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile =>
      files.firstWhere((file) => file.id == activeFileId, orElse: () => files.first);

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> _fileBox;
  final Box _settingsBox;
  Timer? _debounce;
  String? _forceSaveId;

  FileNotifier(this._fileBox, this._settingsBox) : super(FileState(files: [])) {
    _init();
  }

  void _init() {
    final files = _fileBox.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: AppConstants.defaultFileContent,
      );
      _fileBox.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }

    String? activeId = _settingsBox.get(AppConstants.activeFileIdKey);
    if (activeId == null || !files.any((f) => f.id == activeId)) {
      activeId = files.first.id;
      _settingsBox.put(AppConstants.activeFileIdKey, activeId);
    }

    state = FileState(files: files, activeFileId: activeId);
  }

  void setActiveFile(String id) {
    if (state.activeFileId == id) return;

    // Explicitly force save previous active file before switching
    if (state.activeFileId != null && _forceSaveId != null) {
        forceSaveCurrent(_forceSaveId!);
    }

    _settingsBox.put(AppConstants.activeFileIdKey, id);
    _forceSaveId = id;
    state = state.copyWith(activeFileId: id);
  }

  void addFile(String name, String content) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    _fileBox.put(newFile.id, newFile);

    final updatedFiles = List<CodeFile>.from(state.files)..add(newFile);
    state = state.copyWith(files: updatedFiles, activeFileId: newFile.id);
    _settingsBox.put(AppConstants.activeFileIdKey, newFile.id);
    _forceSaveId = newFile.id;
  }

  void deleteFile(String id) {
    _fileBox.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    String? newActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      if (updatedFiles.isNotEmpty) {
        // Select an adjacent file if possible
        newActiveId = updatedFiles.first.id;
      } else {
        // Create an untitled file if all files are deleted
        final newFile = CodeFile(
          id: const Uuid().v4(),
          name: 'untitled.dart',
          content: '',
        );
        _fileBox.put(newFile.id, newFile);
        updatedFiles.add(newFile);
        newActiveId = newFile.id;
      }
      _settingsBox.put(AppConstants.activeFileIdKey, newActiveId);
    }
    _forceSaveId = newActiveId;
    state = state.copyWith(files: updatedFiles, activeFileId: newActiveId);
  }

  void updateFileContent(String id, String content) {
    final index = state.files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final file = state.files[index];
      file.content = content;

      // Update state without immediately writing to Hive for UI responsiveness
      state = state.copyWith(files: List<CodeFile>.from(state.files));

      // Debounce saving to Hive
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(seconds: 2), () {
        file.save();
      });
    }
  }

  void forceSaveCurrent(String content) {
     final index = state.files.indexWhere((f) => f.id == state.activeFileId);
     if (index != -1) {
         final file = state.files[index];
         file.content = content;
         file.save();
     }
  }

  void updateFileName(String id, String newName) {
    final index = state.files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final file = state.files[index];
      file.name = newName;
      file.save();
      state = state.copyWith(files: List<CodeFile>.from(state.files));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final fileBoxProvider = Provider<Box<CodeFile>>((ref) {
  return Hive.box<CodeFile>(AppConstants.fileBoxName);
});

final settingsBoxProvider = Provider<Box>((ref) {
  return Hive.box(AppConstants.settingsBoxName);
});

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final fileBox = ref.watch(fileBoxProvider);
  final settingsBox = ref.watch(settingsBoxProvider);
  return FileNotifier(fileBox, settingsBox);
});