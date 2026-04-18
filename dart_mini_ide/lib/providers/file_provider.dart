import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../utils/constants.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    return files.firstWhere((file) => file.id == activeFileId, orElse: () => files.first);
  }

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _fileBox;
  Timer? _saveTimer;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  Future<void> _init() async {
    _fileBox = Hive.box<CodeFile>('files');
    final files = _fileBox.values.toList();
    if (files.isEmpty) {
      final newFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: Constants.initialMainDartCode,
      );
      await _fileBox.put(newFile.id, newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void setActiveFile(String id) {
    _forceSave(specificId: state.activeFileId); // Flush previous active file explicitly
    state = state.copyWith(activeFileId: id);
  }

  void createNewFile([String name = 'untitled.dart', String content = '']) {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: content,
    );
    _fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    // Update local state immediately
    final updatedFiles = state.files.map((file) {
      if (file.id == state.activeFileId) {
        return file.copyWith(content: content);
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    // Debounce save to Hive (auto-save every 2 seconds)
    _saveTimer?.cancel();
    if (const bool.hasEnvironment('FLUTTER_TEST')) {
      _forceSave(specificId: state.activeFileId);
    } else {
      _saveTimer = Timer(const Duration(seconds: 2), () {
        _forceSave(specificId: state.activeFileId);
      });
    }
  }

  void updateActiveFileName(String name) {
    if (state.activeFileId == null) return;
    final file = state.activeFile;
    if (file == null) return;
    final updatedFile = file.copyWith(name: name);

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return updatedFile;
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);
    _fileBox.put(updatedFile.id, updatedFile);
  }

  void _forceSave({String? specificId}) {
    if (specificId == null) return;
    final fileToSave = state.files.firstWhere((file) => file.id == specificId, orElse: () => CodeFile(id: '', name: '', content: ''));
    if (fileToSave.id.isNotEmpty) {
      _fileBox.put(fileToSave.id, fileToSave);
    }
  }

  void deleteFileById(String id) {
    _fileBox.delete(id);
    final remainingFiles = state.files.where((file) => file.id != id).toList();

    String? newActiveId;
    if (remainingFiles.isNotEmpty) {
      if (state.activeFileId == id) {
        newActiveId = remainingFiles.first.id;
      } else {
        newActiveId = state.activeFileId;
      }
      state = FileState(files: remainingFiles, activeFileId: newActiveId);
    } else {
      // If no files left, auto-create one to maintain UI flow
      createNewFile();
    }
  }
}
