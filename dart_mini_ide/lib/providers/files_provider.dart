import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final filesProvider = StateNotifierProvider<FilesNotifier, List<CodeFile>>((ref) {
  return FilesNotifier();
});

final activeFileIdProvider = StateProvider<String?>((ref) {
  final files = ref.watch(filesProvider);
  if (files.isEmpty) return null;
  return files.first.id;
});

class FilesNotifier extends StateNotifier<List<CodeFile>> {
  final Box<CodeFile> _box = Hive.box<CodeFile>('code_files');

  FilesNotifier() : super([]) {
    _loadFiles();
  }

  void _loadFiles() {
    if (_box.isEmpty) {
      // Create default main.dart
      final newFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
        lastModified: DateTime.now(),
      );
      _box.put(newFile.id, newFile);
    }
    state = _box.values.toList()..sort((a, b) => b.lastModified.compareTo(a.lastModified));
  }

  CodeFile? getFile(String id) {
    try {
      return state.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  String createFile(String name, String content) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    _box.put(newFile.id, newFile);
    state = [newFile, ...state];
    return newFile.id;
  }

  void updateFileContent(String id, String newContent) {
    final index = state.indexWhere((f) => f.id == id);
    if (index != -1) {
      final updated = state[index].copyWith(
        content: newContent,
        lastModified: DateTime.now(),
      );
      _box.put(id, updated);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
    }
  }

  String? deleteFile(String id) {
    final index = state.indexWhere((f) => f.id == id);
    if (index != -1) {
      _box.delete(id);
      final newState = List<CodeFile>.from(state)..removeAt(index);
      state = newState;
      if (newState.isEmpty) {
        return createFile('untitled.dart', '');
      } else {
        return newState.first.id;
      }
    }
    return null;
  }
}
