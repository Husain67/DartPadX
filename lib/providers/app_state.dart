import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/code_file.dart';
import '../models/compiler_preset.dart';

const String _activeFileIdKey = 'activeFileId';
const String _useDefaultCompilerKey = 'useDefaultCompiler';
const String _activePresetIdKey = 'activePresetId';

class EditorState {
  final List<CodeFile> files;
  final String? activeFileId;
  final bool isSaving;

  EditorState({
    required this.files,
    this.activeFileId,
    this.isSaving = false,
  });

  EditorState copyWith({
    List<CodeFile>? files,
    String? activeFileId,
    bool? isSaving,
  }) {
    return EditorState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  CodeFile? get activeFile {
    if (activeFileId == null || files.isEmpty) return null;
    try {
      return files.firstWhere((f) => f.id == activeFileId);
    } catch (_) {
      return files.first;
    }
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  final Box<CodeFile> _box;
  final SharedPreferences _prefs;

  EditorNotifier(this._box, this._prefs) : super(EditorState(files: _box.values.toList())) {
    _init();
  }

  void _init() {
    final activeId = _prefs.getString(_activeFileIdKey);
    if (state.files.isEmpty) {
      _createNewFile(name: 'main.dart', content: 'void main() {\n  print("Hello from DartMini!");\n}\n');
    } else {
      if (activeId != null && state.files.any((f) => f.id == activeId)) {
        state = state.copyWith(activeFileId: activeId);
      } else {
        state = state.copyWith(activeFileId: state.files.first.id);
        _prefs.setString(_activeFileIdKey, state.files.first.id);
      }
    }
  }

  void setActiveFile(String id) {
    if (state.files.any((f) => f.id == id)) {
      state = state.copyWith(activeFileId: id);
      _prefs.setString(_activeFileIdKey, id);
    }
  }

  void updateContent(String id, String newContent) {
    final index = state.files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final updatedFile = state.files[index].copyWith(
        content: newContent,
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );
      _box.put(updatedFile.id, updatedFile);

      final updatedList = List<CodeFile>.from(state.files);
      updatedList[index] = updatedFile;
      state = state.copyWith(files: updatedList);
    }
  }

  void renameFile(String id, String newName) {
     final index = state.files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final updatedFile = state.files[index].copyWith(
        name: newName,
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );
      _box.put(updatedFile.id, updatedFile);

      final updatedList = List<CodeFile>.from(state.files);
      updatedList[index] = updatedFile;
      state = state.copyWith(files: updatedList);
    }
  }

  void _createNewFile({String? name, String? content}) {
    final newFile = CodeFile(
      id: const Uuid().v4(),
      name: name ?? 'untitled.dart',
      content: content ?? '',
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
    _box.put(newFile.id, newFile);
    final newList = [...state.files, newFile];
    state = state.copyWith(files: newList, activeFileId: newFile.id);
    _prefs.setString(_activeFileIdKey, newFile.id);
  }

  void createFile([String? name]) {
     _createNewFile(name: name, content: 'void main() {\n  \n}\n');
  }

  void importFile(String name, String content) {
    _createNewFile(name: name, content: content);
  }

  void deleteFile(String id) {
    if (state.files.length == 1) {
      _box.delete(id);
      state = state.copyWith(files: []);
      _createNewFile();
    } else {
      _box.delete(id);
      final newList = state.files.where((f) => f.id != id).toList();
      final newActiveId = id == state.activeFileId ? newList.first.id : state.activeFileId;
      state = state.copyWith(files: newList, activeFileId: newActiveId);
      if (newActiveId != null) {
          _prefs.setString(_activeFileIdKey, newActiveId);
      }
    }
  }

  // Expose current state for reads outside of build
  EditorState get currentState => state;
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());
final fileBoxProvider = Provider<Box<CodeFile>>((ref) => throw UnimplementedError());
final presetBoxProvider = Provider<Box<CompilerPreset>>((ref) => throw UnimplementedError());

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier(ref.watch(fileBoxProvider), ref.watch(sharedPrefsProvider));
});


class CompilerState {
  final List<CompilerPreset> presets;
  final bool useDefaultCompiler;
  final String? activePresetId;

