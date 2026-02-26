import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/code_file.dart';

// State class
class FileState {
  final List<CodeFile> files;
  final CodeFile? currentFile;

  FileState({required this.files, this.currentFile});

  FileState copyWith({List<CodeFile>? files, CodeFile? currentFile}) {
    return FileState(
      files: files ?? this.files,
      currentFile: currentFile ?? this.currentFile,
    );
  }
}

// Notifier
class FileNotifier extends StateNotifier<FileState> {
  final Box<CodeFile> _box;
  Timer? _autoSaveTimer;

  FileNotifier(this._box) : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        name: 'main.dart',
        content: 'void main() {\n  print("Hello DartMini!");\n}',
      );
      _box.add(defaultFile);
      state = FileState(files: [defaultFile], currentFile: defaultFile);
    } else {
      state = FileState(files: files, currentFile: files.first);
    }
  }

  void selectFile(CodeFile file) {
    // Save previous file if needed (auto-save handles it usually, but let's be safe)
    _saveCurrent();
    state = state.copyWith(currentFile: file);
  }

  Future<void> addFile() async {
    String name = 'untitled_${state.files.length + 1}.dart';
    final newFile = CodeFile(name: name, content: '');
    await _box.add(newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      currentFile: newFile,
    );
  }

  Future<void> importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dart'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      String name = result.files.single.name;

      final newFile = CodeFile(name: name, content: content);
      await _box.add(newFile);

      state = state.copyWith(
        files: [...state.files, newFile],
        currentFile: newFile,
      );
    }
  }

  Future<void> deleteFile(CodeFile file) async {
    await file.delete(); // Delete from Hive

    final updatedFiles = _box.values.toList();
    CodeFile? nextFile = state.currentFile;

    if (state.currentFile == file || !updatedFiles.contains(state.currentFile)) {
       if (updatedFiles.isNotEmpty) {
         nextFile = updatedFiles.last;
       } else {
         nextFile = CodeFile(name: 'untitled.dart', content: '');
         await _box.add(nextFile);
         updatedFiles.add(nextFile);
       }
    }

    state = state.copyWith(
      files: updatedFiles,
      currentFile: nextFile,
    );
  }

  Future<void> deleteCurrentFile() async {
    final current = state.currentFile;
    if (current != null) {
      await deleteFile(current);
    }
  }

  void updateContent(String content) {
    if (state.currentFile == null) return;

    // Update in memory immediately for UI responsiveness
    state.currentFile!.content = content;
    // Hive object is updated in memory, but not persisted to disk until save()

    // Debounce save
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveCurrent();
    });
  }

  Future<void> _saveCurrent() async {
    if (state.currentFile != null && state.currentFile!.isInBox) {
      await state.currentFile!.save();
    }
  }

  Future<void> downloadCurrentFile() async {
    final current = state.currentFile;
    if (current == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${current.name}');
    await file.writeAsString(current.content);

    await Share.shareXFiles([XFile(file.path)], text: 'Here is my Dart code!');
  }
}

// Provider
final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<CodeFile>('code_files');
  return FileNotifier(box);
});
