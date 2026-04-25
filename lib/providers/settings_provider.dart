import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';

class SettingsState {
  final bool useDefaultCompiler;
  final String defaultApiKey;
  final List<CompilerPreset> presets;
  final String? activePresetId;

  SettingsState({
    this.useDefaultCompiler = true,
    this.defaultApiKey = 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac',
    this.presets = const [],
    this.activePresetId,
  });

  SettingsState copyWith({
    bool? useDefaultCompiler,
    String? defaultApiKey,
    List<CompilerPreset>? presets,
    String? activePresetId,
  }) {
    return SettingsState(
      useDefaultCompiler: useDefaultCompiler ?? this.useDefaultCompiler,
      defaultApiKey: defaultApiKey ?? this.defaultApiKey,
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final useDef = prefs.getBool('useDefaultCompiler') ?? true;
    final activeId = prefs.getString('activePresetId');

    final box = HiveService.presetsBox;
    if (box.isEmpty) {
      _loadDefaultPresets();
    }

    state = state.copyWith(
      useDefaultCompiler: useDef,
      presets: box.values.toList(),
      activePresetId: activeId,
    );
  }

  void _loadDefaultPresets() {
    final box = HiveService.presetsBox;
    final defaults = [
      CompilerPreset(id: 'blank', name: 'Blank Preset', url: 'https://api.example.com/execute', bodyTemplate: '{"code": "{code}"}'),
      CompilerPreset(id: 'onecompiler', name: 'OneCompiler', url: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run', method: 'POST', authType: 'API-Key Header', authValue: 'oc_44e2kd6de_44e2kd6dz_5b0328c6ef211f3158c3e0679cd48b5d49e28e0d1eb6daac', headers: [MapEntry('X-RapidAPI-Host', 'onecompiler-apis.p.rapidapi.com')], bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}', stdoutPath: 'stdout', stderrPath: 'stderr', errorPath: 'exception', executionTimePath: 'executionTime', memoryPath: ''),
      CompilerPreset(id: 'jdoodle', name: 'JDoodle', url: 'https://api.jdoodle.com/v1/execute', method: 'POST', bodyTemplate: '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "language": "dart", "versionIndex": "0"}', stdoutPath: 'output', stderrPath: '', errorPath: 'error', executionTimePath: 'cpuTime', memoryPath: 'memory'),
      CompilerPreset(id: 'piston', name: 'Piston', url: 'https://emkc.org/api/v2/piston/execute', method: 'POST', bodyTemplate: '{"language": "dart", "version": "3.3.0", "files": [{"content": "{code}"}]}', stdoutPath: 'run.stdout', stderrPath: 'run.stderr', errorPath: '', executionTimePath: '', memoryPath: ''),
      CompilerPreset(id: 'replit', name: 'Replit', url: 'https://replit.com/api/v1/repls', method: 'POST', bodyTemplate: '{"language": "dart"}'),
      CompilerPreset(id: 'codex', name: 'CodeX', url: 'https://api.codex.jaagrav.in', method: 'POST', bodyTemplate: '{"code": "{code}", "language": "dart"}', stdoutPath: 'output', stderrPath: 'error', errorPath: ''),
      CompilerPreset(id: 'hackerearth', name: 'HackerEarth', url: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/', method: 'POST', bodyTemplate: '{"lang": "DART", "source": "{code}"}'),
    ];
    for (var p in defaults) {
      box.put(p.id, p);
    }
  }

  void toggleUseDefault(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useDefaultCompiler', value);
    state = state.copyWith(useDefaultCompiler: value);
  }

  void setActivePreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    state = state.copyWith(presets: HiveService.presetsBox.values.toList());
  }

  void deletePreset(String id) {
    HiveService.presetsBox.delete(id);
    state = state.copyWith(presets: HiveService.presetsBox.values.toList());
    if (state.activePresetId == id) {
      setActivePreset('');
    }
  }

  CompilerPreset? get activePreset {
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return state.presets.isNotEmpty ? state.presets.first : null;
    }
  }

  Future<void> exportPresets() async {
    try {
      final presets = HiveService.presetsBox.values.map((e) => e.toJson()).toList();
      final jsonStr = jsonEncode(presets);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/dartmini_presets.json';
      final fileIo = File(path);
      await fileIo.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(path)], text: 'DartMini API Presets');
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to export presets");
    }
  }

  Future<void> importPresets() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        final List<dynamic> data = jsonDecode(content);
        for (var item in data) {
          final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
          savePreset(preset);
        }
        Fluttertoast.showToast(msg: "Presets imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to import presets");
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) => SettingsNotifier());
