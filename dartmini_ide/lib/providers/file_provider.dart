import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/file_model.dart';
import 'package:uuid/uuid.dart';

const String _kFilesBox = 'filesBox';
const String _kSelectedFileId = 'selectedFileId';
const _uuid = Uuid();

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

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
  late Box<FileModel> _box;
  late Box _prefsBox;
  Timer? _saveTimer;

  FileNotifier() : super(FileState(files: [], activeFileId: null));

  FileState get currentState => state;

  Future<void> init() async {
    _box = await Hive.openBox<FileModel>(_kFilesBox);
    _prefsBox = await Hive.openBox('prefsBox');

    List<FileModel> loadedFiles = _box.values.toList();

    if (loadedFiles.isEmpty) {
      final defaultFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello from DartMini IDE!');
}''',
        lastModified: DateTime.now(),
      );
      await _box.put(defaultFile.id, defaultFile);
      loadedFiles = [defaultFile];
    }

    String? savedActiveId = _prefsBox.get(_kSelectedFileId);
    if (savedActiveId == null || !loadedFiles.any((f) => f.id == savedActiveId)) {
      savedActiveId = loadedFiles.first.id;
    }

    state = FileState(files: loadedFiles, activeFileId: savedActiveId);
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      _prefsBox.put(_kSelectedFileId, id);
      state = state.copyWith(activeFileId: id);
    }
  }

  void addFile(String name, String content) {
    final newFile = FileModel(
      id: _uuid.v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    _box.put(newFile.id, newFile);

    final newFiles = [...state.files, newFile];
    state = state.copyWith(files: newFiles, activeFileId: newFile.id);
    _prefsBox.put(_kSelectedFileId, newFile.id);
  }

  FileModel? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void updateActiveFileContent(String content) {
    final file = activeFile;
    if (file == null) return;

    // Update local state immediately for UI
    final updatedFile = file.copyWith(
      content: content,
      lastModified: DateTime.now()
    );

    final newFiles = state.files.map((f) => f.id == file.id ? updatedFile : f).toList();
    state = state.copyWith(files: newFiles);

    // Debounce save to Hive
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(file.id, updatedFile);
    });
  }

  Future<void> deleteActiveFile() async {
    final fileId = state.activeFileId;
    if (fileId == null) return;

    await _box.delete(fileId);

    final newFiles = state.files.where((f) => f.id != fileId).toList();

    if (newFiles.isEmpty) {
      final newFile = FileModel(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
        lastModified: DateTime.now(),
      );
      await _box.put(newFile.id, newFile);
      newFiles.add(newFile);
    }

    final nextId = newFiles.last.id;
    _prefsBox.put(_kSelectedFileId, nextId);
    state = FileState(files: newFiles, activeFileId: nextId);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
