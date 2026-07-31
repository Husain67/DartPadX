import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';

final uuid = Uuid();

// --- Hive Boxes ---
final filesBoxProvider = Provider<Box<CodeFile>>((ref) => Hive.box<CodeFile>('files'));
final presetsBoxProvider = Provider<Box<CompilerPreset>>((ref) => Hive.box<CompilerPreset>('presets'));

// --- State Classes ---
class EditorState {
  final List<CodeFile> files;
  final String? activeFileId;
  final bool isExecuting;

  EditorState({
    required this.files,
    this.activeFileId,
    this.isExecuting = false,
  });

  EditorState copyWith({
    List<CodeFile>? files,
    String? activeFileId,
    bool? isExecuting,
  }) {
    return EditorState(
      files: files ?? this.files,
      activeFileId: activeFileId ?? this.activeFileId,
      isExecuting: isExecuting ?? this.isExecuting,
    );
  }

  CodeFile? get activeFile => files.cast<CodeFile?>().firstWhere((f) => f?.id == activeFileId, orElse: () => null);
}

// --- Notifiers ---
class EditorStateNotifier extends StateNotifier<EditorState> {
  final Box<CodeFile> filesBox;
  Timer? _saveTimer;

  EditorStateNotifier(this.filesBox) : super(EditorState(files: [])) {
    _loadFiles();
  }

  void _loadFiles() {
    final storedFiles = filesBox.values.toList();
    if (storedFiles.isEmpty) {
      final defaultFile = CodeFile(
        id: uuid.v4(),
        name: 'main.dart',
        content: 'import \'dart:io\';\n\nvoid main() {\n  print("Hello DartMini IDE!");\n  print("Enter your name:");\n  String? name = stdin.readLineSync();\n  print("Nice to meet you, \$name!");\n}',
      );
      filesBox.put(defaultFile.id, defaultFile);
      state = EditorState(files: [defaultFile], activeFileId: defaultFile.id);
    } else {
      state = EditorState(files: storedFiles, activeFileId: storedFiles.first.id);
    }
  }

  void newFile() {
    int count = state.files.length + 1;
    final newFile = CodeFile(
      id: uuid.v4(),
      name: 'untitled\$count.dart',
      content: '// New Dart file',
    );
    filesBox.put(newFile.id, newFile);
    state = state.copyWith(
      files: [...state.files, newFile],
      activeFileId: newFile.id,
    );
  }

  void addFile(CodeFile file) {
    filesBox.put(file.id, file);
    state = state.copyWith(
      files: [...state.files, file],
      activeFileId: file.id,
    );
  }

  void updateActiveFileContent(String newContent) {
    final activeId = state.activeFileId;
    if (activeId == null) return;

    final files = [...state.files];
    final index = files.indexWhere((f) => f.id == activeId);
    if (index != -1) {
      final updatedFile = files[index].copyWith(content: newContent);
      files[index] = updatedFile;

      // Update UI state immediately
      state = state.copyWith(files: files);

      // Debounce saving to Hive
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 2), () {
        filesBox.put(activeId, updatedFile);
      });
    }
  }

  void setActiveFile(String id) {
    state = state.copyWith(activeFileId: id);
  }

  void closeFile(String id) {
    final files = [...state.files];
    final index = files.indexWhere((f) => f.id == id);
    if (index != -1) {
      filesBox.delete(id);
      files.removeAt(index);

      String? nextActiveId;
      if (files.isNotEmpty) {
        if (state.activeFileId == id) {
          nextActiveId = files.last.id;
        } else {
          nextActiveId = state.activeFileId;
        }
      } else {
         final newFile = CodeFile(
            id: uuid.v4(),
            name: 'untitled.dart',
            content: '',
         );
         filesBox.put(newFile.id, newFile);
         files.add(newFile);
         nextActiveId = newFile.id;
      }

      state = state.copyWith(files: files, activeFileId: nextActiveId);
    }
  }

  void renameFile(String id, String newName) {
     final files = [...state.files];
    final index = files.indexWhere((f) => f.id == id);
    if (index != -1) {
      final updatedFile = files[index].copyWith(name: newName);
      files[index] = updatedFile;
      filesBox.put(id, updatedFile);
      state = state.copyWith(files: files);
    }
  }

  void setExecuting(bool executing) {
    state = state.copyWith(isExecuting: executing);
  }
}

final editorProvider = StateNotifierProvider<EditorStateNotifier, EditorState>((ref) {
  final box = ref.watch(filesBoxProvider);
  return EditorStateNotifier(box);
});

// --- Presets Notifier ---
class PresetsNotifier extends StateNotifier<List<CompilerPreset>> {
  final Box<CompilerPreset> presetsBox;

  PresetsNotifier(this.presetsBox) : super([]) {
    _loadPresets();
  }

  void _loadPresets() {
    var stored = presetsBox.values.toList();
    if (stored.isEmpty) {
      final presets = [
        CompilerPreset.defaultOneCompiler(),
        CompilerPreset.jdoodle(),
        CompilerPreset.piston(),
      ];
      for (var p in presets) {
        presetsBox.put(p.id, p);
      }
      stored = presets;
    }
    state = stored;
  }

  void addPreset(CompilerPreset preset) {
    presetsBox.put(preset.id, preset);
    state = [...state, preset];
  }

  void updatePreset(CompilerPreset preset) {
    presetsBox.put(preset.id, preset);
    state = [
      for (final p in state)
        if (p.id == preset.id) preset else p,
    ];
  }

  void deletePreset(String id) {
    presetsBox.delete(id);
    state = state.where((p) => p.id != id).toList();
  }

  void setDefault(String id) {
     final updated = state.map((p) {
        final isDef = p.id == id;
        final newP = p.copyWith(isDefault: isDef);
        presetsBox.put(newP.id, newP);
        return newP;
     }).toList();
     state = updated;
  }
}

final presetsProvider = StateNotifierProvider<PresetsNotifier, List<CompilerPreset>>((ref) {
  final box = ref.watch(presetsBoxProvider);
  return PresetsNotifier(box);
});

final defaultPresetProvider = Provider<CompilerPreset>((ref) {
  final presets = ref.watch(presetsProvider);
  return presets.firstWhere((p) => p.isDefault, orElse: () => presets.first);
});

class OutputData {
  final String text;
  final String type; // 'normal', 'stdout', 'stderr', 'error', 'meta'

  OutputData({required this.text, this.type = 'normal'});
}

final outputListProvider = StateProvider<List<OutputData>>((ref) => [OutputData(text: 'Ready...')]);
final showOutputProvider = StateProvider<bool>((ref) => false);
