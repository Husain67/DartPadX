import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<FileModel> _box;
  Timer? _saveTimer;

  FileNotifier(this._box) : super(FileState(files: _box.values.toList())) {
    if (state.files.isEmpty) {
      _createDefaultFile();
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  FileState get currentState => state;

  void _createDefaultFile() {
    final defaultFile = FileModel(
      name: 'main.dart',
      content: '''
import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');
}
''',
    );
    _box.put(defaultFile.id, defaultFile);
    state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
  }

  void addFile(String name, {String content = ''}) {
    final newFile = FileModel(name: name, content: content);
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void switchFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String newContent) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final index = state.files.indexWhere((f) => f.id == activeId);
    if (index == -1) return;

    final updatedFile = state.files[index].copyWith(
      content: newContent,
      lastModified: DateTime.now(),
    );

    final newFiles = List<FileModel>.from(state.files);
    newFiles[index] = updatedFile;

    state = state.copyWith(files: newFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(activeId, updatedFile);
    });
  }

  void deleteActiveFile() {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    _box.delete(activeId);

    final newFiles = state.files.where((f) => f.id != activeId).toList();
    if (newFiles.isEmpty) {
      _createDefaultFile();
    } else {
      state = FileState(files: newFiles, activeFileId: newFiles.first.id);
    }
  }

  FileModel? get activeFile {
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (e) {
      return null;
    }
  }
}

final fileBoxProvider = Provider<Box<FileModel>>((ref) => throw UnimplementedError());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileNotifier(box);
});
