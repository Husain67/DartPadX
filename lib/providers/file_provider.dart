import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../services/hive_service.dart';

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

  CodeFile? get activeFile => files.firstWhere((f) => f.id == activeFileId, orElse: () => files.first);
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = HiveService.fileBox;
    if (box.isEmpty) {
      final initialFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: 'void main() {\n  print("Hello, DartMini IDE!");\n}\n',
        lastModified: DateTime.now(),
      );
      box.put(initialFile.id, initialFile);
      state = FileState(files: [initialFile], activeFileId: initialFile.id);
    } else {
      state = FileState(
        files: box.values.toList(),
        activeFileId: box.values.first.id,
      );
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void createFile(String name) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: '',
      lastModified: DateTime.now(),
    );
    HiveService.fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;
    final index = state.files.indexWhere((f) => f.id == state.activeFileId);
    if (index != -1) {
      final updatedFile = state.files[index].copyWith(
        content: content,
        lastModified: DateTime.now(),
      );
      HiveService.fileBox.put(updatedFile.id, updatedFile);
      final newFiles = List<CodeFile>.from(state.files);
      newFiles[index] = updatedFile;
      state = state.copyWith(files: newFiles);
    }
  }

  void forceUpdate() {
    state = state.copyWith(files: List.from(state.files));
  }

  void deleteActiveFile() {
    if (state.activeFileId == null) return;
    HiveService.fileBox.delete(state.activeFileId);
    final remainingFiles = state.files.where((f) => f.id != state.activeFileId).toList();

    if (remainingFiles.isEmpty) {
      final newFile = CodeFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
        lastModified: DateTime.now(),
      );
      HiveService.fileBox.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      state = FileState(files: remainingFiles, activeFileId: remainingFiles.first.id);
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});