  CompilerState({
    required this.presets,
    required this.useDefaultCompiler,
    this.activePresetId,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    bool? useDefaultCompiler,
    String? activePresetId,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _box;
  final SharedPreferences _prefs;

  CompilerNotifier(this._box, this._prefs) : super(CompilerState(
    presets: _box.values.toList(),
    useDefaultCompiler: _prefs.getBool(_useDefaultCompilerKey) ?? true,
    activePresetId: _prefs.getString(_activePresetIdKey),
  )) {
    _initPresets();
  }

  void _initPresets() {
    if (state.presets.isEmpty) {
        _loadDefaultPresets();
    }
  }

  void _loadDefaultPresets() {
     final defaults = [
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'OneCompiler',
          endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          method: 'POST',
          authType: 'API-Key Header',
          authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
          headers: {
            'X-RapidAPI-Key': 'YOUR_RAPID_API_KEY', // Typically OneCompiler uses a rapid api key, or direct. The user provided key looks direct.
            'Content-Type': 'application/json'
          },
          queryParams: {},
          bodyTemplate: '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          errorPath: 'exception',
          timePath: 'executionTime',
          memoryPath: '',
        ),
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'JDoodle',
          endpoint: 'https://api.jdoodle.com/v1/execute',
          method: 'POST',
          authType: 'None',
          authValue: '',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          bodyTemplate: '{\n  "clientId": "YOUR_CLIENT_ID",\n  "clientSecret": "YOUR_CLIENT_SECRET",\n  "script": "{code}",\n  "stdin": "{stdin}",\n  "language": "dart",\n  "versionIndex": "0"\n}',
          stdoutPath: 'output',
          stderrPath: '',
          errorPath: 'error',
          timePath: 'cpuTime',
          memoryPath: 'memory',
        ),
         CompilerPreset(
          id: const Uuid().v4(),
          name: 'Piston',
          endpoint: 'https://emacs.piston.rs/api/v2/execute',
          method: 'POST',
          authType: 'None',
          authValue: '',
          headers: {'Content-Type': 'application/json'},
          queryParams: {},
          bodyTemplate: '{\n  "language": "dart",\n  "version": "*",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}',
          stdoutPath: 'run.stdout',
          stderrPath: 'run.stderr',
          errorPath: 'message',
          timePath: '',
          memoryPath: '',
        ),

        CompilerPreset(
          id: const Uuid().v4(),
          name: 'Replit',
          endpoint: '',
          method: 'POST',
          authType: 'None',
          authValue: '',
          headers: {},
          queryParams: {},
          bodyTemplate: '{}',
          stdoutPath: '',
          stderrPath: '',
          errorPath: '',
          timePath: '',
          memoryPath: '',
        ),
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'CodeX',
          endpoint: '',
          method: 'POST',
          authType: 'None',
          authValue: '',
          headers: {},
          queryParams: {},
          bodyTemplate: '{}',
          stdoutPath: '',
          stderrPath: '',
          errorPath: '',
          timePath: '',
          memoryPath: '',
        ),
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'HackerEarth',
          endpoint: '',
          method: 'POST',
          authType: 'None',
          authValue: '',
          headers: {},
          queryParams: {},
          bodyTemplate: '{}',
          stdoutPath: '',
          stderrPath: '',
          errorPath: '',
          timePath: '',
          memoryPath: '',
        ),
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'Blank',
          endpoint: '',
          method: 'POST',
          authType: 'None',
          authValue: '',
          headers: {},
          queryParams: {},
          bodyTemplate: '{}',
          stdoutPath: '',
          stderrPath: '',
          errorPath: '',
          timePath: '',
          memoryPath: '',
        ),
     ];

     for (var preset in defaults) {
         _box.put(preset.id, preset);
     }

     state = state.copyWith(presets: defaults);
     if (state.activePresetId == null && defaults.isNotEmpty) {
       setActivePreset(defaults.first.id);
     }
  }

  void setUseDefaultCompiler(bool val) {
    _prefs.setBool(_useDefaultCompilerKey, val);
    state = state.copyWith(useDefaultCompiler: val);
  }

  void setActivePreset(String id) {
    _prefs.setString(_activePresetIdKey, id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      final newList = List<CompilerPreset>.from(state.presets);
      newList[index] = preset;
      state = state.copyWith(presets: newList);
    }
  }

  void deletePreset(String id) {
    _box.delete(id);
    final newList = state.presets.where((p) => p.id != id).toList();

    String? newActiveId = state.activePresetId;
    if (state.activePresetId == id) {
      newActiveId = newList.isNotEmpty ? newList.first.id : null;
      if (newActiveId != null) {
          _prefs.setString(_activePresetIdKey, newActiveId);
      } else {
          _prefs.remove(_activePresetIdKey);
      }
    }

    state = state.copyWith(presets: newList, activePresetId: newActiveId);
  }

  CompilerState get currentState => state;
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier(ref.watch(presetBoxProvider), ref.watch(sharedPrefsProvider));
});


class ExecutionState {
  final bool isExecuting;
  final String stdout;
  final String stderr;
  final String error;
  final String executionTime;
  final String memory;

  ExecutionState({
    this.isExecuting = false,
    this.stdout = '',
    this.stderr = '',
    this.error = '',
    this.executionTime = '',
    this.memory = '',
  });

  ExecutionState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
  }) {
    return ExecutionState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
    );
  }
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  void setExecuting(bool val) => state = state.copyWith(isExecuting: val);

  void setResult({
    String stdout = '',
    String stderr = '',
    String error = '',
    String time = '',
    String memory = '',
  }) {
    state = state.copyWith(
      isExecuting: false,
      stdout: stdout,
      stderr: stderr,
      error: error,
      executionTime: time,
      memory: memory,
    );
  }

  void clear() {
    state = ExecutionState();
  }

  ExecutionState get currentState => state;
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});

final stdinProvider = StateProvider<String>((ref) => '');
