import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  final _uuid = const Uuid();
  Timer? _debounce;

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<CodeFile>('code_files');
    if (_box.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello DartMini!');\n}\n",
      );
      await _box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      final files = _box.values.toList();
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  CodeFile? get activeFile {
    if (state.activeFileId.isEmpty) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      _forceSave(specificId: state.activeFileId);
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveContent(String content, {bool forceSync = false}) {
    final active = activeFile;
    if (active == null) return;

    final updated = active.copyWith(content: content);
    final newFiles = state.files.map((f) => f.id == updated.id ? updated : f).toList();

    // Auto-save debounce
    if (const bool.hasEnvironment('FLUTTER_TEST')) {
      _box.put(updated.id, updated);
    } else {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(seconds: 2), () {
        _box.put(updated.id, updated);
      });
    }

    if (forceSync) {
      state = state.copyWith(files: newFiles);
    } else {
      // Don't trigger a full state rebuild for every keystroke unless forced
      // Keep files list updated in memory
      state = FileState(files: newFiles, activeFileId: state.activeFileId);
    }
  }

  void _forceSave({required String specificId}) {
    if (specificId.isEmpty) return;
    try {
      final file = state.files.firstWhere((f) => f.id == specificId);
      _box.put(specificId, file);
    } catch (_) {}
  }

  void addFile({String name = 'untitled.dart', String content = ''}) {
    final newFile = CodeFile(id: _uuid.v4(), name: name, content: content);
    _box.put(newFile.id, newFile);
    state = state.copyWith(files: [...state.files, newFile], activeFileId: newFile.id);
  }

  void deleteActiveFile() {
    if (state.files.isEmpty) return;
    final idToDelete = state.activeFileId;
    _box.delete(idToDelete);

    final newFiles = state.files.where((f) => f.id != idToDelete).toList();
    if (newFiles.isEmpty) {
      state = state.copyWith(files: []);
      addFile();
    } else {
      state = state.copyWith(files: newFiles, activeFileId: newFiles.first.id);
    }
  }
}
