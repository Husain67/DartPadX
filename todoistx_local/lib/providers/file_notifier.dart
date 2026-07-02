import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/app_file.dart';

final filesProvider = StateNotifierProvider<FileNotifier, List<AppFile>>((ref) {
  return FileNotifier();
});

final activeFileIdProvider = StateProvider<String?>((ref) => null);

class FileNotifier extends StateNotifier<List<AppFile>> {
  FileNotifier() : super([]) {
    _loadFiles();
  }

  Box<AppFile>? _box;
  Timer? _saveTimer;

  void _loadFiles() async {
    _box = Hive.box<AppFile>('appFiles');
    final files = _box!.values.toList();

    if (files.isEmpty) {
      final defaultFile = AppFile(
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}''',
      );
      _box!.put(defaultFile.id, defaultFile);
      state = [defaultFile];
    } else {
      state = files;
    }
  }

  void createFile(String name, [String content = '']) {
    final newFile = AppFile(name: name, content: content);
    _box?.put(newFile.id, newFile);
    state = [...state, newFile];
  }

  void importFile(String name, String content) {
    createFile(name, content);
  }

  void updateFileContent(String id, String newContent) {
    final index = state.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final file = state[index];
    if (file.content == newContent) return;

    final updatedFile = file.copyWith(content: newContent);
    final newState = [...state];
    newState[index] = updatedFile;
    state = newState;

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box?.put(id, updatedFile);
    });
  }

  void renameFile(String id, String newName) {
    final index = state.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final updatedFile = state[index].copyWith(name: newName);
    _box?.put(id, updatedFile);

    final newState = [...state];
    newState[index] = updatedFile;
    state = newState;
  }

  void deleteFile(String id) {
    _box?.delete(id);
    state = state.where((f) => f.id != id).toList();
  }
}
