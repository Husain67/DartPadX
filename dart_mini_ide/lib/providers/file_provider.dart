import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import '../core/constants.dart';
import '../data/models/code_file.dart';

final fileBoxProvider = Provider<Box<CodeFile>>((ref) {
  return Hive.box<CodeFile>(AppConstants.fileBoxName);
});

final activeFileIdProvider = StateProvider<String?>((ref) => null);

final fileListProvider = StateNotifierProvider<FileListNotifier, List<CodeFile>>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileListNotifier(box, ref);
});

class FileListNotifier extends StateNotifier<List<CodeFile>> {
  final Box<CodeFile> _box;
  final Ref _ref;

  FileListNotifier(this._box, this._ref) : super(_box.values.toList()) {
    if (state.isEmpty) {
      createNewFile(name: 'main.dart', content: AppConstants.defaultCode);
    } else {
      // Set active file to the last modified or first one if not set
      if (_ref.read(activeFileIdProvider) == null) {
          // Sort by last modified? For now just pick first.
          _ref.read(activeFileIdProvider.notifier).state = state.first.id;
      }
    }
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
  }

  void createNewFile({String? name, String? content}) {
    final id = _generateId();
    final newFile = CodeFile(
      id: id,
      name: name ?? 'untitled${state.length + 1}.dart',
      content: content ?? '',
      lastModified: DateTime.now(),
    );
    _box.put(id, newFile);
    state = _box.values.toList();
    _ref.read(activeFileIdProvider.notifier).state = id;
  }

  void updateFileContent(String id, String content) {
    final file = _box.get(id);
    if (file != null) {
      file.content = content;
      file.lastModified = DateTime.now();
      file.save();
      // Force state update to reflect changes if needed
      state = _box.values.toList();
    }
  }

  void deleteFile(String id) {
    _box.delete(id);
    state = _box.values.toList();

    final currentActive = _ref.read(activeFileIdProvider);
    if (currentActive == id) {
      if (state.isNotEmpty) {
        _ref.read(activeFileIdProvider.notifier).state = state.last.id;
      } else {
        createNewFile(name: 'main.dart', content: AppConstants.defaultCode);
      }
    }
  }
}

final activeFileProvider = Provider<CodeFile?>((ref) {
  final id = ref.watch(activeFileIdProvider);
  final files = ref.watch(fileListProvider);
  if (id == null) return null;
  try {
    return files.firstWhere((f) => f.id == id);
  } catch (e) {
    if (files.isNotEmpty) return files.first;
    return null;
  }
});
