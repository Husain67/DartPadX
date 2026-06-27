import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/file_model.dart';
import 'package:uuid/uuid.dart';

final fileProvider = StateNotifierProvider<FileNotifier, List<FileModel>>((ref) {
  return FileNotifier();
});

final currentFileIdProvider = StateProvider<String?>((ref) => null);

class FileNotifier extends StateNotifier<List<FileModel>> {
  FileNotifier() : super([]) {
    _loadFiles();
  }

  Box<FileModel>? _box;
  Timer? _saveTimer;
  final _uuid = const Uuid();

  List<FileModel> get currentState => state;

  Future<void> _loadFiles() async {
    _box = Hive.box<FileModel>('files');
    final files = _box!.values.toList();
    if (files.isEmpty) {
      final defaultFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
        lastModified: DateTime.now(),
      );
      await _box!.put(defaultFile.id, defaultFile);
      state = [defaultFile];
    } else {
      state = files;
    }
  }

  void addFile(String name, String content) {
    final newFile = FileModel(
      id: _uuid.v4(),
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    _box!.put(newFile.id, newFile);
    state = [...state, newFile];
  }

  void updateFileContent(String id, String newContent) {
    final index = state.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final updatedFile = state[index].copyWith(
      content: newContent,
      lastModified: DateTime.now(),
    );

    final newState = [...state];
    newState[index] = updatedFile;
    state = newState;

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box!.put(id, updatedFile);
    });
  }

  void updateFileName(String id, String newName) {
    final index = state.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final updatedFile = state[index].copyWith(
      name: newName,
      lastModified: DateTime.now(),
    );

    final newState = [...state];
    newState[index] = updatedFile;
    state = newState;
    _box!.put(id, updatedFile);
  }

  void deleteFile(String id) {
    _box!.delete(id);
    state = state.where((f) => f.id != id).toList();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
