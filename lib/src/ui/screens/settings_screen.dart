import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/preset_provider.dart';
import '../../models/compiler_preset.dart';
import '../widgets/preset_editor_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final presetState = ref.watch(presetProvider);
    final notifier = ref.read(presetProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Compilers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Presets',
            onPressed: () {
              // Implementation later
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import Presets',
            onPressed: () {
              // Implementation later
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final sidebar = Container(
            width: isMobile ? constraints.maxWidth : 250,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use Default OneCompiler', style: TextStyle(fontSize: 14)),
                  value: presetState.useDefaultOneCompiler,
                  onChanged: (val) => notifier.toggleUseDefaultOneCompiler(val),
                  // ignore: deprecated_member_use
                  activeTrackColor: Theme.of(context).primaryColor.withOpacity(0.5),
                  // ignore: deprecated_member_use
                  activeColor: Theme.of(context).primaryColor,
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: presetState.presets.length,
                    itemBuilder: (context, index) {
                      final preset = presetState.presets[index];
                      return ListTile(
                        title: Text(preset.name, style: const TextStyle(fontSize: 14)),
                        selected: preset.id == presetState.activePresetId,
                        selectedColor: Theme.of(context).primaryColor,
                        onTap: () {
                          notifier.setActivePreset(preset.id);
                        },
                        trailing: preset.isPreloaded ? const Icon(Icons.lock, size: 16) : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      notifier.addPreset(
                        CompilerPreset(
                          id: UniqueKey().toString(),
                          name: 'New Preset',
                          endpointUrl: '',
                          httpMethod: 'POST',
                          authType: 'None',
                          authValue: '',
                          headers: {},
                          queryParams: {},
                          bodyTemplate: '{"code": "{code}"}',
                          stdoutPath: '',
                          stderrPath: '',
                          errorPath: '',
                          executionTimePath: '',
                          memoryPath: '',
                          isPreloaded: false,
                        )
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Preset'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                  ),
                ),
              ],
            ),
          );

          if (isMobile) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Presets'),
                      Tab(text: 'Editor'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        sidebar,
                        notifier.activePreset != null
                            ? PresetEditorWidget(preset: notifier.activePreset!)
                            : const Center(child: Text('Select a preset')),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              sidebar,
              Expanded(
                child: notifier.activePreset != null
                    ? PresetEditorWidget(preset: notifier.activePreset!)
                    : const Center(child: Text('Select a preset')),
              ),
            ],
          );
        },
      ),
    );
  }
}
