import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import '../models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- File Provider ---
class FileState {
  final List<FileModel> files;
  final int activeIndex;

  FileState({required this.files, required this.activeIndex});

  FileState copyWith({List<FileModel>? files, int? activeIndex}) {
    return FileState(
      files: files ?? this.files,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }

  FileModel? get activeFile => files.isNotEmpty && activeIndex >= 0 && activeIndex < files.length ? files[activeIndex] : null;
}

class FileNotifier extends StateNotifier<FileState> {
  late Box<FileModel> box;

  FileNotifier() : super(FileState(files: [], activeIndex: 0)) {
    box = Hive.box<FileModel>('files');
    _loadFiles();
  }

  void _loadFiles() {
    final storedFiles = box.values.toList();
    if (storedFiles.isEmpty) {
      final defaultFile = FileModel(
        name: 'main.dart',
        content: "void main() {\n  print('Hello World');\n}",
      );
      box.add(defaultFile);
      state = FileState(files: [defaultFile], activeIndex: 0);
    } else {
      state = FileState(files: storedFiles, activeIndex: 0);
    }
  }

  void addFile(String name, String content) {
    final newFile = FileModel(name: name, content: content);
    box.add(newFile);
    final updatedFiles = [...state.files, newFile];
    state = state.copyWith(files: updatedFiles, activeIndex: updatedFiles.length - 1);
  }

  void removeActiveFile() {
    if (state.files.isEmpty) return;
    final indexToRemove = state.activeIndex;
    final keyToRemove = box.keyAt(indexToRemove);
    box.delete(keyToRemove);

    final newFiles = box.values.toList();
    if (newFiles.isEmpty) {
      addFile('untitled.dart', '');
    } else {
      final newIndex = indexToRemove >= newFiles.length ? newFiles.length - 1 : indexToRemove;
      state = state.copyWith(files: newFiles, activeIndex: newIndex);
    }
  }

  void setActiveIndex(int index) {
    if (index >= 0 && index < state.files.length) {
      state = state.copyWith(activeIndex: index);
    }
  }

  void updateActiveFileContent(String content) {
    if (state.files.isEmpty) return;
    final activeFile = state.files[state.activeIndex];
    activeFile.content = content;
    box.putAt(state.activeIndex, activeFile);
    // Don't update state here to avoid rebuild loop with editor, Hive is updated
  }
}

final filesProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  return FileNotifier();
});

// --- Compiler Settings Provider ---
class CompilerSettingsState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefaultOneCompiler;

  CompilerSettingsState({
    required this.presets,
    required this.activePresetId,
    required this.useDefaultOneCompiler,
  });

  CompilerSettingsState copyWith({
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? useDefaultOneCompiler,
  }) {
    return CompilerSettingsState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      useDefaultOneCompiler: useDefaultOneCompiler ?? this.useDefaultOneCompiler,
    );
  }

  CompilerPreset? get activePreset {
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }
}

class CompilerSettingsNotifier extends StateNotifier<CompilerSettingsState> {
  late Box<CompilerPreset> box;
  late SharedPreferences prefs;

  CompilerSettingsNotifier() : super(CompilerSettingsState(presets: [], activePresetId: '', useDefaultOneCompiler: true)) {
    _init();
  }

  Future<void> _init() async {
    box = Hive.box<CompilerPreset>('presets');
    prefs = await SharedPreferences.getInstance();

    if (box.isEmpty) {
      _loadDefaultPresets();
    }

    final storedPresets = box.values.toList();
    final activeId = prefs.getString('activePresetId') ?? (storedPresets.isNotEmpty ? storedPresets.first.id : '');
    final useDefault = prefs.getBool('useDefaultOneCompiler') ?? true;

    state = CompilerSettingsState(
      presets: storedPresets,
      activePresetId: activeId,
      useDefaultOneCompiler: useDefault,
    );
  }

  void _loadDefaultPresets() {
    const defaultKey = String.fromEnvironment('RAPIDAPI_KEY', defaultValue: '');

    final oneCompiler = CompilerPreset(
      id: 'oc_default',
      name: 'OneCompiler (Default)',
      url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
      method: 'POST',
      authType: 'API-Key Header',
      headers: {
        'x-rapidapi-key': defaultKey,
        'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
      },
      queryParams: {},
      bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'exception',
      executionTimePath: 'executionTime',
      memoryPath: '',
    );
    box.add(oneCompiler);
  }

  void toggleUseDefault(bool value) {
    prefs.setBool('useDefaultOneCompiler', value);
    state = state.copyWith(useDefaultOneCompiler: value);
  }

