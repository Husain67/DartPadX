import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/file_model.dart';
import '../services/hive_service.dart';
import 'hive_provider.dart';

class FileState {
  final List<FileModel> files;
  final String? currentFileId;

  FileState({required this.files, this.currentFileId});

  FileState copyWith({List<FileModel>? files, String? currentFileId}) {
    return FileState(
      files: files ?? this.files,
      currentFileId: currentFileId ?? this.currentFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final HiveService _hiveService;
  Timer? _saveTimer;

  FileNotifier(this._hiveService) : super(FileState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _hiveService.filesBox.values.toList();
    final currentFileId = _hiveService.prefs.getString(HiveService.currentFileIdKey);
    state = FileState(files: files, currentFileId: currentFileId);
  }

  FileModel? get currentFile {
    if (state.currentFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.currentFileId);
    } catch (_) {
      return null;
    }
  }

  Future<void> switchFile(String id) async {
    await _hiveService.prefs.setString(HiveService.currentFileIdKey, id);
    state = state.copyWith(currentFileId: id);
  }

  Future<FileModel> createFile([String? name]) async {
    final newId = const Uuid().v4();
    final newFile = FileModel(
      id: newId,
      name: name ?? 'untitled.dart',
      content: '',
      lastModified: DateTime.now(),
    );
    await _hiveService.filesBox.put(newId, newFile);
    final updatedFiles = [...state.files, newFile];
    state = state.copyWith(files: updatedFiles);
    await switchFile(newId);
    return newFile;
  }

  Future<void> deleteCurrentFile() async {
    final fileId = state.currentFileId;
    if (fileId == null) return;

    await _hiveService.filesBox.delete(fileId);
    final updatedFiles = state.files.where((f) => f.id != fileId).toList();

    if (updatedFiles.isEmpty) {
      state = state.copyWith(files: updatedFiles, currentFileId: null);
      await createFile();
    } else {
      await switchFile(updatedFiles.first.id);
      state = state.copyWith(files: updatedFiles);
    }
  }

  void updateCurrentFileContent(String content) {
    final file = currentFile;
    if (file == null) return;

    final updatedFile = file.copyWith(content: content, lastModified: DateTime.now());

    final updatedFiles = state.files.map((f) => f.id == updatedFile.id ? updatedFile : f).toList();
    state = state.copyWith(files: updatedFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      await _hiveService.filesBox.put(updatedFile.id, updatedFile);
    });
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return FileNotifier(hiveService);
});
