import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;
  final bool isContentChangedExternally;

  FileState({
    required this.files,
    this.activeFileId,
    this.isContentChangedExternally = false,
  });

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((file) => file.id == activeFileId);
    } catch (_) {
      return null;
    }
  }

  FileState copyWith({
    List<CodeFile>? files,
    String? activeFileId,
    bool? isContentChangedExternally,
  }) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
      isContentChangedExternally: isContentChangedExternally ?? this.isContentChangedExternally,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _box;
  final _uuid = const Uuid();

  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>('code_files');

    List<CodeFile> savedFiles = _box.values.toList();
    if (savedFiles.isEmpty) {
      final defaultFile = CodeFile(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
        isSaved: true,
      );
      await _box.put(defaultFile.id, defaultFile);
      savedFiles = [defaultFile];
    }

    state = FileState(
      files: savedFiles,
      activeFileId: savedFiles.first.id,
    );
  }

  void setActiveFile(String id) {
    if (state.activeFileId != id) {
      state = state.copyWith(activeFileId: id, isContentChangedExternally: true);
    }
  }

  void updateActiveFileContent(String content, {bool isExternal = false}) {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      activeFile.content = content;
      activeFile.isSaved = false;
      activeFile.save(); // Hive save

      final newFiles = List<CodeFile>.from(state.files);
      final index = newFiles.indexWhere((f) => f.id == activeFile.id);
      if (index != -1) {
        newFiles[index] = activeFile;
        state = state.copyWith(files: newFiles, isContentChangedExternally: isExternal);
      }
    }
  }

  void saveActiveFile() {
    final activeFile = state.activeFile;
    if (activeFile != null && !activeFile.isSaved) {
      activeFile.isSaved = true;
      activeFile.save();

      final newFiles = List<CodeFile>.from(state.files);
      final index = newFiles.indexWhere((f) => f.id == activeFile.id);
      if (index != -1) {
        newFiles[index] = activeFile;
        state = state.copyWith(files: newFiles);
      }
    }
  }

  Future<void> createNewFile() async {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: 'untitled_${state.files.length}.dart',
      content: '',
      isSaved: true,
    );
    await _box.put(newFile.id, newFile);

    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
      isContentChangedExternally: true,
    );
  }

  Future<void> importFile(String name, String content) async {
    final newFile = CodeFile(
      id: _uuid.v4(),
      name: name,
      content: content,
      isSaved: true,
    );
    await _box.put(newFile.id, newFile);

    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
      isContentChangedExternally: true,
    );
  }

  Future<void> deleteActiveFile() async {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      await _box.delete(activeFile.id);
      final newFiles = state.files.where((f) => f.id != activeFile.id).toList();

      if (newFiles.isEmpty) {
        final defaultFile = CodeFile(
          id: _uuid.v4(),
          name: 'untitled.dart',
          content: '',
          isSaved: true,
        );
        await _box.put(defaultFile.id, defaultFile);
        newFiles.add(defaultFile);
      }

      state = state.copyWith(
        files: newFiles,
        activeFileId: newFiles.first.id,
        isContentChangedExternally: true,
      );
    }
  }
}
