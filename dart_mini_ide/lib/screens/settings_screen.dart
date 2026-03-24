import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';
import 'preset_editor_screen.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Box<CompilerPreset> _presetsBox = Hive.box<CompilerPreset>('presets');
  final Box _settingsBox = Hive.box('settings');

  @override
  void initState() {
    super.initState();
    if (_presetsBox.isEmpty) {
      _loadDefaultPresets();
    }
  }

  void _loadDefaultPresets() {
    final uuid = const Uuid();
    final defaults = [
      CompilerPreset(
        id: uuid.v4(),
        name: 'JDoodle',
        endpointUrl: 'https://api.jdoodle.com/v1/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"clientId":"YOUR_CLIENT_ID","clientSecret":"YOUR_CLIENT_SECRET","script":{code},"language":"dart","versionIndex":"4"}',
        stdoutPath: 'output',
        stderrPath: 'error',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Piston',
        endpointUrl: 'https://emkc.org/api/v2/piston/execute',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"language":"dart","version":"*","files":[{"name":"main.dart","content":{code}}],"stdin":{stdin}}',
        stdoutPath: 'run.stdout',
        stderrPath: 'run.stderr',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Replit',
        endpointUrl: 'https://replit.com/api/v1/repls/...',
        httpMethod: 'POST',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'CodeX',
        endpointUrl: 'https://api.codex.jaagrav.in',
        httpMethod: 'POST',
        headers: {'Content-Type': 'application/json'},
        requestBodyTemplate: '{"code":{code},"language":"dart"}',
        stdoutPath: 'output',
        errorPath: 'error',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'HackerEarth',
        endpointUrl: 'https://api.hackerearth.com/v4/partner/code-evaluation/submissions/',
        httpMethod: 'POST',
      ),
      CompilerPreset(
        id: uuid.v4(),
        name: 'Blank Preset',
        endpointUrl: 'https://',
        httpMethod: 'POST',
      ),
    ];

    for (var preset in defaults) {
      _presetsBox.put(preset.id, preset);
    }
    setState(() {});
  }

  Future<void> _exportPresets() async {
    try {
      final presets = _presetsBox.values.map((e) => e.toJson()).toList();
      final jsonStr = jsonEncode(presets);

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/dartmini_presets.json';
      final file = File(filePath);
      await file.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(filePath)], text: 'Exported Presets');
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: $e");
    }
  }

  Future<void> _importPresets() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> parsed = jsonDecode(content);

        for (var item in parsed) {
          final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
          _presetsBox.put(preset.id, preset);
        }
        setState(() {});
        Fluttertoast.showToast(msg: "Presets imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool useDefaultCompiler = _settingsBox.get('useDefaultCompiler', defaultValue: true);
    String? activePresetId = _settingsBox.get('activePresetId');

    return Scaffold(
      backgroundColor: AppTheme.pureBlack,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.pureBlack,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: AppTheme.primaryYellow,
              labelColor: AppTheme.primaryYellow,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'General'),
                Tab(text: 'Compiler Presets'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // General Tab
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SwitchListTile(
                        title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Turn off to use custom presets', style: TextStyle(color: Colors.white54)),
                        activeColor: AppTheme.primaryYellow,
                        value: useDefaultCompiler,
                        onChanged: (val) {
                          setState(() {
                            _settingsBox.put('useDefaultCompiler', val);
                          });
                        },
                      ),
                    ],
                  ),
                  // Presets Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PresetEditorScreen(
                                      preset: CompilerPreset(
                                        id: const Uuid().v4(),
                                        name: 'New Preset',
                                        endpointUrl: '',
                                      ),
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              icon: const Icon(Icons.add, color: AppTheme.pureBlack),
                              label: const Text('New Preset', style: TextStyle(color: AppTheme.pureBlack)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.upload_file, color: Colors.white),
                                  onPressed: _importPresets,
                                  tooltip: 'Import JSON',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download, color: Colors.white),
                                  onPressed: _exportPresets,
                                  tooltip: 'Export JSON',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: _presetsBox.listenable(),
                          builder: (context, Box<CompilerPreset> box, _) {
                            final presets = box.values.toList();
                            return ListView.builder(
                              itemCount: presets.length,
                              itemBuilder: (context, index) {
                                final preset = presets[index];
                                final isActive = !useDefaultCompiler && preset.id == activePresetId;

                                return ListTile(
                                  title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isActive)
                                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                      IconButton(
                                        icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                                        onPressed: () {
                                          final clone = CompilerPreset.fromJson(preset.toJson());
                                          final newPreset = CompilerPreset(
                                              id: const Uuid().v4(),
                                              name: '${clone.name} (Copy)',
                                              endpointUrl: clone.endpointUrl,
                                              httpMethod: clone.httpMethod,
                                              authType: clone.authType,
                                              headers: Map.from(clone.headers),
                                              queryParams: Map.from(clone.queryParams),
                                              requestBodyTemplate: clone.requestBodyTemplate,
                                              stdoutPath: clone.stdoutPath,
                                              stderrPath: clone.stderrPath,
                                              errorPath: clone.errorPath,
                                              executionTimePath: clone.executionTimePath,
                                              memoryPath: clone.memoryPath,
                                          );
                                          box.put(newPreset.id, newPreset);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                        onPressed: () {
                                          box.delete(preset.id);
                                          if (activePresetId == preset.id) {
                                            _settingsBox.delete('activePresetId');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PresetEditorScreen(preset: preset),
                                      ),
                                    ).then((_) => setState(() {}));
                                  },
                                  onLongPress: () {
                                    _settingsBox.put('activePresetId', preset.id);
                                    _settingsBox.put('useDefaultCompiler', false);
                                    setState(() {});
                                    Fluttertoast.showToast(msg: "Set as active preset");
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
