import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_mini_ide/models/file_model.dart';
import 'package:uuid/uuid.dart';

const String defaultFileContent = '''import 'dart:io';

void main() {
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name! Welcome to DartMini IDE!');
}
''';

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

  FileModel? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  final Box _box = Hive.box('files');
  Timer? _saveTimer;

  void _loadFiles() {
    final Map<dynamic, dynamic> data = _box.toMap();
    final List<FileModel> loadedFiles = [];
    String? lastActiveId = _box.get('_activeFileId');

    data.forEach((key, value) {
      if (key != '_activeFileId') {
        try {
          final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(value);
          loadedFiles.add(FileModel.fromJson(jsonMap));
        } catch (e) {
          // Ignore invalid entries
        }
      }
    });

    if (loadedFiles.isEmpty) {
      final defaultFile = FileModel(name: 'main.dart', content: defaultFileContent);
      loadedFiles.add(defaultFile);
      lastActiveId = defaultFile.id;
      _saveFileToHive(defaultFile);
    }

    if (lastActiveId == null || !loadedFiles.any((f) => f.id == lastActiveId)) {
      lastActiveId = loadedFiles.first.id;
    }

    state = FileState(files: loadedFiles, activeFileId: lastActiveId);
  }

  void _saveFileToHive(FileModel file) {
    _box.put(file.id, file.toJson());
  }

  void newFile() {
    final String newId = const Uuid().v4();
    final newFile = FileModel(id: newId, name: 'untitled.dart', content: '');
    final updatedFiles = [...state.files, newFile];

    state = state.copyWith(files: updatedFiles, activeFileId: newId);
    _saveFileToHive(newFile);
    _box.put('_activeFileId', newId);
  }

  void switchFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
      _box.put('_activeFileId', id);
    }
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null) return;

    if (active.content == content) return;

    final updatedFile = active.copyWith(content: content);
    final updatedFiles = state.files.map((f) => f.id == updatedFile.id ? updatedFile : f).toList();

    state = state.copyWith(files: updatedFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveFileToHive(updatedFile);
    });
  }

  void deleteActiveFile() {
    final active = state.activeFile;
    if (active == null) return;

    _box.delete(active.id);
    final updatedFiles = state.files.where((f) => f.id != active.id).toList();

    if (updatedFiles.isEmpty) {
      final newFile = FileModel(name: 'untitled.dart', content: '');
      updatedFiles.add(newFile);
      _saveFileToHive(newFile);
    }

    final newActiveId = updatedFiles.first.id;
    state = FileState(files: updatedFiles, activeFileId: newActiveId);
    _box.put('_activeFileId', newActiveId);
  }

  void importFile(String name, String content) {
    final newId = const Uuid().v4();
    final newFile = FileModel(id: newId, name: name, content: content);
    final updatedFiles = [...state.files, newFile];

    state = state.copyWith(files: updatedFiles, activeFileId: newId);
    _saveFileToHive(newFile);
    _box.put('_activeFileId', newId);
  }
}
