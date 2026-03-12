import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({
    required this.files,
    this.activeFileId,
  });

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }

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
  static const String _activeFileKey = 'active_file_id';

  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final box = Hive.box<CodeFile>('filesBox');
    final prefs = await SharedPreferences.getInstance();

    if (box.isEmpty) {
      final defaultFile = CodeFile(
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
      );
      box.put(defaultFile.id, defaultFile);
      prefs.setString(_activeFileKey, defaultFile.id);
    }

    final files = box.values.toList();
    var activeId = prefs.getString(_activeFileKey);

    if (activeId == null || !files.any((f) => f.id == activeId)) {
      activeId = files.isNotEmpty ? files.first.id : null;
    }

    state = state.copyWith(files: files, activeFileId: activeId);
  }

  void setActiveFile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeFileKey, id);
    state = state.copyWith(activeFileId: id);
  }

  void createFile(String name, [String content = '']) {
    final box = Hive.box<CodeFile>('filesBox');
    final newFile = CodeFile(name: name, content: content);
    box.put(newFile.id, newFile);

    state = state.copyWith(
      files: box.values.toList(),
    );
    setActiveFile(newFile.id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final box = Hive.box<CodeFile>('filesBox');
    final file = box.get(state.activeFileId);
    if (file != null) {
      file.content = content;
      box.put(file.id, file); // Auto-save

      state = state.copyWith(
        files: box.values.toList(), // Refresh list to trigger UI updates if needed
      );
    }
  }

  void deleteFile(String id) {
    final box = Hive.box<CodeFile>('filesBox');
    box.delete(id);

    var files = box.values.toList();
    String? newActiveId = state.activeFileId;

    if (files.isEmpty) {
      // Create a default if all files are deleted
      createFile('untitled.dart');
      return;
    } else if (newActiveId == id) {
      // Find adjacent tab logic
      newActiveId = files.last.id;
      setActiveFile(newActiveId);
    }

    state = state.copyWith(files: files, activeFileId: newActiveId);
  }
}
