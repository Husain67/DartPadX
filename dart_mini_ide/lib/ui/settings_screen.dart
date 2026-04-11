import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Recommended for basic use. Disables custom presets.'),
            value: settings.useDefaultOneCompiler,
            activeTrackColor: const Color(0xFFFACC15),
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(val);
            },
          ),
          const Divider(height: 32, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom Compiler Presets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFACC15)),
              ),
              Row(
                children: [
                   IconButton(
                      icon: const Icon(Icons.upload_file, size: 20),
                      tooltip: 'Import Presets JSON',
                      onPressed: () async {
                         FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['json', 'txt'],
                         );
                         if (result != null && result.files.single.path != null) {
                            final file = File(result.files.single.path!);
                            final content = await file.readAsString();
                            ref.read(settingsProvider.notifier).importPresets(content);
                            Fluttertoast.showToast(msg: "Presets imported");
                         }
                      },
                   ),
                   IconButton(
                      icon: const Icon(Icons.download, size: 20),
                      tooltip: 'Export Presets JSON',
                      onPressed: () async {
                         final jsonStr = await ref.read(settingsProvider.notifier).exportPresets();
                         final tempDir = await getTemporaryDirectory();
                         final file = File('${tempDir.path}/dartmini_presets.json');
                         await file.writeAsString(jsonStr);
                         await Share.shareXFiles([XFile(file.path)]);
                      },
                   )
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Select or configure an external API to execute Dart code.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...settings.presets.map((preset) {
            final isActive = preset.id == settings.activePresetId && !settings.useDefaultOneCompiler;
            return Card(
              color: isActive ? const Color(0xFF1a1a1a) : Colors.transparent,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isActive ? const Color(0xFFFACC15) : Colors.white12,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(preset.name, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Duplicate',
                      onPressed: () {
                         ref.read(settingsProvider.notifier).duplicatePreset(preset);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PresetEditorScreen(preset: preset),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                  if (settings.useDefaultOneCompiler) {
                     ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              final newPreset = CompilerPreset(
                id: const Uuid().v4(),
                name: 'New Custom Preset',
                endpointUrl: 'https://',
                httpMethod: 'POST',
                authType: 'None',
                headers: {},
                queryParams: {},
                requestBodyTemplate: '{\\n  "code": "{code}"\\n}',
                stdoutPath: '',
                stderrPath: '',
                errorPath: '',
                executionTimePath: '',
                memoryPath: '',
              );
              ref.read(settingsProvider.notifier).addPreset(newPreset);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PresetEditorScreen(preset: newPreset),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9F9F9),
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create New Preset'),
          ),
        ],
      ),
    );
  }
}
