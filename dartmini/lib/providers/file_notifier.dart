import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/dart_file.dart';

class FileState {
  final List<DartFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({
    List<DartFile>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<DartFile> _box;
  Timer? _debounceTimer;

  FileNotifier(this._box) : super(FileState(files: _box.values.toList())) {
    if (state.files.isEmpty) {
      _createNewFile(isInitial: true);
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  FileState get currentState => state;

  DartFile? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void _createNewFile({bool isInitial = false}) {
    final newFile = DartFile(
      id: const Uuid().v4(),
      name: isInitial ? 'main.dart' : 'untitled.dart',
      content: isInitial ? "void main() {\n  print('Hello, DartMini!');\n}\n" : "",
      updatedAt: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = FileState(
      files: _box.values.toList(),
      activeFileId: newFile.id,
    );
  }

  void newFile() => _createNewFile();

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateContent(String newContent) {
    if (state.activeFileId == null) return;

    // Update state immediately for UI
    final activeId = state.activeFileId!;
    final updatedFiles = state.files.map((f) {
      if (f.id == activeId) {
        return f.copyWith(content: newContent, updatedAt: DateTime.now());
      }
      return f;
    }).toList();
    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      final fileToSave = state.files.firstWhere((f) => f.id == activeId);
      _box.put(activeId, fileToSave);
    });
  }

  void deleteActiveFile() {
    if (state.activeFileId == null) return;
    final activeId = state.activeFileId!;
    _box.delete(activeId);

    final updatedFiles = _box.values.toList();
    if (updatedFiles.isEmpty) {
      _createNewFile();
    } else {
      state = FileState(
        files: updatedFiles,
        activeFileId: updatedFiles.first.id,
      );
    }
  }

  void importFile(String name, String content) {
    final newFile = DartFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
      updatedAt: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = FileState(
      files: _box.values.toList(),
      activeFileId: newFile.id,
    );
  }
}

final fileBoxProvider = Provider<Box<DartFile>>((ref) => throw UnimplementedError());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileNotifier(box);
});
