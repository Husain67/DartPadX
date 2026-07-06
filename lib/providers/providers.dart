import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/models.dart';

// --- File Notifier ---
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
}

class FileNotifier extends StateNotifier<FileState> {
  FileNotifier() : super(FileState(files: [])) {
    _loadFiles();
  }

  Box<FileModel> get _box => Hive.box<FileModel>('files');
  Timer? _saveTimer;
  final _uuid = const Uuid();

  void _loadFiles() {
    final files = _box.values.toList();
    if (files.isEmpty) {
      final defaultFile = FileModel(
        id: _uuid.v4(),
        name: 'main.dart',
        content: "void main() {\n  print('Hello, DartMini IDE!');\n}\n",
      );
      _box.put(defaultFile.id, defaultFile);
      files.add(defaultFile);
    }
    state = FileState(files: files, activeFileId: files.first.id);
  }

  void addFile(String name, [String content = '']) {
    final newFile = FileModel(id: _uuid.v4(), name: name, content: content);
    _box.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final updatedFiles = state.files.map((f) {
      if (f.id == state.activeFileId) {
        return FileModel(
          id: f.id,
          name: f.name,
          content: content,
          lastModified: DateTime.now(),
        );
      }
      return f;
    }).toList();

    state = state.copyWith(files: updatedFiles);

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      final file = updatedFiles.firstWhere((f) => f.id == state.activeFileId);
      _box.put(file.id, file);
    });
  }

  void deleteFile(String id) {
    _box.delete(id);
    final updatedFiles = state.files.where((f) => f.id != id).toList();

    if (updatedFiles.isEmpty) {
      final defaultFile = FileModel(id: _uuid.v4(), name: 'untitled.dart', content: '');
      _box.put(defaultFile.id, defaultFile);
      updatedFiles.add(defaultFile);
    }

    final newActiveId = (state.activeFileId == id) ? updatedFiles.last.id : state.activeFileId;
    state = state.copyWith(files: updatedFiles, activeFileId: newActiveId);
  }
}

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) => FileNotifier());

// --- Compiler Notifier ---
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

class CompilerNotifier extends StateNotifier<ExecutionState> {
  CompilerNotifier(this.ref) : super(ExecutionState());
  final Ref ref;

  Future<void> runCode(String code) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');

