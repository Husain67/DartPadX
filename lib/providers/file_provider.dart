import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_style/dart_style.dart';
import '../models/code_file.dart';
import '../services/hive_service.dart';

class FileState {
  final List<CodeFile> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [], activeFileId: '')) {
    _init();
  }

  Timer? _debounceTimer;

  void _init() {
    final box = HiveService.filesBox;
    if (box.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello DartMini!');\n}",
      );
      box.put(defaultFile.id, defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      final files = box.values.toList();
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  CodeFile? get activeFile {
    if (state.activeFileId.isEmpty) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void setActiveFile(String id) {
    _forceSaveCurrent();
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId.isEmpty) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        f.content = content;
        return f;
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      final file = state.files.firstWhere((f) => f.id == state.activeFileId);
      HiveService.filesBox.put(file.id, file);
    });
  }

  void _forceSaveCurrent() {
    _debounceTimer?.cancel();
    if (state.activeFileId.isNotEmpty) {
      try {
         final file = state.files.firstWhere((f) => f.id == state.activeFileId);
         HiveService.filesBox.put(file.id, file);
      } catch (_) {}
    }
  }

  void addFile([String? content, String name = 'untitled.dart']) {
    _forceSaveCurrent();
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content ?? "void main() {\n  // New file\n}",
    );
    HiveService.filesBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void deleteActiveFile() {
    if (state.activeFileId.isEmpty) return;

    final idToRemove = state.activeFileId;
    HiveService.filesBox.delete(idToRemove);

    final remainingFiles = state.files.where((f) => f.id != idToRemove).toList();

    if (remainingFiles.isEmpty) {
      state = FileState(files: [], activeFileId: '');
      addFile();
    } else {
      state = FileState(files: remainingFiles, activeFileId: remainingFiles.last.id);
    }
  }

  void formatActiveCode() {
    final file = activeFile;
    if (file == null) return;
    try {
      final formatter = DartFormatter(languageVersion: DartFormatter.latestShortStyleLanguageVersion);
      final formatted = formatter.format(file.content);
      updateActiveFileContent(formatted);
      state = state.copyWith(files: List.from(state.files));
    } catch (e) {
      // syntax error, ignore
    }
  }

  void forceRefresh() {
    state = state.copyWith(files: List.from(state.files));
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) => FileNotifier());
