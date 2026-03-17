import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'api_service.dart';

final uuid = Uuid();

// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

// Settings Provider
class SettingsState {
  final bool useDefaultOneCompiler;
  final String? activePresetId;
  final List<CompilerPreset> presets;

  SettingsState({
    required this.useDefaultOneCompiler,
    this.activePresetId,
    required this.presets,
  });

  SettingsState copyWith({
    bool? useDefaultOneCompiler,
    String? activePresetId,
    List<CompilerPreset>? presets,
  }) {
    return SettingsState(
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
      presets: presets ?? this.presets,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences prefs;
  late Box<CompilerPreset> _presetsBox;

  SettingsNotifier(this.prefs) : super(SettingsState(useDefaultOneCompiler: true, presets: [])) {
    _init();
  }

  void _init() {
    _presetsBox = Hive.box<CompilerPreset>('presets');
    final useDefault = prefs.getBool('useDefaultOneCompiler') ?? true;
    final activeId = prefs.getString('activePresetId');

    var presets = _presetsBox.values.toList();
    if (presets.isEmpty) {
      _loadDefaultPresets();
      presets = _presetsBox.values.toList();
    }

    state = SettingsState(
      useDefaultOneCompiler: useDefault,
      activePresetId: activeId,
      presets: presets,
    );
  }

  void _loadDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: uuid.v4(),
        name: 'OneCompiler',
        endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        httpMethod: 'POST',
        authType: 'API-Key Header',
        headers: {
          'Content-Type': 'application/json',
          'X-RapidAPI-Key': 'YOUR_RAPIDAPI_KEY',
          'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
        },
        queryParams: {},
        bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": {code}\n    }\n  ]\n}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": {code}\n    }\n  ],\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'message',
        executionTimePath: '',
        memoryPath: '',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        authType: 'None',
        headers: {'Content-Type': 'application/json'},
        queryParams: {},
        bodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": {code},\n  "language": "dart",\n  "versionIndex": "0",\n  "stdin": "{stdin}"\n}',
        stdoutPath: 'output',
        stderrPath: 'error',
        errorPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Blank',
        endpointUrl: 'https://',
        httpMethod: 'POST',
        authType: 'None',
        headers: {},
        queryParams: {},
        bodyTemplate: '{}',
        stdoutPath: '',
        stderrPath: '',
        errorPath: '',
        executionTimePath: '',
        memoryPath: '',
      )
    ];

    for (var preset in defaultPresets) {
      _presetsBox.put(preset.id, preset);
    }
  }

  void setUseDefaultOneCompiler(bool value) {
    prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: _presetsBox.values.toList());
  }

  void updatePreset(CompilerPreset preset) {
    preset.save();
    state = state.copyWith(presets: _presetsBox.values.toList());
  }

  void deletePreset(String id) {
    _presetsBox.delete(id);
    if (state.activePresetId == id) {
      prefs.remove('activePresetId');
      state = state.copyWith(activePresetId: null, presets: _presetsBox.values.toList());
    } else {
      state = state.copyWith(presets: _presetsBox.values.toList());
    }
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: uuid.v4(),
      name: '${preset.name} (Copy)',
    );
    addPreset(newPreset);
  }

  CompilerPreset? get activePreset {
    if (state.activePresetId == null) return null;
    return _presetsBox.get(state.activePresetId);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref.watch(sharedPreferencesProvider));
});

// File Provider
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
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<CodeFile> _filesBox;
  Timer? _debounceTimer;
  final SharedPreferences prefs;

  FileNotifier(this.prefs) : super(FileState(files: [])) {
    _init();
  }

  void _init() {
    _filesBox = Hive.box<CodeFile>('files');
    var files = _filesBox.values.toList();
    if (files.isEmpty) {
      final defaultFile = CodeFile(
        id: uuid.v4(),
        name: 'main.dart',
        content: '''void main() {
  print('Hello, DartMini IDE!');
}
''',
      );
      _filesBox.put(defaultFile.id, defaultFile);
      files = [defaultFile];
    }
    final activeId = prefs.getString('activeFileId') ?? files.first.id;
    state = FileState(files: files, activeFileId: activeId);
  }

  void addFile(String name, String content) {
    final file = CodeFile(id: uuid.v4(), name: name, content: content);
    _filesBox.put(file.id, file);
    setActiveFile(file.id);
    _refreshState();
  }

  void setActiveFile(String id) {
    prefs.setString('activeFileId', id);
    state = state.copyWith(activeFileId: id);
  }

  void updateContent(String id, String content) {
    final file = _filesBox.get(id);
    if (file != null) {
      file.content = content;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        file.save();
      });
      // Don't update state to avoid full rebuilds on every keystroke,
      // the editor handles its own state
    }
  }

  void forceSave(String id) {
    _debounceTimer?.cancel();
    _filesBox.get(id)?.save();
  }

  void deleteFile(String id) {
    _filesBox.delete(id);
    final remainingFiles = _filesBox.values.toList();

    if (remainingFiles.isEmpty) {
      addFile('untitled.dart', '');
    } else if (state.activeFileId == id) {
      setActiveFile(remainingFiles.first.id);
    }
    _refreshState();
  }

  void _refreshState() {
    state = state.copyWith(files: _filesBox.values.toList());
  }

  CodeFile? get activeFile => state.activeFileId != null ? _filesBox.get(state.activeFileId) : null;
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier(ref.watch(sharedPreferencesProvider));
});


// Execution Provider
class ExecutionState {
  final bool isRunning;
  final String stdout;
  final String stderr;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isRunning = false,
    this.stdout = '',
    this.stderr = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isRunning,
    String? stdout,
    String? stderr,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isRunning: isRunning ?? this.isRunning,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  final Ref ref;

  ExecutionNotifier(this.ref) : super(ExecutionState());

  Future<void> executeCode(String code, {String stdin = ''}) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');
    try {
      final settings = ref.read(settingsProvider);
      final apiService = ApiService();

      ExecutionResult result;
      if (settings.useDefaultOneCompiler) {
        result = await apiService.executeDefault(code, stdin);
      } else {
        final preset = ref.read(settingsProvider.notifier).activePreset;
        if (preset == null) {
          throw Exception('No custom preset selected.');
        }
        result = await apiService.executeCustom(preset, code, stdin);
      }

      state = state.copyWith(
        isRunning: false,
        stdout: result.stdout,
        stderr: result.stderr,
        executionTime: result.executionTime,
        memory: result.memory,
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        stderr: e.toString(),
      );
    }
  }

  void clear() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier(ref);
});
