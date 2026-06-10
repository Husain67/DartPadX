import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/dart_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<DartFile> files;
  final String? activeFileId;

  FileState({this.files = const [], this.activeFileId});

  FileState copyWith({List<DartFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  DartFile? get activeFile =>
      files.cast<DartFile?>().firstWhere((f) => f?.id == activeFileId, orElse: () => null);
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState()) {
    _loadFiles();
  }

  late Box<DartFile> _box;
  final _uuid = const Uuid();
  Timer? _debounceTimer;

  FileState get currentState => state;

  Future<void> _loadFiles() async {
    _box = Hive.box<DartFile>('files');
    final files = _box.values.toList();
    if (files.isEmpty) {
      _createNewFile(name: 'main.dart', content: 'void main() {\n  print("Hello from DartMini IDE!");\n}\n');
    } else {
      state = state.copyWith(files: files, activeFileId: files.first.id);
    }
  }

  void _createNewFile({String? name, String? content}) {
    final id = _uuid.v4();
    final newFile = DartFile(
      id: id,
      name: name ?? 'untitled_${state.files.length + 1}.dart',
      content: content ?? '',
    );
    _box.put(id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: id,
    );
  }

  void createNewFile() {
    _createNewFile();
  }

  void switchFile(String id) {
    if (state.activeFileId != id) {
      state = state.copyWith(activeFileId: id);
    }
  }

  void updateActiveFileContent(String newContent) {
    final activeFileId = state.activeFileId;
    if (activeFileId == null) return;

    final updatedFiles = state.files.map((file) {
      if (file.id == activeFileId) {
        return file.copyWith(content: newContent);
      }
      return file;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      final fileToSave = updatedFiles.firstWhere((f) => f.id == activeFileId);
      _box.put(activeFileId, fileToSave);
    });
  }

  void deleteFile(String id) {
    _box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();
    if (remainingFiles.isEmpty) {
      state = state.copyWith(files: [], activeFileId: null);
      _createNewFile(); // Auto-create if empty
    } else {
      final nextId = remainingFiles.last.id;
      state = state.copyWith(files: remainingFiles, activeFileId: nextId);
    }
  }
}
