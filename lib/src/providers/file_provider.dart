import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_style/dart_style.dart';

import 'package:uuid/uuid.dart';
import '../models/dart_file.dart';
import '../../main.dart'; // for sharedPreferences

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<DartFile> files;
  final String activeFileId;

  FileState({
    required this.files,
    required this.activeFileId,
  });

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
  late Box<DartFile> _box;
  final _uuid = const Uuid();
  Timer? _autoSaveTimer;

  FileNotifier()
      : super(FileState(
          files: [],
          activeFileId: '',
        )) {
    _box = Hive.box<DartFile>('files');
    _loadFiles();
  }

  void _loadFiles() {
    if (_box.isEmpty) {
      _createDefaultFile();
    } else {
      final files = _box.values.toList();
      String activeId = sharedPreferences.getString('activeFileId') ?? '';
      if (activeId.isEmpty || !files.any((f) => f.id == activeId)) {
        activeId = files.first.id;
      }
      state = state.copyWith(files: files, activeFileId: activeId);
    }
  }

  void _createDefaultFile() {
    final defaultFile = DartFile(
      id: _uuid.v4(),
      name: 'main.dart',
      content: '''import 'dart:io';

void main() {
  print("Hello from DartMini IDE!");
  print("Testing stdin:");
  String? name = stdin.readLineSync();
  if (name != null && name.isNotEmpty) {
    print("Welcome, \$name!");
  } else {
    print("Welcome, stranger!");
  }
}''',
      updatedAt: DateTime.now(),
    );
    _box.put(defaultFile.id, defaultFile);
    state = state.copyWith(
      files: [defaultFile],
      activeFileId: defaultFile.id,
    );
    sharedPreferences.setString('activeFileId', defaultFile.id);
  }

  void createFile(String name, {String content = ''}) {
    final newFile = DartFile(
      id: _uuid.v4(),
      name: name,
      content: content,
      updatedAt: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: _box.values.toList(),
      activeFileId: newFile.id,
    );
    sharedPreferences.setString('activeFileId', newFile.id);
  }

  void setActiveFile(String id) {
    // Force save current active file before switching
    if (state.activeFileId.isNotEmpty) {
      final currentFile = state.files.firstWhere((f) => f.id == state.activeFileId);
      _box.put(currentFile.id, currentFile);
    }

    sharedPreferences.setString('activeFileId', id);
    state = state.copyWith(activeFileId: id);
  }

  void deleteFile(String id) {
    _box.delete(id);
    final files = _box.values.toList();

    if (files.isEmpty) {
      _createDefaultFile();
      return;
    }

    String newActiveId = state.activeFileId;
    if (state.activeFileId == id) {
      newActiveId = files.first.id;
      sharedPreferences.setString('activeFileId', newActiveId);
    }

    state = state.copyWith(files: files, activeFileId: newActiveId);
  }

  void updateActiveFileContent(String content) {
    final activeFile = state.files.firstWhere((f) => f.id == state.activeFileId);
    final updatedFile = activeFile.copyWith(content: content, updatedAt: DateTime.now());

    final index = state.files.indexWhere((f) => f.id == state.activeFileId);
    final newFiles = List<DartFile>.from(state.files);
    newFiles[index] = updatedFile;

    state = state.copyWith(files: newFiles);

    _scheduleAutoSave(updatedFile);
  }

  void _scheduleAutoSave(DartFile file) {
    _autoSaveTimer?.cancel();
    if (const bool.hasEnvironment('FLUTTER_TEST')) {
       _box.put(file.id, file);
       return;
    }
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(file.id, file);
    });
  }


  void formatActiveFile() {
    try {
      final file = activeFile;
      final formatter = DartFormatter();
      final formattedContent = formatter.format(file.content);
      updateActiveFileContent(formattedContent);
    } catch (e) {
      // Ignore format errors
    }
  }

  DartFile get activeFile => state.files.firstWhere((f) => f.id == state.activeFileId);

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
