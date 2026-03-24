import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((file) => file.id == activeFileId);
    } catch (e) {
      return null;
    }
  }

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> _box = Hive.box<CodeFile>('files');
  final Uuid _uuid = const Uuid();
  Timer? _debounceTimer;

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      _createDefaultFile();
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void _createDefaultFile() {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: 'main.dart',
      content: '''
import 'dart:io';

void main() {
  print('Hello from DartMini IDE!');

  // Example of stdin reading
  // print('Enter your name:');
  // String? name = stdin.readLineSync();
  // print('Hello, \$name!');
}
''',
    );
    _box.put(newFile.id, newFile);
    state = FileState(files: [newFile], activeFileId: newFile.id);
  }

  void createFile(String name, {String content = ''}) {
    final newFile = CodeFile(
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

  void switchFile(String id) {
    if (state.activeFileId == id) return;

    // Force save any pending changes for the current file before switching
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
      _forceSave(state.activeFileId);
    }

    state = state.copyWith(activeFileId: id);
  }

  void _forceSave(String? id) {
    if (id == null) return;
    try {
      final file = state.files.firstWhere((f) => f.id == id);
      _box.put(id, file);
    } catch (e) {
      // Ignore
    }
  }

  void updateContent(String content) {
    final activeFile = state.activeFile;
    if (activeFile == null) return;

    final updatedFile = activeFile.copyWith(content: content);

    // Debounce Hive saving by 2 seconds
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _box.put(activeFile.id, updatedFile);
    });

    final updatedFiles = state.files.map((file) {
      return file.id == activeFile.id ? updatedFile : file;
    }).toList();

    state = state.copyWith(files: updatedFiles);
  }

  void deleteFile(String id) {
    _box.delete(id);

    final updatedFiles = state.files.where((file) => file.id != id).toList();

    if (updatedFiles.isEmpty) {
      state = state.copyWith(files: [], activeFileId: null);
      _createDefaultFile();
    } else {
      String? newActiveId = state.activeFileId;
      if (newActiveId == id) {
        // Find adjacent file to select
        int oldIndex = state.files.indexWhere((f) => f.id == id);
        if (oldIndex > 0) {
            newActiveId = state.files[oldIndex - 1].id;
        } else {
            newActiveId = updatedFiles.first.id;
        }
      }
      state = state.copyWith(files: updatedFiles, activeFileId: newActiveId);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
