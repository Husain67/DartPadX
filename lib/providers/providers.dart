import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/editor_file.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('Initialize HiveService first');
});

// File State
class FileState {
  final List<EditorFile> files;
  final String? activeFileId;

  FileState({this.files = const [], this.activeFileId});

  FileState copyWith({List<EditorFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final HiveService _hiveService;

  FileNotifier(this._hiveService) : super(FileState()) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = _hiveService.getFiles();
    if (files.isEmpty) {
      final defaultFile = EditorFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'main.dart',
        content: '''import 'dart:io';

void main() {
  print('Hello from DartMini IDE!');
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Welcome, \$name!');
}''',
      );
      _hiveService.saveFile(defaultFile);
      state = FileState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = FileState(files: files, activeFileId: files.first.id);
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  EditorFile? get activeFile {
    if (state.activeFileId == null) return null;
    try {
      return state.files.firstWhere((f) => f.id == state.activeFileId);
    } catch (_) {
      return null;
    }
  }

  void updateActiveFileContent(String content) {
    final file = activeFile;
    if (file != null) {
      final updatedFile = file.copyWith(content: content);
      _hiveService.saveFile(updatedFile); // Note: Should add debounce in UI or Service
      final newFiles = state.files.map((f) => f.id == file.id ? updatedFile : f).toList();
      state = state.copyWith(files: newFiles);
    }
  }

  void addFile(EditorFile file) {
    _hiveService.saveFile(file);
    state = state.copyWith(
      files: [...state.files, file],
      activeFileId: file.id,
    );
  }

  void deleteFile(String id) {
    _hiveService.deleteFile(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();
    if (remainingFiles.isEmpty) {
      final newFile = EditorFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'untitled.dart',
        content: 'void main() {\n  \n}',
      );
      _hiveService.saveFile(newFile);
      state = FileState(files: [newFile], activeFileId: newFile.id);
    } else {
      final newActiveId = id == state.activeFileId ? remainingFiles.first.id : state.activeFileId;
      state = state.copyWith(files: remainingFiles, activeFileId: newActiveId);
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return FileNotifier(hiveService);
});

// Compiler Settings State
class CompilerState {
  final List<CompilerPreset> presets;
  final CompilerPreset? activePreset;

  CompilerState({this.presets = const [], this.activePreset});

  CompilerState copyWith({List<CompilerPreset>? presets, CompilerPreset? activePreset}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePreset: activePreset ?? this.activePreset,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final HiveService _hiveService;

  CompilerNotifier(this._hiveService) : super(CompilerState()) {
    _loadPresets();
  }

  void _loadPresets() {
    final presets = _hiveService.getPresets();
    if (presets.isEmpty) {
      _initializeDefaultPresets();
    } else {
      final defaultPreset = presets.firstWhere((p) => p.isDefault, orElse: () => presets.first);
      state = CompilerState(presets: presets, activePreset: defaultPreset);
    }
  }

  void _initializeDefaultPresets() {
    final oneCompiler = CompilerPreset(
      id: 'onecompiler_default',
      platformName: 'OneCompiler',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      httpMethod: 'POST',
      authType: 'API-Key Header',
      dynamicHeaders: {
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json'
      },
      requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
      isDefault: true,
    );
    // You'd add other presets like JDoodle, Piston here

    _hiveService.savePreset(oneCompiler);
    state = CompilerState(presets: [oneCompiler], activePreset: oneCompiler);
  }

  void setActivePreset(String id) {
    final presets = state.presets.map((p) {
      final updated = p.copyWith(isDefault: p.id == id);
      _hiveService.savePreset(updated);
      return updated;
    }).toList();
    state = state.copyWith(
      presets: presets,
      activePreset: presets.firstWhere((p) => p.id == id),
    );
  }

  void addOrUpdatePreset(CompilerPreset preset) {
    _hiveService.savePreset(preset);
    final exists = state.presets.any((p) => p.id == preset.id);
    List<CompilerPreset> newPresets;
    if (exists) {
      newPresets = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    } else {
      newPresets = [...state.presets, preset];
    }
    state = state.copyWith(
      presets: newPresets,
      activePreset: preset.isDefault ? preset : state.activePreset,
    );
  }

  void deletePreset(String id) {
    _hiveService.deletePreset(id);
    final newPresets = state.presets.where((p) => p.id != id).toList();
    CompilerPreset? newActive = state.activePreset;
    if (newActive?.id == id && newPresets.isNotEmpty) {
      newActive = newPresets.first;
      addOrUpdatePreset(newActive.copyWith(isDefault: true)); // update storage
      return; // addOrUpdate handles state
    }
    state = state.copyWith(presets: newPresets, activePreset: newActive);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return CompilerNotifier(hiveService);
});

// Execution State
class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String error;
  final String time;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.time = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? error,
    String? time,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      time: time ?? this.time,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setRunning(bool running) {
    state = state.copyWith(isRunning: running);
  }

  void setResult({String stdout = '', String stderr = '', String error = '', String time = '', String memory = ''}) {
    state = state.copyWith(
      isRunning: false,
      stdout: stdout,
      stderr: stderr,
      error: error,
      time: time,
      memory: memory,
    );
  }

  void clear() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

final stdinProvider = StateProvider<String>((ref) => '');
