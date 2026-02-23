import 'dart:convert';
import 'package:dart_mini_ide/core/constants.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/providers/settings_provider.dart';
import 'package:dart_mini_ide/ui/screens/preset_editor_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & API'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(ref),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(settings.presets),
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Custom Compiler API'),
            subtitle: const Text('Override default OneCompiler with selected preset'),
            value: settings.useCustomPreset,
            onChanged: (val) => notifier.setUseCustomPreset(val),
            activeTrackColor: AppColors.accent,
            activeColor: AppColors.accent,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Compiler Presets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          ...settings.presets.map((preset) {
            final isActive = settings.activePreset?.id == preset.id;
            return ListTile(
              title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive) const Icon(Icons.check_circle, color: AppColors.accent),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PresetEditorScreen(preset: preset),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(context, ref, preset),
                  ),
                ],
              ),
              onTap: () => notifier.setActivePreset(preset),
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PresetEditorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Preset'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importPresets(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = result.files.first;
        final content = utf8.decode(file.bytes!); // Assuming bytes are available
        final List<dynamic> jsonList = jsonDecode(content);
        for (final item in jsonList) {
           // Basic validation?
           // I'll create from JSON manually or assumes valid structure.
           // Since I don't have `fromJson` generated (I used Hive), I have to map manually or add `fromJson` to model.
           // I'll add `fromJson` to model later or map here.
           // For now, I'll map manually.
           final preset = CompilerPreset(
             name: item['name'],
             endpoint: item['endpoint'],
             method: item['method'],
             authType: item['authType'],
             headers: Map<String, String>.from(item['headers']),
             queryParams: Map<String, String>.from(item['queryParams']),
             requestBodyTemplate: item['requestBodyTemplate'],
             stdoutPath: item['stdoutPath'],
             stderrPath: item['stderrPath'],
             errorPath: item['errorPath'],
             executionTimePath: item['executionTimePath'],
             memoryPath: item['memoryPath'],
           );
           await ref.read(settingsProvider.notifier).addPreset(preset);
        }
        Fluttertoast.showToast(msg: "Imported ${jsonList.length} presets");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing: $e");
    }
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    final List<Map<String, dynamic>> jsonList = presets.map((p) => {
      'name': p.name,
      'endpoint': p.endpoint,
      'method': p.method,
      'authType': p.authType,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'requestBodyTemplate': p.requestBodyTemplate,
      'stdoutPath': p.stdoutPath,
      'stderrPath': p.stderrPath,
      'errorPath': p.errorPath,
      'executionTimePath': p.executionTimePath,
      'memoryPath': p.memoryPath,
    }).toList();

    final jsonString = jsonEncode(jsonList);
    await Share.share(jsonString, subject: 'DartMini Presets.json');
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CompilerPreset preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: Text('Delete ${preset.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).deletePreset(preset);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
