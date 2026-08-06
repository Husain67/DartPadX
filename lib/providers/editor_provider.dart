import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/project_file.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});

class EditorState {
  final List<ProjectFile> files;
  final String? activeFileId;
  final bool isReady;

  EditorState({
    required this.files,
    this.activeFileId,
    this.isReady = false,
  });

  ProjectFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }

  EditorState copyWith({
    List<ProjectFile>? files,
    String? activeFileId,
    bool? isReady,
  }) {
    return EditorState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
      isReady: isReady ?? this.isReady,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(EditorState(files: [])) {
    _init();
  }

  late Box<ProjectFile> _fileBox;
  final _uuid = const Uuid();
  Timer? _saveTimer;

  Future<void> _init() async {
    _fileBox = Hive.box<ProjectFile>('files');
    final storedFiles = _fileBox.values.toList();

    if (storedFiles.isEmpty) {
      final defaultFile = ProjectFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello DartMini!');
}
''',
      );
      await _fileBox.put(defaultFile.id, defaultFile);
      storedFiles.add(defaultFile);
    }

    state = state.copyWith(
      files: storedFiles,
      activeFileId: storedFiles.first.id,
      isReady: true,
    );
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
    }
  }

  Future<void> updateActiveFileContent(String content) async {
    final active = state.activeFile;
    if (active == null) return;

    // Update state immediately for fast UI
    final updated = active.copyWith(content: content);
    final newFiles = state.files.map((f) => f.id == updated.id ? updated : f).toList();
    state = state.copyWith(files: newFiles);

    // Debounce save to Hive every 2 seconds
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      await _fileBox.put(updated.id, updated);
    });
  }

  Future<void> createFile(String name) async {
    final newFile = ProjectFile(
      id: _uuid.v4(),
      name: name,
      content: '',
    );
    await _fileBox.put(newFile.id, newFile);

    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  Future<void> deleteActiveFile() async {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    await _fileBox.delete(activeId);

    final newFiles = state.files.where((f) => f.id != activeId).toList();

    if (newFiles.isEmpty) {
      // Auto create untitled
      final newFile = ProjectFile(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
      );
      await _fileBox.put(newFile.id, newFile);
      newFiles.add(newFile);
    }

    state = state.copyWith(
      files: newFiles,
      activeFileId: newFiles.first.id,
    );
  }
}
