import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/preset_provider.dart';
import '../models/compiler_preset.dart';
import '../theme.dart';
import '../widgets/preset_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetState = ref.watch(presetProvider);
    final notifier = ref.read(presetProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.gradientStart,
      appBar: AppBar(title: const Text('Settings')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: AppTheme.primaryAccent,
              labelColor: AppTheme.primaryAccent,
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
                        title: const Text('Use Default OneCompiler API'),
                        subtitle: const Text('Toggle to use custom presets instead.'),
                        activeColor: AppTheme.primaryAccent, // ignore: deprecated_member_use
                        value: presetState.useDefault,
                        // ignore: deprecated_member_use
                                      // ignore: deprecated_member_use
                                      onChanged: (val) {
                          notifier.setUseDefault(val);
                        },
                      )
                    ],
                  ),
                  // Compiler Presets Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                                                        ElevatedButton.icon(
                              onPressed: () {
                                final data = notifier.exportPresets();
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Export Presets'),
                                    content: SelectableText(data),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                                    ]
                                  )
                                );
                              },
                              icon: const Icon(Icons.upload, color: Colors.black),
                              label: const Text('Export', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                String jsonStr = '';
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Import Presets'),
                                    content: TextField(
                                      onChanged: (v) => jsonStr = v,
                                      maxLines: 4,
                                      decoration: const InputDecoration(hintText: 'Paste JSON array here'),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () {
                                          notifier.importPresets(jsonStr);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Import')
                                      ),
                                    ]
                                  )
                                );
                              },
                              icon: const Icon(Icons.download, color: Colors.black),
                              label: const Text('Import', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (ctx) => PresetEditor(
                                  initialPreset: CompilerPreset(name: 'New Preset', endpointUrl: ''),
                                  onSave: (p) => notifier.addPreset(p),
                                )));
                              },
                              icon: const Icon(Icons.add, color: Colors.black),
                              label: const Text('Add Preset', style: TextStyle(color: Colors.black)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: presetState.presets.length,
                          itemBuilder: (context, index) {
                            final preset = presetState.presets[index];

                            return ListTile(
                              title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!presetState.useDefault)
                                    Radio<String>(
                                      value: preset.id,
                                      // ignore: deprecated_member_use
                                      groupValue: presetState.selectedPresetId,
                                      activeColor: AppTheme.primaryAccent,
                                      // ignore: deprecated_member_use
                                      onChanged: (val) {
                                        if (val != null) notifier.setSelectedPreset(val);
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (ctx) => PresetEditor(
                                        initialPreset: preset,
                                        onSave: (p) => notifier.updatePreset(p),
                                      )));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => notifier.deletePreset(preset.id),
                                  ),
                                ],
                              ),
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
