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
  final int activeIndex;
  final bool isReady;

  FileState({
    required this.files,
    required this.activeIndex,
    this.isReady = false,
  });

  CodeFile? get activeFile => files.isNotEmpty && activeIndex >= 0 && activeIndex < files.length ? files[activeIndex] : null;

  FileState copyWith({
    List<CodeFile>? files,
    int? activeIndex,
    bool? isReady,
  }) {
    return FileState(
      files: files ?? this.files,
      activeIndex: activeIndex ?? this.activeIndex,
      isReady: isReady ?? this.isReady,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  Timer? _debounceTimer;

  FileNotifier() : super(FileState(files: [], activeIndex: 0)) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>(AppConstants.fileBoxName);

    if (_box.isEmpty) {
      await _box.put(AppConstants.defaultMainFile.id, AppConstants.defaultMainFile);
    }

    List<CodeFile> initialFiles = _box.values.toList();
    state = FileState(files: initialFiles, activeIndex: 0, isReady: true);
  }

  void _forceSave() {
    if (state.activeFile != null) {
      _box.put(state.activeFile!.id, state.activeFile!);
    }
  }

  void createNewFile() {
    _forceSave();
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: 'untitled_\${state.files.length}.dart',
      content: '',
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: _box.values.toList(),
      activeIndex: state.files.length, // Select new file
    );
  }

  void importFile(String name, String content) {
    _forceSave();
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: _box.values.toList(),
      activeIndex: state.files.length,
    );
  }

  void loadExample(CodeFile example) {
    _forceSave();
    // Generate new ID so it doesn't overwrite if loaded multiple times
    final newFile = example.copyWith(id: const Uuid().v4());
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: _box.values.toList(),
      activeIndex: state.files.length,
    );
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFile == null) return;

    // Update state immediately for UI
    final updatedFile = state.activeFile!.copyWith(content: newContent);
    final newFiles = List<CodeFile>.from(state.files);
    newFiles[state.activeIndex] = updatedFile;
    state = state.copyWith(files: newFiles);

    // Auto-save with 2s debounce
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _box.put(updatedFile.id, updatedFile);
    });
  }

  void updateActiveFileName(String newName) {
    if (state.activeFile == null) return;
    final updatedFile = state.activeFile!.copyWith(name: newName);
    final newFiles = List<CodeFile>.from(state.files);
    newFiles[state.activeIndex] = updatedFile;
    _box.put(updatedFile.id, updatedFile);
    state = state.copyWith(files: newFiles);
  }

  void setActiveIndex(int index) {
    _forceSave();
    if (index >= 0 && index < state.files.length) {
      state = state.copyWith(activeIndex: index);
    }
  }

  void deleteFileById(String id) {
    _box.delete(id);
    final remaining = _box.values.toList();
    if (remaining.isEmpty) {
      // Create default if all deleted
      final df = AppConstants.defaultMainFile.copyWith(id: const Uuid().v4());
      _box.put(df.id, df);
      state = state.copyWith(files: [df], activeIndex: 0);
    } else {
      int newIndex = state.activeIndex;
      if (newIndex >= remaining.length) {
        newIndex = remaining.length - 1;
      }
      state = state.copyWith(files: remaining, activeIndex: newIndex);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
