import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';

final fileProvider = StateNotifierProvider<FileNotifier, CodeFile?>((ref) {
  return FileNotifier();
});

final fileListProvider = Provider<List<CodeFile>>((ref) {
  final box = Hive.box<CodeFile>('code_files');
  return box.values.toList();
});

class FileNotifier extends StateNotifier<CodeFile?> {
  FileNotifier() : super(null) {
    _loadInitialFile();
  }

  late Box<CodeFile> _box;

  Future<void> _loadInitialFile() async {
    _box = await Hive.openBox<CodeFile>('code_files');
    if (_box.isEmpty) {
      await createNewFile('main.dart', _defaultCode);
    } else {
      state = _box.values.last;
    }
  }

  Future<void> createNewFile(String name, [String? content]) async {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name,
      content: content ?? '',
      lastModified: DateTime.now(),
    );
    await _box.add(newFile);
    state = newFile;
  }

  Future<void> updateContent(String newContent) async {
    if (state == null) return;
    state!.content = newContent;
    state!.lastModified = DateTime.now();
    await state!.save();
    // Start auto-save timer logic if needed, but Hive save is fast enough for now
    // Or we can just update state and save periodically.
    // For now, save on every update (debounce in UI).
  }

  Future<void> deleteCurrentFile() async {
    if (state == null) return;
    await state!.delete();
    if (_box.isNotEmpty) {
      state = _box.values.last;
    } else {
      await createNewFile('untitled.dart', '');
    }
  }

  void selectFile(CodeFile file) {
    state = file;
  }

  static const _defaultCode = '''void main() {
  print('Hello, Dart Mini IDE!');

  // Try editing this code and running it!
  // Output will appear below.
}
''';
}
