import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartmini_ide/src/features/settings/providers/compiler_provider.dart';
import 'package:dartmini_ide/src/features/settings/presentation/preset_editor.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            indicatorColor: Colors.yellow,
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Global'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalSettingsTab(),
            _PresetsSettingsTab(),
          ],
        ),
      ),
    );
  }
}

class _GlobalSettingsTab extends ConsumerWidget {
  const _GlobalSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Disables custom API execution and uses the reliable built-in OneCompiler API key.'),
          value: state.useDefaultOneCompiler,
          activeTrackColor: Colors.yellow.withValues(alpha: 0.3),
          activeThumbColor: Colors.yellow,
          onChanged: (val) {
            ref.read(compilerProvider.notifier).setUseDefaultOneCompiler(val);
          },
        ),
        if (!state.useDefaultOneCompiler)
          ListTile(
            title: const Text('Active Custom Preset'),
            subtitle: Text(state.activePreset?.name ?? 'None selected'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              DefaultTabController.of(context).animateTo(1);
            },
          ),
      ],
    );
  }
}

class _PresetsSettingsTab extends ConsumerWidget {
  const _PresetsSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PresetEditor(preset: null)),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Preset'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.presets.length,
            itemBuilder: (context, index) {
              final preset = state.presets[index];
              final isActive = preset.id == state.activePresetId;

              return ListTile(
                title: Text(preset.name),
                subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      const Icon(Icons.check_circle, color: Colors.green),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PresetEditor(preset: preset)),
                        );
                      },
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Activated preset: ${preset.name}')),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
