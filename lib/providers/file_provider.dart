import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/project_file.dart';
import 'package:uuid/uuid.dart';

class FileState {
  final List<ProjectFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<ProjectFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  ProjectFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (e) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<ProjectFile> _box;
  Timer? _debounceTimer;

  FileNotifier(this._box) : super(FileState(files: _box.values.toList())) {
    if (state.files.isEmpty) {
      _createDefaultFile();
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  void _createDefaultFile() {
    final defaultFile = ProjectFile(
      id: const Uuid().v4(),
      name: 'main.dart',
      content: '''import 'dart:io';

void main() {
  print('Hello, DartMini IDE!');
  print('Enter something:');
  String? input = stdin.readLineSync();
  print('You entered: \$input');
}''',
      lastModified: DateTime.now(),
    );
    _box.put(defaultFile.id, defaultFile);
    state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
  }

  void createFile(String name, [String content = '']) {
    final newFile = ProjectFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null) return;

    final updated = active.copyWith(
      content: content,
      lastModified: DateTime.now(),
    );

    final newFiles = state.files.map((f) => f.id == active.id ? updated : f).toList();
    state = state.copyWith(files: newFiles);

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _box.put(updated.id, updated);
    });
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remaining = state.files.where((f) => f.id != id).toList();
    String? nextActiveId;
    if (remaining.isNotEmpty) {
      nextActiveId = remaining.last.id;
    }
    state = state.copyWith(files: remaining, activeFileId: nextActiveId);

    if (remaining.isEmpty) {
      _createDefaultFile();
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<ProjectFile>('files');
  return FileNotifier(box);
});
