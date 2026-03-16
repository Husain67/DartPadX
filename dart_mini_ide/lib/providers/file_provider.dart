import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final filesProvider = StateNotifierProvider<FilesNotifier, List<CodeFile>>((ref) {
  return FilesNotifier();
});

final activeFileIdProvider = StateNotifierProvider<ActiveFileNotifier, String?>((ref) {
  return ActiveFileNotifier();
});

class FilesNotifier extends StateNotifier<List<CodeFile>> {
  late Box<CodeFile> _box;

  FilesNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CodeFile>('files');
    if (_box.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
      );
      await _box.put(defaultFile.id, defaultFile);
    }
    state = _box.values.toList();
  }

  void addFile(CodeFile file) {
    _box.put(file.id, file);
    state = _box.values.toList();
  }

  void updateFile(String id, String content) {
    final file = _box.get(id);
    if (file != null) {
      file.content = content;
      file.save();
      state = _box.values.toList();
    }
  }

  void renameFile(String id, String newName) {
    final file = _box.get(id);
    if (file != null) {
      file.name = newName;
      file.save();
      state = _box.values.toList();
    }
  }

  void deleteFile(String id) {
    _box.delete(id);
    state = _box.values.toList();
  }
}

class ActiveFileNotifier extends StateNotifier<String?> {
  ActiveFileNotifier() : super(null) {
    _init();
  }

  void _init() {
    final box = Hive.box<CodeFile>('files');
    if (box.isNotEmpty) {
      state = box.keys.first.toString();
    }
  }

  void setActive(String id) {
    state = id;
  }
}
