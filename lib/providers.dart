import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

// --- File Provider ---
class FileState {
  final List<FileModel> files;
  final String activeFileId;

  FileState({required this.files, required this.activeFileId});

  FileState copyWith({List<FileModel>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }

  FileModel? get activeFile {
    if (files.isEmpty) return null;
    return files.firstWhere((f) => f.id == activeFileId, orElse: () => files.first);
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box<FileModel> box;
  Timer? _saveTimer;

  FileNotifier(this.box) : super(FileState(files: [], activeFileId: '')) {
    _loadFiles();
  }

  void _loadFiles() {
    final files = box.values.toList();
    if (files.isEmpty) {
      final defaultFile = FileModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'main.dart',
        content: '''
import 'dart:io';

void main() {
  print('Welcome to DartMini IDE!');
  print('Enter your name:');
  String? name = stdin.readLineSync();
  print('Hello, \$name!');
}
''',
      );
      box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }
    state = FileState(files: files, activeFileId: files.first.id);
  }

  void addFile(String name, String content) {
    final newFile = FileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      content: content,
    );
    box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void updateActiveFileContent(String content) {
    final activeFile = state.activeFile;
    if (activeFile != null) {
      final updatedFile = activeFile.copyWith(content: content);
      final index = state.files.indexWhere((f) => f.id == activeFile.id);
      if (index != -1) {
        final newFiles = List<FileModel>.from(state.files);
        newFiles[index] = updatedFile;
        state = state.copyWith(files: newFiles);

        _saveTimer?.cancel();
        _saveTimer = Timer(const Duration(seconds: 2), () {
          box.put(updatedFile.id, updatedFile);
        });
      }
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void deleteFile(String id) {
    box.delete(id);
    final remainingFiles = state.files.where((f) => f.id != id).toList();
    if (remainingFiles.isEmpty) {
      addFile('untitled.dart', '');
    } else {
      state = state.copyWith(
        files: remainingFiles,
        activeFileId: remainingFiles.first.id,
      );
    }
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = Hive.box<FileModel>('filesBox');
  return FileNotifier(box);
});


// --- Compiler Provider ---
class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    required this.activePresetId,
    required this.useDefaultOneCompiler,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }

  CompilerPreset? get activePreset {
    if (presets.isEmpty) return null;
    return presets.firstWhere((p) => p.id == activePresetId, orElse: () => presets.first);
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> box;
  final Box settingsBox;

  CompilerNotifier(this.box, this.settingsBox) : super(CompilerState(presets: [], activePresetId: '', useDefaultOneCompiler: true)) {
    _loadPresets();
  }

  void _loadPresets() {
    final presets = box.values.toList();
    if (presets.isEmpty) {
      _initDefaultPresets();
      presets.addAll(box.values);
    }

    final activeId = settingsBox.get('activePresetId', defaultValue: presets.first.id);
    final useDefault = settingsBox.get('useDefaultOneCompiler', defaultValue: true);

    state = CompilerState(
      presets: presets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void _initDefaultPresets() {
    final oneCompiler = CompilerPreset(
      id: 'onecompiler',
      name: 'OneCompiler',
      endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      method: 'POST',
      authType: 'API-Key Header',
      headers: {
        'X-RapidAPI-Key': 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
        'Content-Type': 'application/json',
      },
      queryParams: {},
      requestBodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
    );
    box.put(oneCompiler.id, oneCompiler);

    final blank = CompilerPreset(
      id: 'blank',
      name: 'Blank Preset',
      endpointUrl: '',
      method: 'POST',
      authType: 'None',
      headers: {},
      queryParams: {},
      requestBodyTemplate: '{}',
      stdoutPath: '',
      stderrPath: '',
      errorPath: '',
      executionTimePath: '',
      memoryPath: '',
    );
    box.put(blank.id, blank);
  }

  void addPreset(CompilerPreset preset) {
    box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    box.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final newPresets = List<CompilerPreset>.from(state.presets);
      newPresets[index] = preset;
      state = state.copyWith(presets: newPresets);
    }
  }

  void deletePreset(String id) {
    box.delete(id);
    state = state.copyWith(presets: state.presets.where((p) => p.id != id).toList());
  }

  void setActivePreset(String id) {
    settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void toggleUseDefaultOneCompiler(bool value) {
    settingsBox.put('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = Hive.box<CompilerPreset>('compilerBox');
  final settingsBox = Hive.box('settingsBox');
  return CompilerNotifier(box, settingsBox);
});


// --- Execution Provider ---
class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void clearOutput() {
    state = ExecutionState();
  }

  Future<void> executeCode(String code, String stdin, CompilerState compilerState) async {
    state = state.copyWith(isExecuting: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      final preset = compilerState.useDefaultOneCompiler
          ? compilerState.presets.firstWhere((p) => p.id == 'onecompiler')
          : compilerState.activePreset;

      if (preset == null) {
        throw Exception('No active compiler preset found.');
      }

      String body = preset.requestBodyTemplate;
      String encodedCode = jsonEncode(code);
      encodedCode = encodedCode.substring(1, encodedCode.length - 1);
      String encodedStdin = jsonEncode(stdin);
      encodedStdin = encodedStdin.substring(1, encodedStdin.length - 1);

      body = body.replaceAll('{code}', encodedCode);
      body = body.replaceAll('{stdin}', encodedStdin);

      final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams.isNotEmpty ? preset.queryParams : null);

      http.Response response;
      if (preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: preset.headers, body: body);
      } else {
        response = await http.get(uri, headers: preset.headers);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        String stdout = _extractValue(data, preset.stdoutPath) ?? '';
        String stderr = _extractValue(data, preset.stderrPath) ?? '';
        String error = _extractValue(data, preset.errorPath) ?? '';
        String time = _extractValue(data, preset.executionTimePath) ?? '';
        String mem = _extractValue(data, preset.memoryPath) ?? '';

        if (error.isNotEmpty && stderr.isEmpty) {
          stderr = error;
        }

        state = state.copyWith(
          isExecuting: false,
          stdout: stdout,
          stderr: stderr,
          executionTime: time,
          memory: mem,
        );
      } else {
        state = state.copyWith(
          isExecuting: false,
          stderr: 'HTTP Error ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        stderr: 'Execution Exception: $e',
      );
    }
  }

  String? _extractValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic current = data;
    for (var key in keys) {
      if (current is Map<String, dynamic> && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current?.toString();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

final stdinProvider = StateProvider<String>((ref) => '');
