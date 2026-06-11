import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/file_model.dart';

class FileState {
  final List<FileModel> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  FileState copyWith({List<FileModel>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  FileModel? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return null;
    }
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<FileModel> _box;
  Timer? _saveTimer;
  final _uuid = const Uuid();

  FileNotifier(this._box) : super(FileState(files: [])) {
    _loadFiles();
  }

  FileState get currentState => state;

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final defaultFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print("Hello, DartMini!");
}''',
      );
      _box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }
    state = FileState(files: files, activeFileId: files.first.id);
  }

  void newFile() {
    final newFile = FileModel(
      id: _uuid.v4(),
      name: 'untitled_${state.files.length + 1}.dart',
      content: '',
    );
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void switchTab(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void closeTab(String id) {
    if (state.files.length == 1) return; // Don't close the last tab
    final index = state.files.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final newFiles = List<FileModel>.from(state.files)..removeAt(index);
    String? newActiveId = state.activeFileId;
    if (newActiveId == id) {
      newActiveId = newFiles.last.id;
    }

    state = state.copyWith(files: newFiles, activeFileId: newActiveId);
    // Note: We don't delete from Hive on close tab, just from the UI session.
    // Actually, "Delete current file" is a separate action.
  }

  Future<void> deleteFile(String id) async {
    await _box.delete(id);
    final newFiles = List<FileModel>.from(state.files)..removeWhere((f) => f.id == id);
    if (newFiles.isEmpty) {
      final newFile = FileModel(
        id: _uuid.v4(),
        name: 'untitled.dart',
        content: '',
      );
      await _box.put(newFile.id, newFile);
      newFiles.add(newFile);
    }
    String? newActiveId = state.activeFileId;
    if (newActiveId == id) {
      newActiveId = newFiles.last.id;
    }
    state = state.copyWith(files: newFiles, activeFileId: newActiveId);
  }

  void updateActiveFileContent(String content) {
    final active = state.activeFile;
    if (active == null) return;

    // Update local state instantly
    final updatedFile = active.copyWith(content: content);
    final newFiles = state.files.map((f) => f.id == active.id ? updatedFile : f).toList();
    state = state.copyWith(files: newFiles);

    // Debounce save to Hive
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _box.put(updatedFile.id, updatedFile);
    });
  }

  void updateActiveFileName(String newName) {
     final active = state.activeFile;
    if (active == null) return;

    final updatedFile = active.copyWith(name: newName);
    final newFiles = state.files.map((f) => f.id == active.id ? updatedFile : f).toList();
    state = state.copyWith(files: newFiles);
    _box.put(updatedFile.id, updatedFile);
  }

  Future<void> importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart', 'txt', 'json'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      String name = result.files.single.name;

      final importedFile = FileModel(
        id: _uuid.v4(),
        name: name,
        content: content,
      );
      await _box.put(importedFile.id, importedFile);
      state = state.copyWith(
        files: [...state.files, importedFile],
        activeFileId: importedFile.id,
      );
    }
  }

  Future<void> exportFile() async {
    final active = state.activeFile;
    if (active == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${active.name}');
    await file.writeAsString(active.content);

    await Share.shareXFiles([XFile(file.path)], text: 'Exported from DartMini IDE');
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<FileModel>('files');
  return FileNotifier(box);
});
