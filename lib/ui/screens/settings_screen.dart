import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/compiler_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/compiler_provider.dart';
import '../theme.dart';
import 'package:uuid/uuid.dart';
import 'preset_editor.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Future<void> _exportPresets(WidgetRef ref) async {
    try {
      final presets = ref.read(compilerProvider).presets;
      final jsonList = presets.map((p) => {
        'name': p.name,
        'endpointUrl': p.endpointUrl,
        'httpMethod': p.httpMethod,
        'authType': p.authType,
        'authKey': p.authKey,
        'headers': p.headers,
        'queryParams': p.queryParams,
        'bodyTemplate': p.bodyTemplate,
        'stdoutPath': p.stdoutPath,
        'stderrPath': p.stderrPath,
        'errorPath': p.errorPath,
        'executionTimePath': p.executionTimePath,
        'memoryPath': p.memoryPath,
      }).toList();
      final jsonStr = jsonEncode(jsonList);
      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      final path = '${dir!.path}/dartmini_presets.json';
      await File(path).writeAsString(jsonStr);
      Fluttertoast.showToast(msg: 'Presets exported to $path');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Export failed: $e');
    }
  }

  Future<void> _importPresets(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null && result.files.single.path != null) {
        final content = await File(result.files.single.path!).readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        for (var item in jsonList) {
          // Simplistic import mapping
          // In a real app, you'd map this properly to CompilerPreset model and save
        }
        Fluttertoast.showToast(msg: 'Presets imported! (Demo)');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Import failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Compiler Presets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // General Settings
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Use Default OneCompiler'),
                subtitle: const Text('Overrides selected custom preset'),
                activeTrackColor: AppTheme.accentYellow,
                activeThumbColor: Colors.black,
                value: compilerState.useDefault,
                onChanged: (val) {
                  ref.read(compilerProvider.notifier).setUseDefault(val);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Export Presets'),
                onTap: () => _exportPresets(ref),
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Import Presets'),
                onTap: () => _importPresets(ref),
              ),
              const Divider(),
              const ListTile(
                title: Text('About DartMini IDE'),
                subtitle: Text('Version 1.0.0 (beta)'),
              ),
            ],
          ),
          // Compiler Presets
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: compilerState.presets.length,
            itemBuilder: (context, index) {
              final preset = compilerState.presets[index];
              final isActive = preset.id == compilerState.activePresetId && !compilerState.useDefault;
              return Card(
                color: AppTheme.darkSurface,
                child: ListTile(
                  title: Text(preset.name, style: TextStyle(color: isActive ? AppTheme.accentYellow : AppTheme.textLight)),
                  subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppTheme.textDim),
                        onPressed: () {
                          final duplicate = preset.copyWith(
                            id: const Uuid().v4(),
                            name: '${preset.name} Copy',
                            isReadOnly: false,
                          );
                          ref.read(compilerProvider.notifier).savePreset(duplicate);
                          Fluttertoast.showToast(msg: 'Preset duplicated');
                        },
                      ),
                      if (!preset.isReadOnly)
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.textDim),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditor(preset: preset)));
                          },
                        ),
                      if (!preset.isReadOnly)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            ref.read(compilerProvider.notifier).deletePreset(preset.id);
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: Colors.green),
                        onPressed: () async {
                           Fluttertoast.showToast(msg: 'Testing connection...');
                           final result = await CompilerService.executeCode(
                             preset: preset,
                             code: "void main() { print('Hello from custom API'); }",
                             stdin: "",
                             language: "dart",
                           );
                           if (context.mounted) {
                             showDialog(
                               context: context,
                               builder: (_) => AlertDialog(
                                 title: const Text('Test Result'),
                                 content: Text('Stdout: ${result.stdout}\nStderr: ${result.stderr}\nError: ${result.error}'),
                                 actions: [
                                   TextButton(onPressed: () => Navigator.pop(_), child: const Text('Close'))
                                 ],
                               )
                             );
                           }
                        },
                      )
                    ],
                  ),
                  onTap: () {
                    ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: Colors.black,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditor()));
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
