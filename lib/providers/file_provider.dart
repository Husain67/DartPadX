import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../core/db.dart';

class FileStateData {
  final List<FileState> files;
  final String activeFileId;

  FileStateData({required this.files, required this.activeFileId});

  FileStateData copyWith({List<FileState>? files, String? activeFileId}) {
    return FileStateData(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileStateData> {
  FileNotifier() : super(FileStateData(files: [], activeFileId: '')) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = DB.filesBox;
    List<FileState> loadedFiles = box.values.toList();

    if (loadedFiles.isEmpty) {
      final defaultFile = FileState(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: "import 'dart:io';\n\nvoid main() {\n  print('Hello DartMini!');\n}\n",
      );
      box.put(defaultFile.id, defaultFile);
      loadedFiles = [defaultFile];
    }

    final activeId = DB.settingsBox.get('activeFileId', defaultValue: loadedFiles.first.id);
    state = FileStateData(files: loadedFiles, activeFileId: activeId);
  }

  void setActiveFile(String id) {
    DB.settingsBox.put('activeFileId', id);
    state = state.copyWith(activeFileId: id);
  }

  FileState? get activeFile {
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (e) {
      return null;
    }
  }

  void newFile() {
    final newFile = FileState(
      id: const Uuid().v4(),
      name: 'untitled_${state.files.length + 1}.dart',
      content: '',
    );
    DB.filesBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
    DB.settingsBox.put('activeFileId', newFile.id);
  }

  void deleteActiveFile() {
    if (state.files.length <= 1) {
      DB.filesBox.delete(state.activeFileId);
      final newFile = FileState(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
      );
      DB.filesBox.put(newFile.id, newFile);
      state = FileStateData(files: [newFile], activeFileId: newFile.id);
      DB.settingsBox.put('activeFileId', newFile.id);
    } else {
      DB.filesBox.delete(state.activeFileId);
      final newFiles = state.files.where((f) => f.id != state.activeFileId).toList();
      final newActiveId = newFiles.last.id;
      state = state.copyWith(files: newFiles, activeFileId: newActiveId);
      DB.settingsBox.put('activeFileId', newActiveId);
    }
  }

  void updateActiveFileContent(String content) {
    final active = activeFile;
    if (active != null) {
      final updated = active.copyWith(content: content);
      DB.filesBox.put(updated.id, updated);
      state = state.copyWith(
        files: state.files.map((f) => f.id == updated.id ? updated : f).toList(),
      );
    }
  }

  void importFile(String name, String content) {
      final newFile = FileState(
        id: const Uuid().v4(),
        name: name,
        content: content,
      );
      DB.filesBox.put(newFile.id, newFile);
      state = state.copyWith(
        files: [...state.files, newFile],
        activeFileId: newFile.id,
      );
      DB.settingsBox.put('activeFileId', newFile.id);
  }

  void formatActiveFile() {
     // Optional formatting logic can be hooked here.
     // Updating state triggers redraw.
     state = state.copyWith(files: List.from(state.files));
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileStateData>((ref) {
  return FileNotifier();
});
