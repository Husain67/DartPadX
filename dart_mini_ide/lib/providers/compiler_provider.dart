import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';

final compilerProvider = StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final bool useDefaultOneCompiler;

  CompilerState({
    required this.presets,
    required this.activePresetId,
    required this.useDefaultOneCompiler,
  });

  CompilerPreset? get activePreset => presets.where((p) => p.id == activePresetId).firstOrNull;

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
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  late Box<CompilerPreset> _box;

  CompilerNotifier() : super(CompilerState(
    presets: [],
    activePresetId: '',
    useDefaultOneCompiler: true,
  )) {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box<CompilerPreset>('compiler_presets');

    // Add default presets if empty
    if (_box.isEmpty) {
      final defaultPresets = [
        CompilerPreset(
          id: const Uuid().v4(),
          name: 'OneCompiler',
          endpointUrl: 'https://onecompiler-apis.p.rapidapi.com/api/v1/run',
          httpMethod: 'POST',
          authType: 'API-Key Header',
          authValue: 'YOUR_RAPID_API_KEY', // They should edit this or use default OneCompiler logic
          headers: {
            'X-RapidAPI-Host': 'onecompiler-apis.p.rapidapi.com',
          },
          bodyTemplate: '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": {code}}]}',
          stdoutPath: 'stdout',
          stderrPath: 'stderr',
          executionTimePath: 'executionTime',
        ),
        // other defaults like JDoodle, Piston could go here
      ];
      for (var p in defaultPresets) {
        await _box.put(p.id, p);
      }
    }

    state = CompilerState(
      presets: _box.values.toList(),
      activePresetId: _box.values.first.id,
      useDefaultOneCompiler: true, // defaulting to true for beta
    );
  }

  Future<void> addPreset(CompilerPreset preset) async {
    await _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  Future<void> updatePreset(CompilerPreset preset) async {
    await _box.put(preset.id, preset);
    state = state.copyWith(presets: _box.values.toList());
  }

  Future<void> deletePreset(String id) async {
    await _box.delete(id);
    final remaining = _box.values.toList();
    state = state.copyWith(
      presets: remaining,
      activePresetId: remaining.isNotEmpty ? remaining.first.id : '',
    );
  }

  void setActivePreset(String id) {
    state = state.copyWith(activePresetId: id);
  }

  void toggleUseDefault(bool useDefault) {
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }
}
