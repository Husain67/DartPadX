import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileModel? get activeFile => files.isNotEmpty
    ? (activeFileId == null
        ? files.first
        : files.firstWhere((f) => f.id == activeFileId, orElse: () => files.first))
    : null;

  FileState copyWith({List<FileModel>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<FileModel> _box;
  Timer? _debounce;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  void _init() {
    _box = Hive.box<FileModel>('files');
    final storedFiles = _box.values.toList();

    if (storedFiles.isEmpty) {
      // Create default
      final defaultFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello DartMini!');
  // Write your dart code here
}''',
      );
      _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: storedFiles, activeFileId: storedFiles.first.id);
    }
  }

  void switchFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void createNewFile() {
    final newFile = FileModel(
      id: _uuid.v4(),
      name: 'untitled_${state.files.length}.dart',
      content: '',
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void importFile(String name, String content) {
    final newFile = FileModel(
      id: _uuid.v4(),
      name: name,
      content: content,
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateContent(String id, String newContent) {
    // Update local state immediately
    final updatedFiles = state.files.map((f) {
      if (f.id == id) {
        return f.copyWith(content: newContent);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive (auto-save every 2s)
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final fileToSave = state.files.firstWhere((f) => f.id == id);
      _box.put(id, fileToSave);
    });
  }

  void renameFile(String id, String newName) {
    final updatedFiles = state.files.map((f) {
      if (f.id == id) {
        final uf = f.copyWith(name: newName);
        _box.put(id, uf);
        return uf;
      }
      return f;
    }).toList();
    state = state.copyWith(files: updatedFiles);
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remaining = state.files.where((f) => f.id != id).toList();

    if (remaining.isEmpty) {
      // Must have at least one file
      final newFile = FileModel(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
      );
      _box.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      String? nextId;
      if (state.activeFileId == id) {
        nextId = remaining.first.id;
      } else {
        nextId = state.activeFileId;
      }
      state = FileState(files: remaining, activeFileId: nextId);
    }
  }
}
