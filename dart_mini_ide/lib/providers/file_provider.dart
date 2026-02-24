import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/code_file.dart';
import '../services/hive_service.dart';

final fileProvider = StateNotifierProvider<FileNotifier, List<CodeFile>>((ref) {
  return FileNotifier();
});

class FileNotifier extends StateNotifier<List<CodeFile>> {
  Timer? _saveTimer;

  FileNotifier() : super([]) {
    _init();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final box = Hive.box<CodeFile>(HiveService.filesBoxName);
    if (box.isEmpty) {
      final defaultFile = CodeFile(
        name: 'main.dart',
        content: '''void main() {
  print("Hello, DartMini!");
  // Try input/output
  // import 'dart:io';
  // String? input = stdin.readLineSync();
  // print("You entered: \$input");
}''',
        lastModified: DateTime.now(),
      );
      await box.add(defaultFile);
    }
    state = box.values.toList();
  }

  Future<void> addFile(String name, String content) async {
    final newFile = CodeFile(
      name: name,
      content: content,
      lastModified: DateTime.now(),
    );
    final box = Hive.box<CodeFile>(HiveService.filesBoxName);
    await box.add(newFile);
    state = box.values.toList();
  }

  Future<void> updateFileContent(int index, String newContent) async {
    final box = Hive.box<CodeFile>(HiveService.filesBoxName);
    if (index >= 0 && index < box.length) {
      final file = box.getAt(index);
      if (file != null) {
        file.content = newContent;
        file.lastModified = DateTime.now();

        _saveTimer?.cancel();
        _saveTimer = Timer(const Duration(seconds: 2), () {
          file.save();
        });

        state = List.from(box.values);
      }
    }
  }

  Future<void> renameFile(int index, String newName) async {
    final box = Hive.box<CodeFile>(HiveService.filesBoxName);
    if (index >= 0 && index < box.length) {
       final file = box.getAt(index);
       if (file != null) {
         file.name = newName;
         await file.save();
         state = List.from(box.values);
       }
    }
  }

  Future<void> deleteFile(int index) async {
    final box = Hive.box<CodeFile>(HiveService.filesBoxName);
    if (index >= 0 && index < box.length) {
      await box.deleteAt(index);
      if (box.isEmpty) {
        await addFile('untitled.dart', '');
      } else {
        state = box.values.toList();
      }
    }
  }
}

final currentFileIndexProvider = StateProvider<int>((ref) => 0);

final currentFileProvider = Provider<CodeFile?>((ref) {
  final files = ref.watch(fileProvider);
  final index = ref.watch(currentFileIndexProvider);
  if (index >= 0 && index < files.length) {
    return files[index];
  }
  return null;
});
