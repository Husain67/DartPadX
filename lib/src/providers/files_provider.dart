import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/code_file.dart';
import '../services/hive_storage_service.dart';


class FilesState {
  final List<CodeFile> files;
  final String activeFileId;

  FilesState({required this.files, required this.activeFileId});

  FilesState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FilesState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FilesNotifier extends StateNotifier<FilesState> {
  FilesNotifier() : super(FilesState(files: [], activeFileId: '')) {
    _loadFiles();
  }

  void _loadFiles() {
    final box = HiveStorageService.filesBox;
    final files = box.values.toList();
    if (files.isNotEmpty) {
      state = FilesState(files: files, activeFileId: files.first.id);
    }
  }

  void addFile(String name, [String content = '']) {
    final newFile = CodeFile(name: name, content: content);
    HiveStorageService.filesBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId.isEmpty) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        final updatedFile = f.copyWith(content: content);
        HiveStorageService.filesBox.put(f.id, updatedFile);
        return updatedFile;
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void deleteFile(String id) {
    HiveStorageService.filesBox.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();

    if (remainingFiles.isEmpty) {
      addFile('untitled.dart');
    } else {
      String newActiveId = state.activeFileId;
      if (id == state.activeFileId) {
        newActiveId = remainingFiles.first.id;
      }
      state = state.copyWith(files: remainingFiles, activeFileId: newActiveId);
    }
  }
}

final filesProvider = StateNotifierProvider<FilesNotifier, FilesState>((ref) {
  return FilesNotifier();
});
