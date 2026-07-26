import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../hive_service.dart';
import '../models/compiler_preset.dart';

final compilerProvider =
    StateNotifierProvider<CompilerNotifier, CompilerState>((ref) {
  return CompilerNotifier();
});

class CompilerState {
  final List<CompilerPreset> presets;
  final bool useDefaultOneCompiler;
  final String? activePresetId;

  CompilerState({
    required this.presets,
    required this.useDefaultOneCompiler,
    this.activePresetId,
  });

  CompilerState copyWith({
    List<CompilerPreset>? presets,
    bool? useDefaultOneCompiler,
    String? activePresetId,
  }) {
    return CompilerState(
      presets: presets ?? this.presets,
      useDefaultOneCompiler:
          useDefaultOneCompiler ?? this.useDefaultOneCompiler,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }
}

class CompilerNotifier extends StateNotifier<CompilerState> {
  CompilerNotifier()
      : super(CompilerState(
          presets: HiveService.presetsBox.values.toList(),
          useDefaultOneCompiler:
              HiveService.prefs.getBool('useDefaultOneCompiler') ?? true,
          activePresetId: HiveService.prefs.getString('activePresetId'),
        )) {
    if (state.presets.isEmpty) {
      _seedDefaultPresets();
    }
  }

  void _seedDefaultPresets() {
    final defaultPresets = [
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'JDoodle',
        endpoint: 'https://api.jdoodle.com/v1/execute',
        method: 'POST',
        bodyTemplate:
            '{"clientId": "YOUR_CLIENT_ID", "clientSecret": "YOUR_CLIENT_SECRET", "script": "{code}", "stdin": "{stdin}", "language": "dart", "versionIndex": "0"}',
        stdoutPath: 'output',
        timePath: 'cpuTime',
        memoryPath: 'memory',
      ),
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Piston',
        endpoint:
            'https://emacsx.com/api/v200/execution', // using emacsx piston instance as example
        method: 'POST',
        bodyTemplate:
            '{"language": "dart", "version": "3.1.0", "files": [{"name": "main.dart", "content": "{code}"}], "stdin": "{stdin}"}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      // Blank
      CompilerPreset(
        id: const Uuid().v4(),
        name: 'Blank Custom API',
        endpoint: 'https://api.example.com/execute',
      ),
    ];

    for (var preset in defaultPresets) {
      HiveService.presetsBox.put(preset.id, preset);
    }

    state = state.copyWith(
        presets: defaultPresets, activePresetId: defaultPresets.first.id);
    HiveService.prefs.setString('activePresetId', defaultPresets.first.id);
  }

  void toggleDefaultCompiler(bool useDefault) {
    HiveService.prefs.setBool('useDefaultOneCompiler', useDefault);
    state = state.copyWith(useDefaultOneCompiler: useDefault);
  }

  void setActivePreset(String id) {
    HiveService.prefs.setString('activePresetId', id);
    state = state.copyWith(activePresetId: id);
  }

  void savePreset(CompilerPreset preset) {
    HiveService.presetsBox.put(preset.id, preset);
    final updatedPresets = HiveService.presetsBox.values.toList();
    state = state.copyWith(presets: updatedPresets);
  }

  void deletePreset(String id) {
    HiveService.presetsBox.delete(id);
    final updatedPresets = HiveService.presetsBox.values.toList();
    state = state.copyWith(
      presets: updatedPresets,
      activePresetId: state.activePresetId == id
          ? (updatedPresets.isNotEmpty ? updatedPresets.first.id : null)
          : state.activePresetId,
    );
    if (state.activePresetId != null) {
      HiveService.prefs.setString('activePresetId', state.activePresetId!);
    } else {
      HiveService.prefs.remove('activePresetId');
    }
  }
}
