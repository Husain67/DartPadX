import 'dart:async';
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

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  CodeFile? get activeFile => files.where((f) => f.id == activeFileId).firstOrNull;
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [])) {
    _init();
  }

  late Box<CodeFile> _fileBox;
  Timer? _debounce;

  Future<void> _init() async {
    _fileBox = Hive.box<CodeFile>('files');

    if (_fileBox.isEmpty) {
      final defaultFile = CodeFile(
        id: const Uuid().v4(),
        title: 'main.dart',
        content: "void main() {\n  print('Hello from DartMini IDE!');\n}\n",
      );
      await _fileBox.put(defaultFile.id, defaultFile);
    }

    final files = _fileBox.values.toList();
    final activeId = files.isNotEmpty ? files.first.id : null;
    state = state.copyWith(files: files, activeFileId: activeId);
  }

  void switchFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  Future<void> createNewFile({String? title, String? content}) async {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      title: title ?? 'untitled.dart',
      content: content ?? '',
    );
    await _fileBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: _fileBox.values.toList(),
      activeFileId: newFile.id,
    );
  }

  Future<void> deleteActiveFile() async {
    if (state.activeFileId == null) return;

    final idToDelete = state.activeFileId!;
    await _fileBox.delete(idToDelete);

    final remaining = _fileBox.values.toList();
    String? newActiveId;
    if (remaining.isNotEmpty) {
      newActiveId = remaining.last.id;
    }

    state = state.copyWith(files: remaining, activeFileId: newActiveId);

    if (remaining.isEmpty) {
      await createNewFile();
    }
  }

  void updateActiveContent(String content, {bool triggerStateUpdate = false}) {
    if (state.activeFileId == null) return;

    final active = state.activeFile;
    if (active != null) {
      active.content = content;

      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(seconds: 2), () {
        _fileBox.put(active.id, active);
      });

      if (triggerStateUpdate) {
        state = state.copyWith(files: List.from(state.files));
      }
    }
  }

  Future<void> forceSave(String id, String content) async {
    final file = _fileBox.get(id);
    if (file != null) {
      file.content = content;
      await _fileBox.put(id, file);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