  void setActivePreset(String id) {
    prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void addPreset(CompilerPreset preset) {
    box.add(preset);
    state = state.copyWith(presets: box.values.toList());
  }

  void updatePreset(int index, CompilerPreset preset) {
    box.putAt(index, preset);
    state = state.copyWith(presets: box.values.toList());
  }

  void deletePreset(int index) {
    final presetId = box.getAt(index)?.id;
    box.deleteAt(index);
    final newPresets = box.values.toList();

    String newActiveId = state.activePresetId;
    if (presetId == state.activePresetId) {
       newActiveId = newPresets.isNotEmpty ? newPresets.first.id : '';
       prefs.setString('activePresetId', newActiveId);
    }

    state = state.copyWith(presets: newPresets, activePresetId: newActiveId);
  }

  Future<void> exportPresets() async {
    final presetsList = box.values.map((p) => p.toJson()).toList();
    final jsonStr = jsonEncode(presetsList);
    // Exporting via clipboard for simplicity in mobile environment without file system prompt
    Clipboard.setData(ClipboardData(text: jsonStr));
    Fluttertoast.showToast(msg: 'Presets exported to clipboard as JSON');
  }

  Future<void> importPresets() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data.text!);
        for (var item in decoded) {
          final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
          // Check if exists to avoid duplicates
          if (!box.values.any((p) => p.id == preset.id)) {
            box.add(preset);
          }
        }
        state = state.copyWith(presets: box.values.toList());
        Fluttertoast.showToast(msg: 'Presets imported successfully');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Invalid JSON format for presets');
      }
    } else {
        Fluttertoast.showToast(msg: 'Clipboard is empty');
    }
  }
}

final compilerSettingsProvider = StateNotifierProvider<CompilerSettingsNotifier, CompilerSettingsState>((ref) {
  return CompilerSettingsNotifier();
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
}

class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier() : super(ExecutionState());

  Future<void> executeCode(String code, CompilerSettingsState settings, {String stdin = ''}) async {
    state = ExecutionState(isExecuting: true);

    try {
      if (settings.useDefaultOneCompiler || settings.activePreset == null) {
         await _runOneCompiler(code, stdin);
      } else {
         await _runCustomPreset(code, settings.activePreset!, stdin);
      }
    } catch (e) {
      state = ExecutionState(isExecuting: false, stderr: e.toString());
    }
  }

  Future<void> _runOneCompiler(String code, String stdin) async {
    const defaultKey = String.fromEnvironment('RAPIDAPI_KEY', defaultValue: '');
    final url = Uri.parse('https://onecompiler-apis.p.rapidapi.com/api/v1/run');
    final response = await http.post(
      url,
      headers: {
        'x-rapidapi-key': defaultKey,
        'x-rapidapi-host': 'onecompiler-apis.p.rapidapi.com',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "language": "dart",
        "stdin": stdin,
        "files": [{"name": "main.dart", "content": code}]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      state = ExecutionState(
        isExecuting: false,
        stdout: data['stdout'] ?? '',
        stderr: data['stderr'] ?? data['exception'] ?? '',
        executionTime: data['executionTime']?.toString() ?? '',
      );
    } else {
      state = ExecutionState(isExecuting: false, stderr: 'Error: ${response.statusCode}\n${response.body}');
    }
  }

  Future<void> _runCustomPreset(String code, CompilerPreset preset, String stdin) async {
    String body = preset.bodyTemplate
        .replaceAll('{code}', jsonEncode(code).substring(1, jsonEncode(code).length - 1))
        .replaceAll('{stdin}', jsonEncode(stdin).substring(1, jsonEncode(stdin).length - 1))
        .replaceAll('{language}', 'dart');

    Uri url = Uri.parse(preset.url);
    if (preset.queryParams.isNotEmpty) {
       url = url.replace(queryParameters: preset.queryParams);
    }

    http.Response response;
    if (preset.method.toUpperCase() == 'GET') {
      response = await http.get(url, headers: preset.headers);
    } else {
      response = await http.post(url, headers: preset.headers, body: body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
       try {
         final data = jsonDecode(response.body);

         String extractPath(String path) {
           if (path.isEmpty) return '';
           final keys = path.split('.');
           dynamic current = data;
           for (var key in keys) {
             if (current is Map && current.containsKey(key)) {
               current = current[key];
             } else {
               return '';
             }
           }
           return current?.toString() ?? '';
         }

         state = ExecutionState(
           isExecuting: false,
           stdout: extractPath(preset.stdoutPath),
           stderr: extractPath(preset.stderrPath) + (extractPath(preset.errorPath).isNotEmpty ? '\n${extractPath(preset.errorPath)}' : ''),
           executionTime: extractPath(preset.executionTimePath),
           memory: extractPath(preset.memoryPath),
         );
       } catch (e) {
         state = ExecutionState(isExecuting: false, stdout: response.body);
       }
    } else {
      state = ExecutionState(isExecuting: false, stderr: 'Error ${response.statusCode}: ${response.body}');
    }
  }

  void clearOutput() {
    state = ExecutionState();
  }
}

final executionProvider = StateNotifierProvider<ExecutionNotifier, ExecutionState>((ref) {
  return ExecutionNotifier();
});
