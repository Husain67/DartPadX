import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import '../widgets/preset_editor_form.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: Color(0xFFFACC15),
              labelColor: Color(0xFFFACC15),
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: 'General'),
                Tab(text: 'Compiler Presets'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildGeneralTab(settings),
                  _buildPresetsTab(settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(SettingsState settings) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Turn off to use Custom API Presets'),
          value: settings.useDefaultCompiler,
          // ignore: deprecated_member_use
          activeColor: const Color(0xFFFACC15),
          onChanged: (val) {
            ref.read(settingsProvider.notifier).setUseDefaultCompiler(val);
          },
        ),
      ],
    );
  }

  Widget _buildPresetsTab(SettingsState settings) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: settings.presets.length,
            itemBuilder: (context, index) {
              final preset = settings.presets[index];
              final isActive = preset.id == settings.activePresetId;

              return ListTile(
                title: Text(preset.name, style: TextStyle(color: isActive ? const Color(0xFFFACC15) : Colors.white)),
                subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive)
                      TextButton(
                        onPressed: () {
                          ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                        },
                        child: const Text('Set Active'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white54),
                      onPressed: () => _editPreset(preset),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black),
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Preset'),
            onPressed: () => _editPreset(CompilerPreset.blank()),
          ),
        )
      ],
    );
  }

  void _editPreset(CompilerPreset preset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: PresetEditorForm(
            initialPreset: preset,
            onSave: (updated) {
              ref.read(settingsProvider.notifier).savePreset(updated);
              Navigator.pop(ctx);
            },
          ),
        ),
      ),
    );
  }
}
