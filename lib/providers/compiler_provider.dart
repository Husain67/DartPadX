import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../services/hive_service.dart';
import '../services/compiler_service.dart';

class CompilerState {
  final bool isExecuting;
  final String? stdout;
  final String? stderr;
  final String? error;
  final String? executionTime;
  final String? memory;
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool isOutputSheetVisible;

  CompilerState({
    required this.isExecuting,
    this.stdout,
    this.stderr,
    this.error,
    this.executionTime,
    this.memory,
    required this.presets,
    required this.activePresetId,
    this.isOutputSheetVisible = false,
  });

  CompilerState copyWith({
    bool? isExecuting,
    String? stdout,
    String? stderr,
    String? error,
    String? executionTime,
    String? memory,
    List<CompilerPreset>? presets,
    String? activePresetId,
    bool? isOutputSheetVisible,
  }) {
    return CompilerState(
      isExecuting: isExecuting ?? this.isExecuting,
      stdout: stdout ?? this.stdout,
      stderr: stderr ?? this.stderr,
      error: error ?? this.error,
      executionTime: executionTime ?? this.executionTime,
      memory: memory ?? this.memory,
      presets: presets ?? this.presets,
      activePresetId: activePresetId ?? this.activePresetId,
      isOutputSheetVisible: isOutputSheetVisible ?? this.isOutputSheetVisible,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier() : super(CompilerState(
    isExecuting: false,
    presets: [],
    activePresetId: '',
  )) {
    _loadPresets();
  }

  void _loadPresets() {
    final presets = HiveService.presetsBox.values.toList();
    final activeId = HiveService.settingsBox.get('activePresetId', defaultValue: presets.first.id);

    state = state.copyWith(
      presets: presets,
      activePresetId: activeId,
    );
  }

  CompilerPreset? get activePreset {
    try {
      return state.presets.firstWhere((p) => p.id == state.activePresetId);
    } catch (_) {
      return state.presets.isNotEmpty ? state.presets.first : null;
    }
  }

  void setActivePreset(String id) {
    HiveService.settingsBox.put('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    _loadPresets();
  }

  void deletePreset(String id) {
    HiveService.presetsBox.delete(id);
    _loadPresets();
    if (state.activePresetId == id && state.presets.isNotEmpty) {
      setActivePreset(state.presets.first.id);
    }
  }

  void toggleOutputSheet(bool visible) {
    state = state.copyWith(isOutputSheetVisible: visible);
  }

  void clearOutput() {
    state = state.copyWith(
      stdout: '',
      stderr: '',
      error: '',
      executionTime: '',
      memory: '',
    );
  }

  Future<void> executeCode(String code, String stdin, String filename) async {
    final preset = activePreset;
    if (preset == null) return;

    state = state.copyWith(isExecuting: true, isOutputSheetVisible: true, stdout: '', stderr: '', error: '');

    final output = await CompilerService.executeCode(
      code: code,
      stdin: stdin,
      filename: filename,
      preset: preset,
    );

    state = state.copyWith(
      isExecuting: false,
      stdout: output.stdout,
      stderr: output.stderr,
      error: output.error,
      executionTime: output.executionTime,
      memory: output.memory,
    );
  }

  Future<CompilerOutput> testPresetExecution(CompilerPreset preset) async {
    return await CompilerService.executeCode(
      code: "void main() { print('Hello from custom API'); }",
      stdin: "",
      filename: "main.dart",
      preset: preset,
    );
  }
}

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});