    try {
      final preset = ref.read(settingsProvider).activePreset;

      if (preset == null || preset.isDefault) {
        await _runOneCompiler(code);
      } else {
        await _runCustomCompiler(code, preset);
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: 'Execution Error: $e');
    }
  }

  Future<void> _runOneCompiler(String code) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-RapidAPI-Key': const String.fromEnvironment('OC_API_KEY', defaultValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac'),
        'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com'
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": "",
        "files": [
          {"name": "main.dart", "content": code}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = state.copyWith(
        isRunning: false,
        stdout: data['stdout'] ?? '',
        stderr: data['stderr'] ?? data['exception'] ?? '',
        executionTime: '${data['executionTime'] ?? 0} ms',
      );
    } else {
      state = state.copyWith(isRunning: false, stderr: 'API Error: ${response.statusCode}\n${response.body}');
    }
  }

  Future<void> _runCustomCompiler(String code, CompilerPreset preset) async {
    final uri = Uri.parse(preset.endpointUrl).replace(queryParameters: preset.queryParams);

    Map<String, String> headers = Map.from(preset.headers);
    if (preset.authType == 'API-Key Header' && preset.authValue.isNotEmpty) {
       // Assuming standard authorization header for simplicity, user can configure custom headers
       headers['Authorization'] = preset.authValue;
    } else if (preset.authType == 'Bearer Token' && preset.authValue.isNotEmpty) {
       headers['Authorization'] = 'Bearer ${preset.authValue}';
    } else if (preset.authType == 'Basic Auth' && preset.authValue.isNotEmpty) {
       final encoded = base64Encode(utf8.encode(preset.authValue));
       headers['Authorization'] = 'Basic $encoded';
    }

    String bodyStr = preset.requestBodyTemplate;
    bodyStr = bodyStr.replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1)); // Escape properly
    bodyStr = bodyStr.replaceAll('{language}', 'dart');
    bodyStr = bodyStr.replaceAll('{stdin}', '');

    http.Response response;
    if (preset.httpMethod.toUpperCase() == 'POST') {
      response = await http.post(uri, headers: headers, body: bodyStr);
    } else if (preset.httpMethod.toUpperCase() == 'PUT') {
      response = await http.put(uri, headers: headers, body: bodyStr);
    } else {
      response = await http.get(uri, headers: headers);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      dynamic getValue(Map map, String path) {
        if (path.isEmpty) return null;
        List<String> keys = path.split('.');
        dynamic current = map;
        for (String key in keys) {
          if (current is Map && current.containsKey(key)) {
            current = current[key];
          } else {
            return null;
          }
        }
        return current;
      }

      state = state.copyWith(
        isRunning: false,
        stdout: getValue(data, preset.stdoutPath)?.toString() ?? '',
        stderr: getValue(data, preset.stderrPath)?.toString() ?? getValue(data, preset.errorPath)?.toString() ?? '',
        executionTime: getValue(data, preset.executionTimePath)?.toString() ?? '',
        memory: getValue(data, preset.memoryPath)?.toString() ?? '',
      );
    } else {
      state = state.copyWith(isRunning: false, stderr: 'API Error: ${response.statusCode}\n${response.body}');
    }
  }

  void clearOutput() {
    state = ExecutionState();
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, ExecutionState>((ref) => CompilerNotifier(ref));

// --- Settings Notifier ---
class SettingsState {
  final List<CompilerPreset> presets;
  final String? activePresetId;

  SettingsState({required this.presets, this.activePresetId});

  CompilerPreset? get activePreset {
     if (activePresetId == null) return null;
     try {
       return presets.firstWhere((p) => p.id == activePresetId);
     } catch (e) {
       return null;
     }
  }

  SettingsState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return SettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(presets: [])) {
    _loadPresets();
  }

  Box<CompilerPreset> get _box => Hive.box<CompilerPreset>('compiler_presets');
  final _uuid = const Uuid();

  void _loadPresets() {
    final presets = _box.values.toList();
    if (presets.isEmpty) {
      final defaultPreset = CompilerPreset(
        id: 'default_onecompiler',
        name: 'OneCompiler (Default)',
        endpointUrl: '',
        isDefault: true,
      );
      _box.put(defaultPreset.id, defaultPreset);
      presets.add(defaultPreset);
    }

    String? activeId;
    try {
      activeId = presets.firstWhere((p) => p.isDefault).id;
    } catch (_) {
      if (presets.isNotEmpty) activeId = presets.first.id;
    }

    state = SettingsState(presets: presets, activePresetId: activeId);
  }

  void addPreset(CompilerPreset preset) {
    if (preset.id.isEmpty) preset.id = _uuid.v4();
    _box.put(preset.id, preset);
    state = state.copyWith(presets: [...state.presets, preset]);
  }

  void updatePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final updated = state.presets.map((p) => p.id == preset.id ? preset : p).toList();
    state = state.copyWith(presets: updated);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final updated = state.presets.where((p) => p.id != id).toList();
    String? activeId = state.activePresetId;
    if (activeId == id) {
      activeId = updated.isNotEmpty ? updated.first.id : null;
    }
    state = state.copyWith(presets: updated, activePresetId: activeId);
  }

  void setActivePreset(String id) {
     final updated = state.presets.map((p) => p.copyWith(isDefault: p.id == id)).toList();
     for (var p in updated) {
       _box.put(p.id, p);
     }
     state = state.copyWith(presets: updated, activePresetId: id);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());
