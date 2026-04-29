import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({
    required this.files,
    required this.activeFileId,
  });

  FileState copyWith({
    List<CodeFile>? files,
    String? activeFileId,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> box;
  Timer? _debounceTimer;

  FileNotifier(this.box) : super(FileState(
    files: box.values.toList(),
    activeFileId: '',
  )) {
    if (state.files.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Welcome to DartMini IDE!');
}
''',
      );
      box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void addFile(String name, String content) {
    final newFile = CodeFile(id: const Uuid().v4(), name: name, content: content);
    box.put(newFile.id, newFile);
    state = state.copyWith(
      files: box.values.toList(),
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    final fileIndex = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (fileIndex != -1) {
      final updatedFile = state.files[fileIndex].copyWith(content: content);

      final updatedFiles = List<CodeFile>.from(state.files);
      updatedFiles[fileIndex] = updatedFile;

      state = state.copyWith(files: updatedFiles);

      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        if (!const bool.hasEnvironment('FLUTTER_TEST')) {
          box.put(updatedFile.id, updatedFile);
        }
      });
    }
  }

  void forceSave() {
     _debounceTimer?.cancel();
     final activeFile = state.files.firstWhere((f) => f.id == state.activeFileId, orElse: () => CodeFile(id: '', name: '', content: ''));
     if(activeFile.id.isNotEmpty) {
       box.put(activeFile.id, activeFile);
     }
  }

  void deleteActiveFile() {
    if (state.files.isEmpty) return;

    final idToDelete = state.activeFileId;
    box.delete(idToDelete);

    final remainingFiles = box.values.toList();
    if (remainingFiles.isEmpty) {
      addFile('untitled.dart', '');
    } else {
      state = state.copyWith(
        files: remainingFiles,
        activeFileId: remainingFiles.first.id,
      );
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<CodeFile>('files');
  return FileNotifier(box);
});
