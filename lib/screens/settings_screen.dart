import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import '../providers/settings_provider.dart';
import '../providers/compiler_provider.dart';
import '../theme/app_theme.dart';
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
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GeneralTab(),
            _CompilerPresetsTab(),
          ],
        ),
      ),
    );
  }
}

class _GeneralTab extends ConsumerWidget {
  const _GeneralTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Disables custom API selection'),
          value: settings.useDefaultOneCompiler,
          activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          // ignore: deprecated_member_use
          activeColor: AppTheme.primaryColor,
          // ignore: deprecated_member_use
                        onChanged: (v) {
            ref.read(settingsProvider.notifier).toggleUseDefaultOneCompiler(v);
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
    final compilerState = ref.watch(compilerProvider);
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        if (settings.useDefaultOneCompiler)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.redAccent.withValues(alpha: 0.2),
            child: const Text('Disable "Use Default OneCompiler" in General to use custom presets.', style: TextStyle(color: Colors.redAccent)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                },
                icon: const Icon(Icons.add),
                label: const Text('New'),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: compilerState.presets.length,
            itemBuilder: (context, index) {
              final preset = compilerState.presets[index];
              final _ = compilerState.activePresetId == preset.id; // suppress unused
              return ListTile(
                title: Text(preset.name),
                subtitle: Text(preset.endpointUrl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!settings.useDefaultOneCompiler)
                      Radio<String>(
                        value: preset.id,
                        // ignore: deprecated_member_use
                        groupValue: compilerState.activePresetId,
                        // ignore: deprecated_member_use
          activeColor: AppTheme.primaryColor,
                        // ignore: deprecated_member_use
                        onChanged: (v) {
                          if (v != null) ref.read(compilerProvider.notifier).setActivePreset(v);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                         final duplicate = preset.copyWith(id: const Uuid().v4(), name: '\${preset.name} (Copy)');
                         ref.read(compilerProvider.notifier).addPreset(duplicate);
                         Fluttertoast.showToast(msg: "Preset duplicated");
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () {
                         ref.read(compilerProvider.notifier).deletePreset(preset.id);
                         Fluttertoast.showToast(msg: "Preset deleted");
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
