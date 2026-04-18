import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/settings_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/execution_provider.dart';
import '../../models/compiler_preset.dart';
import '../../theme/app_theme.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            indicatorColor: AppTheme.accentYellow,
            labelColor: AppTheme.accentYellow,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GeneralSettingsTab(),
            _CompilerPresetsTab(),
          ],
        ),
      ),
    );
  }
}

class _GeneralSettingsTab extends ConsumerWidget {
  const _GeneralSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useDefault = ref.watch(useDefaultOneCompilerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Toggle between default API and your custom preset.'),
          value: useDefault,
          activeTrackColor: AppTheme.accentYellow.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.accentYellow,
          onChanged: (val) {
            ref.read(useDefaultOneCompilerProvider.notifier).toggle(val);
          },
        ),
      ],
    );
  }
}

class _CompilerPresetsTab extends ConsumerWidget {
  const _CompilerPresetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ref.watch(compilerPresetBoxProvider);

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box<CompilerPreset> presetBox, _) {
        final presets = presetBox.values.toList();
        final defaultId = ref.watch(defaultPresetProvider);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Preset'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    tooltip: 'Export All Presets',
                    onPressed: () async {
                      if (presets.isEmpty) return;
                      final List<Map<String, dynamic>> jsonList = presets.map((p) => p.toJson()).toList();
                      final jsonString = jsonEncode(jsonList);
                      final dir = await getTemporaryDirectory();
                      final file = File('${dir.path}/presets.json');
                      await file.writeAsString(jsonString);
                      await Share.shareXFiles([XFile(file.path)], text: 'Exported Presets');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Import Presets from JSON',
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );
                      if (result != null && result.files.single.path != null) {
                        try {
                          File file = File(result.files.single.path!);
                          String content = await file.readAsString();
                          List<dynamic> jsonList = jsonDecode(content);
                          for (var item in jsonList) {
                            final preset = CompilerPreset.fromJson(item);
                            // Generate new ID to avoid collisions
                            final newPreset = preset.copyWith(id: const Uuid().v4());
                            box.put(newPreset.id, newPreset);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presets imported successfully')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import presets: $e')));
                          }
                        }
                      }
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final preset = presets[index];
                  final isDefault = preset.id == defaultId;

                  return Card(
                    color: AppTheme.surfaceColor,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(preset.name),
                      subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDefault)
                            const Icon(Icons.check_circle, color: AppTheme.accentYellow),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'edit') {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                              } else if (val == 'duplicate') {
                                final newPreset = preset.copyWith(
                                  id: const Uuid().v4(),
                                  name: '${preset.name} (Copy)',
                                );
                                box.put(newPreset.id, newPreset);
                              } else if (val == 'delete') {
                                box.delete(preset.id);
                                if (isDefault) {
                                  ref.read(defaultPresetProvider.notifier).state = null;
                                }
                              } else if (val == 'setdefault') {
                                ref.read(defaultPresetProvider.notifier).state = preset.id;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'setdefault', child: Text('Set Default')),
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
