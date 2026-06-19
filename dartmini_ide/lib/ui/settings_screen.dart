import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import '../core/theme.dart';
import 'preset_editor_screen.dart';
import 'examples_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _exportPresets(BuildContext context, CompilerState state) async {
    try {
      final presetsList = state.presets.map((p) => {
        'id': p.id,
        'name': p.name,
        'endpointUrl': p.endpointUrl,
        'httpMethod': p.httpMethod,
        'authType': p.authType,
        'headers': p.headers,
        'queryParams': p.queryParams,
        'requestBodyTemplate': p.requestBodyTemplate,
        'stdoutPath': p.stdoutPath,
        'stderrPath': p.stderrPath,
        'errorPath': p.errorPath,
        'executionTimePath': p.executionTimePath,
        'memoryPath': p.memoryPath,
        'isBuiltIn': p.isBuiltIn,
      }).toList();

      final jsonString = jsonEncode(presetsList);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('\${dir.path}/dartmini_presets.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)], text: 'DartMini IDE Compiler Presets');
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: \$e");
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

        final List<dynamic> decoded = jsonDecode(content);
        int count = 0;

        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            final preset = CompilerPreset(
              name: item['name'] ?? 'Imported Preset',
              endpointUrl: item['endpointUrl'] ?? '',
              httpMethod: item['httpMethod'] ?? 'POST',
              authType: item['authType'] ?? 'None',
              headers: (item['headers'] as Map?)?.cast<String, String>() ?? {},
              queryParams: (item['queryParams'] as Map?)?.cast<String, String>() ?? {},
              requestBodyTemplate: item['requestBodyTemplate'] ?? '{}',
              stdoutPath: item['stdoutPath'] ?? '',
              stderrPath: item['stderrPath'] ?? '',
              errorPath: item['errorPath'] ?? '',
              executionTimePath: item['executionTimePath'] ?? '',
              memoryPath: item['memoryPath'] ?? '',
              isBuiltIn: false, // Imported presets are never built-in
            );
            ref.read(compilerProvider.notifier).addPreset(preset);
            count++;
          }
        }

        Fluttertoast.showToast(msg: "Successfully imported \$count presets");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: Invalid JSON");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      backgroundColor: AppTheme.backgroundStart,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Global Execution Settings
          const Text('Execution Engine', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Toggle to use custom presets instead', style: TextStyle(color: Colors.grey)),
              value: compilerState.useDefaultOneCompiler,
              activeColor: AppTheme.primaryAccent, // ignore: deprecated_member_use
              onChanged: (val) {
                ref.read(compilerProvider.notifier).setUseDefaultOneCompiler(val);
              },
            ),
          ),
          const SizedBox(height: 24),

          // Presets Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom Compiler Presets', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.grey),
                    tooltip: 'Import JSON',
                    onPressed: () => _importPresets(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload, color: Colors.grey),
                    tooltip: 'Export JSON',
                    onPressed: () => _exportPresets(context, compilerState),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Add Preset',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...compilerState.presets.map((preset) {
            final isSelected = !compilerState.useDefaultOneCompiler && compilerState.activePresetId == preset.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryAccent.withValues(alpha: 0.1) : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: AppTheme.primaryAccent, width: 1) : null,
              ),
              child: ListTile(
                title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                      },
                    ),
                    if (!preset.isBuiltIn)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          ref.read(compilerProvider.notifier).deletePreset(preset.id);
                        },
                      ),
                  ],
                ),
                onTap: () {
                  if (!compilerState.useDefaultOneCompiler) {
                    ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  }
                },
              ),
            );
          }),

          const SizedBox(height: 24),
          const Text('Misc', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.book, color: Colors.white),
              title: const Text('Code Examples', style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
