import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'package:uuid/uuid.dart';

// --- File State Management ---

class FileState {
  final List<CodeFile> files;
  final String? activeFileId;

  FileState({required this.files, this.activeFileId});

  CodeFile? get activeFile => files.where((f) => f.id == activeFileId).firstOrNull;

  FileState copyWith({List<CodeFile>? files, String? activeFileId}) {
    return FileState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
    );
  }
}

class FileNotifier extends StateNotifier<FileState> {
  final Box _box;
  Timer? _saveTimer;

  FileNotifier(this._box) : super(FileState(files: [], activeFileId: null)) {
    _loadFiles();
  }

  void _loadFiles() {
    final List<CodeFile> loadedFiles = [];
    for (var key in _box.keys) {
      if (key == 'activeFileId') continue;
      final data = _box.get(key);
      if (data is String) {
        try {
          final json = jsonDecode(data);
          loadedFiles.add(CodeFile.fromJson(json));
        } catch (e) {
          // ignore parsing error
        }
      }
    }

    if (loadedFiles.isEmpty) {
      final defaultFile = CodeFile(
        name: 'main.dart',
        content: "import 'dart:io';\n\nvoid main() {\n  print('Hello DartMini!');\n  String? input = stdin.readLineSync();\n  print('Input was: \$input');\n}\n",
      );
      loadedFiles.add(defaultFile);
      _saveFileInstantly(defaultFile);
    }

    final activeId = _box.get('activeFileId') as String?;
    final finalActiveId = (activeId != null && loadedFiles.any((f) => f.id == activeId))
        ? activeId
        : loadedFiles.first.id;

    state = FileState(files: loadedFiles, activeFileId: finalActiveId);
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
    _box.put('activeFileId', id);
  }

  void addFile(CodeFile file) {
    final newFiles = [...state.files, file];
    state = state.copyWith(files: newFiles, activeFileId: file.id);
    _saveFileInstantly(file);
    _box.put('activeFileId', file.id);
  }

  void updateActiveFileContent(String content) {
    if (state.activeFileId == null) return;

    final files = [...state.files];
    final index = files.indexWhere((f) => f.id == state.activeFileId);
    if (index >= 0) {
      files[index].content = content;
      state = state.copyWith(files: files);

      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), () {
        _saveFileInstantly(files[index]);
      });
    }
  }

  void renameActiveFile(String newName) {
    if (state.activeFileId == null) return;
    final files = [...state.files];
    final index = files.indexWhere((f) => f.id == state.activeFileId);
    if (index >= 0) {
      files[index].name = newName;
      state = state.copyWith(files: files);
      _saveFileInstantly(files[index]);
    }
  }

  void deleteActiveFile() {
    if (state.activeFileId == null) return;

    final idToDelete = state.activeFileId!;
    _box.delete(idToDelete);

    final files = state.files.where((f) => f.id != idToDelete).toList();
    if (files.isEmpty) {
      final newFile = CodeFile(name: 'untitled.dart', content: '');
      files.add(newFile);
      _saveFileInstantly(newFile);
    }

    final newActiveId = files.last.id;
    state = state.copyWith(files: files, activeFileId: newActiveId);
    _box.put('activeFileId', newActiveId);
  }

  void _saveFileInstantly(CodeFile file) {
    _box.put(file.id, jsonEncode(file.toJson()));
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}

// --- Settings State Management ---

class SettingsState {
  final bool useOneCompiler;
  final List<CompilerPreset> presets;
  final String? activePresetId;

  SettingsState({
    required this.useOneCompiler,
    required this.presets,
    this.activePresetId,
  });

  CompilerPreset? get activePreset => presets.where((p) => p.id == activePresetId).firstOrNull;

