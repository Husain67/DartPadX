import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _exportPresets(WidgetRef ref) {
    final state = ref.read(compilerProvider);
    final presetsJson = state.presets.map((p) => {
      'name': p.name,
      'url': p.url,
      'method': p.method,
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

    final jsonStr = jsonEncode(presetsJson);
    Share.share(jsonStr, subject: 'DartMini Presets');
  }

  void _importPresets(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'txt'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        try {
          final content = utf8.decode(file.bytes!);
          final List<dynamic> parsed = jsonDecode(content);
          for (var p in parsed) {
            final preset = CompilerPreset(
              id: '',
              name: p['name'] ?? 'Imported Preset',
              url: p['url'] ?? '',
              method: p['method'] ?? 'POST',
              authType: p['authType'] ?? 'None',
              authValue: p['authValue'] ?? '',
              headers: Map<String, String>.from(p['headers'] ?? {}),
              queryParams: Map<String, String>.from(p['queryParams'] ?? {}),
              bodyTemplate: p['bodyTemplate'] ?? '{}',
              stdoutPath: p['stdoutPath'] ?? '',
              stderrPath: p['stderrPath'] ?? '',
              errorPath: p['errorPath'] ?? '',
              executionTimePath: p['executionTimePath'] ?? '',
              memoryPath: p['memoryPath'] ?? '',
              isBuiltIn: false,
            );
            ref.read(compilerProvider.notifier).addPreset(preset);
          }
          Fluttertoast.showToast(msg: "Imported ${parsed.length} presets");
        } catch (e) {
          Fluttertoast.showToast(msg: "Invalid JSON format");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler API'),
            value: state.useDefaultOneCompiler,
            activeColor: const Color(0xFFFACC15),
            onChanged: (val) {
              ref.read(compilerProvider.notifier).toggleUseDefault(val);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Custom Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.presets.length,
              itemBuilder: (context, index) {
                final preset = state.presets[index];
                return ListTile(
                  title: Text(preset.name),
                  subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!state.useDefaultOneCompiler)
                        Radio<String>(
                          value: preset.id,
                          groupValue: state.activePresetId,
                          activeColor: const Color(0xFFFACC15),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(compilerProvider.notifier).setActivePreset(val);
                            }
                          },
                        ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                          } else if (val == 'duplicate') {
                            final newPreset = preset.copyWith(id: '', name: '${preset.name} (Copy)', isBuiltIn: false);
                            ref.read(compilerProvider.notifier).addPreset(newPreset);
                          } else if (val == 'delete') {
                            ref.read(compilerProvider.notifier).deletePreset(preset.id);
                          } else if (val == 'default') {
                            ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                            ref.read(compilerProvider.notifier).toggleUseDefault(false);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'default', child: Text('Set as Default')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                          if (!preset.isBuiltIn)
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFACC15),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
        },
      ),
    );
  }
}
