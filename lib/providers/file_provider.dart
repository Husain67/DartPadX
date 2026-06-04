import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';

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

  FileModel? get activeFile => activeFileId == null
      ? null
      : files.where((f) => f.id == activeFileId).firstOrNull;
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<FileModel> _box;
  Timer? _saveTimer;

  FileNotifier(this._box) : super(FileState(files: _box.values.toList())) {
    if (state.files.isEmpty) {
      createFile(name: 'main.dart', content: 'void main() {\n  print("Hello, DartMini IDE!");\n}\n');
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  void createFile({String name = 'untitled.dart', String content = ''}) {
    final newFile = FileModel(
      id: const Uuid().v4(),
      name: name,
      content: content,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    final activeFile = state.activeFile;
    if (activeFile == null) return;

    // Update UI state immediately
    final updatedFile = activeFile.copyWith(
      content: content,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );

    final updatedFiles = state.files.map((f) => f.id == activeFile.id ? updatedFile : f).toList();
    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(updatedFile.id, updatedFile);
    });
  }

  void updateActiveFileName(String newName) {
    final activeFile = state.activeFile;
    if (activeFile == null) return;

    final updatedFile = activeFile.copyWith(
      name: newName,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );

    final updatedFiles = state.files.map((f) => f.id == activeFile.id ? updatedFile : f).toList();
    state = state.copyWith(files: updatedFiles);
    _box.put(updatedFile.id, updatedFile);
  }

  void deleteActiveFile() {
    final activeFileId = state.activeFileId;
    if (activeFileId == null) return;

    _box.delete(activeFileId);
    final remainingFiles = state.files.where((f) => f.id != activeFileId).toList();

    if (remainingFiles.isEmpty) {
      state = FileState(files: []);
      createFile(name: 'main.dart', content: 'void main() {\n  print("Hello, DartMini IDE!");\n}\n');
    } else {
      state = state.copyWith(
        files: remainingFiles,
        activeFileId: remainingFiles.first.id,
      );
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<FileModel>('files');
  return FileNotifier(box);
});