  SettingsState copyWith({
    bool? useOneCompiler,
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return SettingsState(
      useOneCompiler: useOneCompiler ?? this.useOneCompiler,
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(SettingsState(useOneCompiler: true, presets: [])) {
    _loadSettings();
  }

  void _loadSettings() {
    final useOneCompiler = _prefs.getBool('useOneCompiler') ?? true;
    final presetsJson = _prefs.getStringList('presets') ?? [];
    final activeId = _prefs.getString('activePresetId');

    List<CompilerPreset> loadedPresets = [];
    for (var str in presetsJson) {
      try {
        loadedPresets.add(CompilerPreset.fromJson(jsonDecode(str)));
      } catch (e) {
        // ignore
      }
    }

    if (loadedPresets.isEmpty) {
      loadedPresets = [
        CompilerPreset(
          name: 'Blank',
          endpoint: 'https://api.example.com/execute',
          method: 'POST',
          requestBodyTemplate: '{\n  "code": "{code}",\n  "stdin": "{stdin}"\n}',
          responseMapping: {'stdout': 'stdout', 'stderr': 'stderr', 'time': 'time'},
        ),
      ];
      _savePresetsList(loadedPresets);
    }

    state = SettingsState(
      useOneCompiler: useOneCompiler,
      presets: loadedPresets,
      activePresetId: activeId ?? loadedPresets.first.id,
    );
  }

  void setUseOneCompiler(bool value) {
    state = state.copyWith(useOneCompiler: value);
    _prefs.setBool('useOneCompiler', value);
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
    _prefs.setString('activePresetId', id);
  }

  void addPreset(CompilerPreset preset) {
    final newPresets = [...state.presets, preset];
    state = state.copyWith(presets: newPresets);
    _savePresetsList(newPresets);
  }

  void updatePreset(CompilerPreset preset) {
    final index = state.presets.indexWhere((p) => p.id == preset.id);
    if (index >= 0) {
      final newPresets = [...state.presets];
      newPresets[index] = preset;
      state = state.copyWith(presets: newPresets);
      _savePresetsList(newPresets);
    }
  }

  void duplicatePreset(CompilerPreset preset) {
    final newPreset = CompilerPreset(
      name: '${preset.name} (Copy)',
      endpoint: preset.endpoint,
      method: preset.method,
      authType: preset.authType,
      headers: Map.from(preset.headers),
      queryParams: Map.from(preset.queryParams),
      requestBodyTemplate: preset.requestBodyTemplate,
      responseMapping: Map.from(preset.responseMapping),
    );
    addPreset(newPreset);
  }

  void deletePreset(String id) {
    final newPresets = state.presets.where((p) => p.id != id).toList();
    String? newActiveId = state.activePresetId;
    if (newActiveId == id) {
      newActiveId = newPresets.isNotEmpty ? newPresets.first.id : null;
      if (newActiveId != null) {
          _prefs.setString('activePresetId', newActiveId);
      } else {
          _prefs.remove('activePresetId');
      }
    }
    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
    _savePresetsList(newPresets);
  }

  void importPresets(List<CompilerPreset> newPresets) {
    final allPresets = [...state.presets, ...newPresets];
    state = state.copyWith(presets: allPresets);
    _savePresetsList(allPresets);
  }

  String exportPresets() {
    return jsonEncode(state.presets.map((p) => p.toJson()).toList());
  }

  void _savePresetsList(List<CompilerPreset> list) {
    final strList = list.map((p) => jsonEncode(p.toJson())).toList();
    _prefs.setStringList('presets', strList);
  }
}

// --- Execution State Management ---

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
  ExecutionNotifier() : super(ExecutionState());

  void clear() {
    state = ExecutionState();
  }

  Future<void> executeCode({
    required String code,
    required bool useOneCompiler,
    CompilerPreset? customPreset,
  }) async {
    state = state.copyWith(isRunning: true, stdout: '', stderr: '', executionTime: '', memory: '');
    try {
      if (useOneCompiler) {
        await _runOneCompiler(code);
      } else if (customPreset != null) {
        await _runCustomPreset(code, customPreset);
      } else {
        state = state.copyWith(isRunning: false, stderr: 'No compiler preset selected.');
      }
    } catch (e) {
      state = state.copyWith(isRunning: false, stderr: 'Execution failed: $e');
    }
  }

  Future<void> _runOneCompiler(String code) async {
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final apiKey = const String.fromEnvironment('OC_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
        state = state.copyWith(isRunning: false, stderr: 'OC_KEY is missing. Pass via --dart-define=OC_KEY=...');
        return;
    }

    final response = await http.post(
      url,
      headers: {
        'content-type': 'application/json',
        'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
        'x-rapidapi-key': apiKey,
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
        stderr: data['stderr'] ?? ((data['exception'] != null) ? data['exception'] : ''),
        executionTime: data['executionTime']?.toString() ?? '',
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        stderr: 'OneCompiler API Error: ${response.statusCode}\n${response.body}',
      );
    }
  }

  Future<void> _runCustomPreset(String code, CompilerPreset preset) async {
    Uri url = Uri.parse(preset.endpoint);

    // Add query parameters
    if (preset.queryParams.isNotEmpty) {
      final queryParams = Map<String, String>.from(url.queryParameters);
      queryParams.addAll(preset.queryParams);
      url = url.replace(queryParameters: queryParams);
    }

    Map<String, String> headers = {...preset.headers};

    String body = preset.requestBodyTemplate;
    String escapedCode = jsonEncode(code);
    if (escapedCode.length >= 2) {
      escapedCode = escapedCode.substring(1, escapedCode.length - 1); // remove outer quotes
    }
    body = body.replaceAll('{code}', escapedCode);
    body = body.replaceAll('{stdin}', '');
    body = body.replaceAll('{language}', 'dart');

    http.Response response;

    if (preset.method.toUpperCase() == 'GET') {
      response = await http.get(url, headers: headers);
    } else if (preset.method.toUpperCase() == 'PUT') {
      response = await http.put(url, headers: headers, body: body);
    } else {
      response = await http.post(url, headers: headers, body: body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      String stdout = _resolvePath(data, preset.responseMapping['stdout']);
      String stderr = _resolvePath(data, preset.responseMapping['stderr']);
      String time = _resolvePath(data, preset.responseMapping['time']);

      state = state.copyWith(
        isRunning: false,
        stdout: stdout,
        stderr: stderr,
        executionTime: time,
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        stderr: 'API Error ${response.statusCode}: ${response.body}',
      );
    }
  }

  String _resolvePath(dynamic data, String? path) {
    if (path == null || path.isEmpty) return '';
    if (data is! Map) return '';

    final parts = path.split('.');
    dynamic current = data;
    for (var part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return '';
      }
    }
    return current?.toString() ?? '';
  }
}

// --- Provider Definitions ---

final fileBoxProvider = Provider<Box>((ref) => throw UnimplementedError());
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final box = ref.watch(fileBoxProvider);
  return FileNotifier(box);
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});
