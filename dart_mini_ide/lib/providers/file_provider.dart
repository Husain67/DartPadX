import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> fileBox;
  Timer? _debounceTimer;

  FileNotifier(this.fileBox) : super(FileState(files: fileBox.values.toList())) {
    if (state.files.isEmpty) {
      _createNewFile(name: 'main.dart', content: '''
void main() {
  print('Hello, DartMini IDE!');
}
''');
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  void _createNewFile({String? name, String? content}) {
    final id = const Uuid().v4();
    final newFile = CodeFile(
      id: id,
      name: name ?? 'untitled.dart',
      content: content ?? '',
    );
    fileBox.put(id, newFile);
    state = state.copyWith(
      files: fileBox.values.toList(),
      activeFileId: id,
    );
  }

  void newFile() => _createNewFile();

  void addFile(CodeFile file) {
    fileBox.put(file.id, file);
    state = state.copyWith(
      files: fileBox.values.toList(),
      activeFileId: file.id,
    );
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;
    final activeFile = state.activeFile!;
    if (activeFile.content == content) return;

    activeFile.content = content;
    // Update memory immediately
    final index = state.files.indexWhere((f) => f.id == activeFile.id);
    if (index != -1) {
      final updatedFiles = List<CodeFile>.from(state.files);
      updatedFiles[index] = activeFile;
      state = state.copyWith(files: updatedFiles);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      fileBox.put(activeFile.id, activeFile);
    });
  }

  void forceSave({String? specificId}) {
    final targetId = specificId ?? state.activeFileId;
    if (targetId == null) return;
    try {
      final file = state.files.firstWhere((f) => f.id == targetId);
      fileBox.put(file.id, file);
    } catch (_) {}
  }

  void setActiveFile(String id) {
    if (state.activeFileId == id) return;
    forceSave(specificId: state.activeFileId);
    state = state.copyWith(activeFileId: id);
  }

  void deleteFile(String id) {
    fileBox.delete(id);
    final files = fileBox.values.toList();
    String? newActiveId;
    if (files.isNotEmpty) {
      if (state.activeFileId == id) {
        newActiveId = files.last.id;
      } else {
        newActiveId = state.activeFileId;
      }
    }
    state = state.copyWith(files: files, activeFileId: newActiveId);
    if (files.isEmpty) {
      _createNewFile();
    }
  }

  void renameActiveFile(String newName) {
    if (state.activeFileId == null) return;
    final activeFile = state.activeFile!;
    activeFile.name = newName;
    fileBox.put(activeFile.id, activeFile);
    state = state.copyWith(files: fileBox.values.toList());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final fileBoxProvider = Provider<Box<CodeFile>>((ref) => throw UnimplementedError());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileNotifier(box);
});
