import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';

const String _filesBoxName = 'filesBox';
const String _activeFileIdKey = 'activeFileId';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

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
  FileNotifier() : super(FileState(files: []));

  late Box<FileModel> _filesBox;
  late Box _prefsBox;
  Timer? _debounce;
  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    _filesBox = Hive.box<FileModel>(_filesBoxName);
    _prefsBox = Hive.box('prefsBox');

    final files = _filesBox.values.toList();
    String? activeId = _prefsBox.get(_activeFileIdKey);

    if (files.isEmpty) {
      final defaultFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello from DartMini IDE!');
}''',
        lastModified: DateTime.now(),
      );
      await _filesBox.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
      activeId = defaultFile.id;
      await _prefsBox.put(_activeFileIdKey, activeId);
    }

    // Ensure activeId is valid
    if (activeId == null || !files.any((f) => f.id == activeId)) {
      activeId = files.first.id;
      await _prefsBox.put(_activeFileIdKey, activeId);
    }

    state = FileState(files: files, activeFileId: activeId);
  }

  void switchFile(String id) {
    if (state.activeFileId == id) return;
    _forceSave(state.activeFileId); // Save previous before switching
    state = state.copyWith(activeFileId: id);
    _prefsBox.put(_activeFileIdKey, id);
  }

  Future<void> createNewFile([String content = '']) async {
    final id = _uuid.v4();
    final name = 'untitled_${state.files.length + 1}.dart';
    final newFile = FileModel(
      id: id,
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );

    await _filesBox.put(id, newFile);
    final updatedFiles = List<FileModel>.from(state.files)..add(newFile);

    state = FileState(files: updatedFiles, activeFileId: id);
    await _prefsBox.put(_activeFileIdKey, id);
  }

  Future<void> deleteFile(String id) async {
    await _filesBox.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    String? nextActiveId;
    if (updatedFiles.isNotEmpty) {
      if (state.activeFileId == id) {
        nextActiveId = updatedFiles.first.id;
      } else {
        nextActiveId = state.activeFileId;
      }
      await _prefsBox.put(_activeFileIdKey, nextActiveId);
      state = FileState(files: updatedFiles, activeFileId: nextActiveId);
    } else {
      // If last file deleted, create a new untitled one
      await createNewFile();
    }
  }

  void updateActiveFileContent(String newContent) {
    if (state.activeFileId == null) return;

    final index = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (index == -1) return;

    final updatedFile = state.files[index].copyWith(
      content: newContent,
      lastModified: DateTime.now(),
    );

    final updatedFiles = List<FileModel>.from(state.files);
    updatedFiles[index] = updatedFile;

    // Fast state update without writing to Hive immediately to avoid lag
    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _filesBox.put(updatedFile.id, updatedFile);
    });
  }

  void _forceSave(String? id) {
    if (id == null) return;
    final file = state.files.firstWhere((f) => f.id == id, orElse: () => state.files.first);
    _filesBox.put(file.id, file);
  }

  FileModel? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (e) {
      return null;
    }
  }
}
