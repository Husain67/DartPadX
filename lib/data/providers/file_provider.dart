import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../hive_service.dart';
import '../models/file_model.dart';
import '../../core/constants.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileModel? get activeFile => files.cast<FileModel?>().firstWhere((f) => f?.id == activeFileId, orElse: () => null);

  FileState copyWith({List<FileModel>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  Timer? _saveTimer;

  FileNotifier() : super(FileState(files: HiveService.filesBox.values.toList())) {
    if (state.files.isNotEmpty) {
      state = state.copyWith(activeFileId: state.files.first.id);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == activeId) {
        return f.copyWith(content: content, lastModified: DateTime.now().millisecondsSinceEpoch);
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    // Debounce save
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      final fileToSave = updatedFiles.firstWhere((f) => f.id == activeId);
      HiveService.filesBox.put(activeId, fileToSave);
    });
  }

  void createNewFile() {
    final id = const Uuid().v4();
    // find next untitled number
    int counter = 1;
    String name = 'untitled.dart';
    while (state.files.any((f) => f.name == name)) {
      counter++;
      name = 'untitled\$counter.dart';
    }

    final newFile = FileModel(
      id: id,
      name: name,
      content: '// \$name\nvoid main() {\n  \n}\n',
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );

    HiveService.filesBox.put(id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: id,
    );
  }

  void importFile(String name, String content) {
    final id = const Uuid().v4();
    final newFile = FileModel(
      id: id,
      name: name,
      content: content,
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
    HiveService.filesBox.put(id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: id,
    );
  }

  void deleteActiveFile() {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    HiveService.filesBox.delete(activeId);
    final updatedFiles = state.files.where((f) => f.id != activeId).toList();

    if (updatedFiles.isEmpty) {
      // Create a default file if all are deleted
      final id = const Uuid().v4();
      final newFile = FileModel(
        id: id,
        name: AppConstants.defaultFileName,
        content: AppConstants.defaultCode,
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );
      HiveService.filesBox.put(id, newFile);
      state = FileState(files: [newFile], activeFileId: id);
    } else {
      state = FileState(files: updatedFiles, activeFileId: updatedFiles.first.id);
    }
  }

  void forceSave() {
     _saveTimer?.cancel();
     final activeId = state.activeFileId;
     if (activeId != null) {
       final fileToSave = state.files.firstWhere((f) => f.id == activeId);
       HiveService.filesBox.put(activeId, fileToSave);
     }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
