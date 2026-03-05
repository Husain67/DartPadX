import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/constants.dart';
import '../../providers/preset_provider.dart';
import '../../data/compiler_preset.dart';
import 'preset_editor_screen.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetState = ref.watch(presetProvider);
    final isUsingDefault = presetState.useDefaultOneCompiler;
    final presets = presetState.presets;
    final selectedPreset = presetState.selectedPresetId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & API'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler API'),
            subtitle: const Text('Recommended for stable execution'),
            value: isUsingDefault,
            onChanged: (val) => ref.read(presetProvider.notifier).toggleUseDefault(val),
            activeColor: AppColors.accent,
          ),
          const Divider(height: 32, color: AppColors.buttonBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom Compiler Presets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: AppColors.textPrimary),
                    tooltip: 'Import Presets',
                    onPressed: () => _importPresets(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_rounded, color: AppColors.textPrimary),
                    tooltip: 'Export Presets',
                    onPressed: () => _exportPresets(context, ref, presets),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppColors.accent),
                    tooltip: 'New Custom API',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PresetEditorScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (presets.isEmpty)
            const Text('No custom presets available.')
          else
            ...presets.map((preset) => Card(
                  color: selectedPreset == preset.id && !isUsingDefault
                      ? AppColors.pureBlack
                      : AppColors.backgroundEnd,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: selectedPreset == preset.id && !isUsingDefault
                          ? AppColors.accent
                          : AppColors.buttonBorder,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Duplicate',
                          onPressed: () {
                            // Since copyWith doesn't support changing id in the current implementation,
                            // we create a new preset based on the current one.
                            final duplicate = CompilerPreset(
                              id: const Uuid().v4(),
                              name: '${preset.name} (Copy)',
                              endpointUrl: preset.endpointUrl,
                              httpMethod: preset.httpMethod,
                              authType: preset.authType,
                              headers: preset.headers,
                              queryParams: preset.queryParams,
                              requestBodyTemplate: preset.requestBodyTemplate,
                              stdoutPath: preset.stdoutPath,
                              stderrPath: preset.stderrPath,
                              errorPath: preset.errorPath,
                              executionTimePath: preset.executionTimePath,
                              memoryPath: preset.memoryPath,
                            );
                            ref.read(presetProvider.notifier).addPreset(duplicate);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Edit',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PresetEditorScreen(preset: preset)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.outputRed, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => ref.read(presetProvider.notifier).deletePreset(preset.id),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isUsingDefault) {
                        ref.read(presetProvider.notifier).selectPreset(preset.id);
                      }
                    },
                  ),
                )),
        ],
      ),
    );
  }

  Future<void> _exportPresets(BuildContext context, WidgetRef ref, List<CompilerPreset> presets) async {
    try {
      final jsonList = presets.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/compiler_presets.json');
      await tempFile.writeAsString(jsonString);
      await Share.shareXFiles([XFile(tempFile.path)], text: 'DartMini Compiler Presets');
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to export presets");
    }
  }

  Future<void> _importPresets(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final importedPresets = jsonList.map((j) => CompilerPreset.fromJson(j)).toList();
        ref.read(presetProvider.notifier).importPresets(importedPresets);
        Fluttertoast.showToast(msg: "Imported ${importedPresets.length} presets");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to import presets. Invalid JSON.");
    }
  }
}
