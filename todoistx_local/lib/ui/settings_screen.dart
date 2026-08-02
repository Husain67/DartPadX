import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import 'preset_editor_screen.dart';
import 'examples_screen.dart';
import 'theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _exportPresets(List<CompilerPreset> presets) async {
    try {
      final jsonStr = json.encode(presets.map((e) => e.toMap()).toList());
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      final path = '${directory!.path}/compiler_presets.json';
      await File(path).writeAsString(jsonStr);
      Fluttertoast.showToast(msg: "Exported to $path");
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: $e");
    }
  }

  void _importPresets(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final List<dynamic> decoded = json.decode(content);
        final imported = decoded.map((e) => CompilerPreset.fromMap(e)).toList();

        for (var preset in imported) {
          if (!preset.isDefaultPreset) {
            ref.read(compilerProvider.notifier).addPreset(preset);
          }
        }
        Fluttertoast.showToast(msg: "Imported ${imported.length} presets");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Compiler Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'Examples',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(state.presets),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(ref),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.presets.length,
        itemBuilder: (context, index) {
          final preset = state.presets[index];
          final isActive = preset.id == state.activePresetId;

          return Card(
            color: AppTheme.backgroundEnd,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isActive ? AppTheme.primaryAccent : Colors.transparent, width: 2),
            ),
            child: ListTile(
              title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text(preset.isDefaultPreset ? 'Built-in API' : preset.endpoint, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isActive)
                    TextButton(
                      onPressed: () => ref.read(compilerProvider.notifier).setActivePreset(preset.id),
                      child: const Text('Set Active', style: TextStyle(color: AppTheme.primaryAccent)),
                    ),
                  if (!preset.isDefaultPreset) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset))),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                    ),
                  ]
                ],
              ),
              onTap: preset.isDefaultPreset ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset))),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryAccent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('New Custom Preset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen())),
      ),
    );
  }
}
