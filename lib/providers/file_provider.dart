import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/project_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<ProjectFile> files;
  final int activeIndex;

  FileState({required this.files, required this.activeIndex});

  FileState copyWith({List<ProjectFile>? files, int? activeIndex}) {
    return FileState(
      files: files ?? this.files,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }

  ProjectFile? get activeFile => files.isNotEmpty && activeIndex >= 0 && activeIndex < files.length ? files[activeIndex] : null;
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<ProjectFile> _fileBox;
  Timer? _saveTimer;

  FileNotifier() : super(FileState(files: [], activeIndex: 0)) {
    _init();
  }

  FileState get currentState => state;

  Future<void> _init() async {
    _fileBox = Hive.box<ProjectFile>('files');
    if (_fileBox.isEmpty) {
      final defaultFile = ProjectFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: "import 'dart:io';\n\nvoid main() {\n  print('Hello DartMini IDE');\n  String? input = stdin.readLineSync();\n  print('Input received: \$input');\n}\n",
      );
      _fileBox.put(defaultFile.id, defaultFile);
    }
    state = FileState(files: _fileBox.values.toList(), activeIndex: 0);
  }

  void setActiveFile(int index) {
    if (index >= 0 && index < state.files.length) {
      state = state.copyWith(activeIndex: index);
    }
  }

  void addFile(String name, String content) {
    final newFile = ProjectFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
    );
    _fileBox.put(newFile.id, newFile);
    final updatedFiles = _fileBox.values.toList();
    state = state.copyWith(files: updatedFiles, activeIndex: updatedFiles.length - 1);
  }

  void deleteFile(String id) {
    _fileBox.delete(id);
    final updatedFiles = _fileBox.values.toList();
    int newIndex = state.activeIndex;
    if (updatedFiles.isEmpty) {
      final newFile = ProjectFile(
        id: const Uuid().v4(),
        name: 'untitled.dart',
        content: '',
      );
      _fileBox.put(newFile.id, newFile);
      state = state.copyWith(files: [newFile], activeIndex: 0);
    } else {
      if (newIndex >= updatedFiles.length) {
        newIndex = updatedFiles.length - 1;
      }
      state = state.copyWith(files: updatedFiles, activeIndex: newIndex);
    }
  }

  void updateActiveFileContent(String newContent) {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      final updatedFile = activeFile.copyWith(content: newContent);

      final files = List<ProjectFile>.from(state.files);
      files[state.activeIndex] = updatedFile;
      state = state.copyWith(files: files);

      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), () {
        _fileBox.put(updatedFile.id, updatedFile);
      });
    }
  }
}
