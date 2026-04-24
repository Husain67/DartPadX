import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/preset_provider.dart';
import '../providers/execution_provider.dart';
import 'preset_editor.dart';
import 'dart:convert';
import '../services/file_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/models.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useDefault = ref.watch(useDefaultOneCompilerProvider);
    final presets = ref.watch(presetProvider);
    final selectedId = ref.watch(selectedPresetIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Compilers'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Toggle to use standard setup or Custom APIs'),
            value: useDefault,
            activeTrackColor: const Color(0xFFFACC15).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFFFACC15),
            onChanged: (val) {
              ref.read(useDefaultOneCompilerProvider.notifier).state = val;
            },
          ),
          const Divider(height: 1),
          if (!useDefault) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Custom Compilers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.file_upload),
                        tooltip: 'Export Presets',
                        onPressed: () async {
                          final presetsStr = jsonEncode(presets.map((e) => e.toJson()).toList());
                          await FileService.downloadFile('dart_mini_presets.json', presetsStr);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download),
                        tooltip: 'Import Presets',
                        onPressed: () async {
                          final result = await FileService.importFile();
                          if (result != null) {
                            try {
                              final List<dynamic> decoded = jsonDecode(result['content']!);
                              final newPresets = decoded.map((e) => CompilerPreset.fromJson(e)).toList();
                              ref.read(presetProvider.notifier).importPresetsFromJson(newPresets);
                              Fluttertoast.showToast(msg: 'Presets imported successfully!');
                            } catch (e) {
                              Fluttertoast.showToast(msg: 'Invalid JSON format');
                            }
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PresetEditorScreen(preset: null),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.black, size: 18),
                        label: const Text('Add New', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                        ),
                      ),
                    ],
                  )                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final isSelected = preset.id == selectedId || (selectedId == null && index == 0);

                  return ListTile(
                    tileColor: isSelected ? const Color(0xFF2A2A2A) : null,
                    title: Text(
                      preset.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFFACC15) : Colors.white,
                      ),
                    ),
                    subtitle: Text(preset.endpointUrl, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            ref.read(presetProvider.notifier).duplicatePreset(preset);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PresetEditorScreen(preset: preset),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          onPressed: () {
                            if (presets.length > 1) {
                              ref.read(presetProvider.notifier).deletePreset(preset.id);
                              if (isSelected) {
                                ref.read(selectedPresetIdProvider.notifier).state = null;
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(selectedPresetIdProvider.notifier).state = preset.id;
                    },
                  );
                },
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text(
                  'Default OneCompiler is active.\nDisable it to configure custom APIs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
