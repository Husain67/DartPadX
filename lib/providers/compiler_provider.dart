import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import 'dart:convert';

class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;

  CompilerState({required this.presets, required this.activePresetId});

  CompilerState copyWith({List<CompilerPreset>? presets, String? activePresetId}) {
    return CompilerState(
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  final Box<CompilerPreset> _box;

  CompilerNotifier(this._box) : super(CompilerState(presets: [], activePresetId: '')) {
    _loadPresets();
  }

  void _loadPresets() {
    var presets = _box.values.toList();
    if (presets.isEmpty) {
      presets = _getDefaultPresets();
      for (var p in presets) {
        _box.put(p.id, p);
      }
    }
    state = CompilerState(presets: presets, activePresetId: presets.first.id);
  }

  CompilerPreset? get activePreset {
    if (state.activePresetId.isEmpty) return null;
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return null;
    }
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    _box.put(preset.id, preset);
    final updatedPresets = _box.values.toList();
    state = state.copyWith(presets: updatedPresets);
  }

  void deletePreset(String id) {
    _box.delete(id);
    final updatedPresets = _box.values.toList();
    String newActiveId = state.activePresetId == id
        ? (updatedPresets.isNotEmpty ? updatedPresets.first.id : '')
        : state.activePresetId;
    state = state.copyWith(presets: updatedPresets, activePresetId: newActiveId);
  }

  void duplicatePreset(String id) {
    final preset = state.presets.firstWhere((p) => p.id == id);
    final newPreset = preset.copyWith(
      id: const Uuid().v4(),
      name: '${preset.name} (Copy)',
      isDefaultSystem: false,
    );
    savePreset(newPreset);
  }

  List<CompilerPreset> _getDefaultPresets() {
    return [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'OneCompiler',
        endpoint: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'X-RapidAPI-Key',
        authValue: String.fromCharCodes(base64Decode('b2NfNDRlMmtkNmRlXzQ0ZTJrZDZkel81YjAzMjhjNmVmMjExZjMxNThjM2UwNjc5Y2Q0OGI1ZDQ5ZTI4ZTBkMWViNmRhYWM=')),
        headers: [
          const MapEntry('X-RapidAPI-Host', 'onecompiler-apis.p.rapidapi.com'),
          const MapEntry('Content-Type', 'application/json'),
        ],
        bodyTemplate: '{"language":"dart","stdin":"{stdin}","files":[{"name":"main.dart","content":"{code}"}]}',
        stdoutPath: 'stdout',
        stderrPath: 'stderr',
        errorPath: 'exception',
        executionTimePath: 'executionTime',
        memoryPath: '',
        isDefaultSystem: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        authType: 'None',
        headers: [const MapEntry('Content-Type', 'application/json')],
        bodyTemplate: '{"clientId":"YOUR_CLIENT_ID","clientSecret":"YOUR_CLIENT_SECRET","script":"{code}","stdin":"{stdin}","language":"dart","versionIndex":"4"}',
        stdoutPath: 'output',
        stderrPath: 'error',
        executionTimePath: 'cpuTime',
        memoryPath: 'memory',
        isDefaultSystem: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpoint: 'https://emkc.org/api/v2/piston/execute',
        method: 'POST',
        authType: 'None',
        headers: [const MapEntry('Content-Type', 'application/json')],
        bodyTemplate: '{"language":"dart","version":"*","files":[{"content":"{code}"}],"stdin":"{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
        errorPath: 'compile.stderr',
        isDefaultSystem: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Replit (GraphQL)',
        endpoint: 'https://replit.com/graphql',
        method: 'POST',
        authType: 'None',
        headers: [
           const MapEntry('Content-Type', 'application/json'),
           const MapEntry('X-Requested-With', 'XMLHttpRequest'),
        ],
        bodyTemplate: '{"query":"...","variables":{"code":"{code}"}}',
        stdoutPath: 'data.run.stdout',
        stderrPath: 'data.run.stderr',
        isDefaultSystem: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'CodeX',
        endpoint: 'https://api.codex.jaagrav.in',
        method: 'POST',
        authType: 'None',
        headers: [const MapEntry('Content-Type', 'application/x-www-form-urlencoded')],
        bodyTemplate: 'code={code}&language=dart&input={stdin}',
        stdoutPath: 'output',
        stderrPath: 'error',
        isDefaultSystem: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'HackerEarth',
        endpoint: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        method: 'POST',
        authType: 'API-Key Header',
        authKey: 'client-secret',
        authValue: 'YOUR_SECRET',
        headers: [const MapEntry('Content-Type', 'application/json')],
        bodyTemplate: '{"lang":"DART","source":"{code}","input":"{stdin}"}',
        stdoutPath: 'result.run_status.output',
        stderrPath: 'result.run_status.stderr',
        executionTimePath: 'result.run_status.time_used',
        memoryPath: 'result.run_status.memory_used',
        isDefaultSystem: true,
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank',
        endpoint: '',
        method: 'POST',
        authType: 'None',
        isDefaultSystem: true,
      ),
    ];
  }
}

final compilerBoxProvider = Provider<Box<CompilerPreset>>((ref) => throw UnimplementedError());

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  final box = ref.watch(compilerBoxProvider);
  return CompilerNotifier(box);
});
