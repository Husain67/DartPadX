import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  CodeFile? get activeFile =>
      files.where((f) => f.id == activeFileId).firstOrNull;

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> _fileBox = Hive.box<CodeFile>('files');
  final Box _prefsBox = Hive.box('prefs');
  final _uuid = const Uuid();
  Timer? _debounce;

  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _fileBox.values.toList();
    if (files.isEmpty) {
      // Create default file
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Hello from DartMini IDE!');

  // Example of reading from stdin
  // Note: Standard API integrations might not support interactive stdin,
  // but you can test it by hardcoding the "stdin" parameter in custom presets.
  // String? input = stdin.readLineSync();
  // print('You typed: \$input');
}
''',
      );
      _fileBox.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }

    final savedActiveId = _prefsBox.get('activeFileId');
    final activeId = (savedActiveId != null && files.any((f) => f.id == savedActiveId))
        ? savedActiveId
        : files.first.id;

    state = FileState(files: files, activeFileId: activeId);
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      _forceSave(state.activeFileId); // Flush previous
      _prefsBox.put('activeFileId', id);
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String content) {
    if (state.activeFile == null) return;

    final updatedFile = state.activeFile!.copyWith(content: content);
    final updatedList = state.files.map((f) => f.id == updatedFile.id ? updatedFile : f).toList();

    state = state.copyWith(files: updatedList);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      _fileBox.put(updatedFile.id, updatedFile);
    });
  }

  void _forceSave(String id) {
    final file = state.files.where((f) => f.id == id).firstOrNull;
    if (file != null) {
      _fileBox.put(file.id, file);
    }
  }

  void addNewFile({String name = 'untitled.dart', String content = ''}) {
    final newFile = CodeFile(id: _uuid.v4(), name: name, content: content);
    _fileBox.put(newFile.id, newFile);
    state = FileState(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
    _prefsBox.put('activeFileId', newFile.id);
  }

  void deleteFile(String id) {
    if (state.files.length <= 1) {
      // Don't delete last file, just clear it or add untitled first
      addNewFile();
    }

    _fileBox.delete(id);
    final files = state.files.where((f) => f.id != id).toList();

    String nextActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      nextActiveId = files.last.id;
      _prefsBox.put('activeFileId', nextActiveId);
    }

    state = FileState(files: files, activeFileId: nextActiveId);
  }

  void importFile(String name, String content) {
    addNewFile(name: name, content: content);
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
