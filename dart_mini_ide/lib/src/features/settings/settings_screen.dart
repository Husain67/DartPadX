import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import '../../ui/theme/theme_constants.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final presets = ref.watch(presetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler API'),
            subtitle: const Text('Toggle OFF to use custom API presets'),
            value: settings.useDefaultApi,
            activeColor: ThemeConstants.primaryAccent,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setUseDefaultApi(val);
            },
          ),
          if (!settings.useDefaultApi) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Compiler Presets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeConstants.primaryAccent),
              ),
            ),
            ...presets.map((preset) {
              final isSelected = settings.selectedPresetId == preset.id;
              return ListTile(
                title: Text(preset.platformName),
                subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) const Icon(Icons.check_circle, color: ThemeConstants.primaryAccent),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PresetEditorScreen(preset: preset),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).setSelectedPresetId(preset.id);
                },
              );
            }).toList(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New Preset'),
                onPressed: () {
                  final newPreset = CompilerPreset.create(
                    platformName: 'New Preset',
                    endpointUrl: 'https://',
                    httpMethod: 'POST',
                    authType: 'None',
                    authValue: '',
                    headers: {},
                    queryParams: {},
                    requestBodyTemplate: '{\n  "code": "{code}"\n}',
                    stdoutPath: '',
                    stderrPath: '',
                    errorPath: '',
                    executionTimePath: '',
                    memoryPath: '',
                  );
                  ref.read(presetsProvider.notifier).addPreset(newPreset);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PresetEditorScreen(preset: newPreset),
                    ),
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }
}
