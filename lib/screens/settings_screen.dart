import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'preset_editor_screen.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);
    final notifier = ref.read(compilerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('When enabled, the default OneCompiler API is used regardless of the selected preset.'),
            value: state.useDefaultOneCompiler,
            onChanged: (val) {
              notifier.setUseDefaultOneCompiler(val);
            },
            activeTrackColor: const Color(0xFFFACC15).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFFFACC15),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Compiler Presets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final newPreset = CompilerPreset(
                    id: '',
                    name: 'New Preset',
                    endpointUrl: '',
                    httpMethod: 'POST',
                    authType: 'None',
                    authValue: '',
                    headers: [],
                    queryParams: [],
                    bodyTemplate: '{}',
                    stdoutPath: '',
                    stderrPath: '',
                    errorPath: '',
                    executionTimePath: '',
                    memoryPath: '',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PresetEditorScreen(preset: newPreset, isNew: true),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D2D2D), foregroundColor: Colors.white),
                onPressed: () async {
                  try {
                    final presets = state.presets.map((p) => {
                      'name': p.name,
                      'endpointUrl': p.endpointUrl,
                      'httpMethod': p.httpMethod,
                      'authType': p.authType,
                      'authValue': p.authValue,
                      'headers': p.headers,
                      'queryParams': p.queryParams,
                      'bodyTemplate': p.bodyTemplate,
                      'stdoutPath': p.stdoutPath,
                      'stderrPath': p.stderrPath,
                      'errorPath': p.errorPath,
                      'executionTimePath': p.executionTimePath,
                      'memoryPath': p.memoryPath,
                    }).toList();
                    final jsonStr = jsonEncode(presets);
                    final directory = await getApplicationDocumentsDirectory();
                    final file = File('${directory.path}/dartmini_presets.json');
                    await file.writeAsString(jsonStr);
                    Share.shareXFiles([XFile(file.path)], text: 'DartMini IDE Compiler Presets');
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Export failed');
                  }
                },
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Export JSON'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D2D2D), foregroundColor: Colors.white),
                onPressed: () async {
                  try {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
                    if (result != null && result.files.single.path != null) {
                      final file = File(result.files.single.path!);
                      final content = await file.readAsString();
                      final List<dynamic> data = jsonDecode(content);
                      for (var item in data) {
                        final preset = CompilerPreset(
                          id: '', // provider will assign new id
                          name: item['name'] ?? 'Imported Preset',
                          endpointUrl: item['endpointUrl'] ?? '',
                          httpMethod: item['httpMethod'] ?? 'POST',
                          authType: item['authType'] ?? 'None',
                          authValue: item['authValue'] ?? '',
                          headers: List<Map<dynamic, dynamic>>.from(item['headers'] ?? []),
                          queryParams: List<Map<dynamic, dynamic>>.from(item['queryParams'] ?? []),
                          bodyTemplate: item['bodyTemplate'] ?? '{}',
                          stdoutPath: item['stdoutPath'] ?? '',
                          stderrPath: item['stderrPath'] ?? '',
                          errorPath: item['errorPath'] ?? '',
                          executionTimePath: item['executionTimePath'] ?? '',
                          memoryPath: item['memoryPath'] ?? '',
                        );
                        notifier.addPreset(preset);
                      }
                      Fluttertoast.showToast(msg: 'Imported successfully');
                    }
                  } catch (e) {
                    Fluttertoast.showToast(msg: 'Import failed: Invalid JSON');
                  }
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Import JSON'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...state.presets.map((preset) {
            final isSelected = !state.useDefaultOneCompiler && preset.id == state.activePresetId;
            return Card(
              color: isSelected ? const Color(0xFF2D2D2D) : const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isSelected ? const Color(0xFFFACC15) : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(preset.endpointUrl.isEmpty ? 'No endpoint configured' : preset.endpointUrl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!preset.isPreloaded)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PresetEditorScreen(preset: preset, isNew: false),
                            ),
                          );
                        },
                      ),
                    if (!preset.isPreloaded)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Preset?'),
                              content: Text('Are you sure you want to delete ${preset.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    notifier.deletePreset(preset.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
                onTap: () {
                  if (!state.useDefaultOneCompiler) {
                    notifier.setActivePreset(preset.id);
                  } else {
                    Fluttertoast.showToast(msg: 'Disable "Use Default OneCompiler" to select a preset.');
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
