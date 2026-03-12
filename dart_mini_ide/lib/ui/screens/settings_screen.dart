import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import '../../services/export_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _importPresets(ref),
            tooltip: 'Import JSON',
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => _exportPresets(settings.presets),
            tooltip: 'Export JSON',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler API'),
              subtitle: const Text('Turn off to use custom presets below'),
              activeTrackColor: AppTheme.accentYellow,
              value: settings.useDefaultCompiler,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).toggleDefaultCompiler(val);
              },
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: settings.presets.length,
                itemBuilder: (context, index) {
                  final preset = settings.presets[index];
                  final isActive = preset.id == settings.activePresetId;

                  return Opacity(
                    opacity: settings.useDefaultCompiler ? 0.5 : 1.0,
                    child: ListTile(
                      title: Text(preset.name),
                      subtitle: Text(preset.endpointUrl, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive && !settings.useDefaultCompiler)
                            const Icon(Icons.check_circle, color: AppTheme.accentYellow),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: settings.useDefaultCompiler
                                ? null
                                : () => _editPreset(context, ref, preset),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                            onPressed: settings.useDefaultCompiler || preset.isReadOnly
                                ? null
                                : () => ref.read(settingsProvider.notifier).deletePreset(preset.id),
                          ),
                        ],
                      ),
                      onTap: settings.useDefaultCompiler
                          ? null
                          : () => ref.read(settingsProvider.notifier).setActivePreset(preset.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: settings.useDefaultCompiler
          ? null
          : FloatingActionButton(
              onPressed: () => _addPreset(context, ref),
              backgroundColor: AppTheme.accentYellow,
              child: const Icon(Icons.add, color: Colors.black),
            ),
    );
  }

  void _addPreset(BuildContext context, WidgetRef ref) {
    final preset = CompilerPreset(
      name: 'New Custom API',
      endpointUrl: 'https://',
      requestBodyTemplate: '{"code": "{code}"}',
    );
    ref.read(settingsProvider.notifier).addPreset(preset);
    _editPreset(context, ref, preset);
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset preset) {
     // For a full implementation, a new screen or dialog with forms for endpoints,
     // auth, headers, and json body templates should go here.
     // We'll show a basic editing toast for this scope to keep it concise but working.
     Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
  }

  Future<void> _importPresets(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(content);

        for (var item in jsonList) {
          final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
          ref.read(settingsProvider.notifier).addPreset(preset);
        }
        Fluttertoast.showToast(msg: "Imported presets successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing presets");
    }
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    final jsonList = presets.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    try {
      await ExportService.downloadFile('compiler_presets.json', jsonString);
      Fluttertoast.showToast(msg: "Exported to downloads");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error exporting presets");
    }
  }
}
