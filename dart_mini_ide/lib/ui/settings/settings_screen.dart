import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

import 'preset_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white)),
            value: settings.useDefaultOneCompiler,
            activeColor: const Color(0xFFFACC15),
            onChanged: (val) {
              notifier.toggleDefaultCompiler(val);
            },
          ),
          const Divider(color: Colors.grey),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Custom Compiler Presets',
              style: TextStyle(color: Color(0xFFFACC15), fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (settings.useDefaultOneCompiler)
            const Text(
              'Custom presets are disabled while using default OneCompiler.',
              style: TextStyle(color: Colors.grey),
            )
          else ...[
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditor()));
              },
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add New Preset', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15)),
            ),
            const SizedBox(height: 16),
            ...settings.customPresets.map((preset) {
              final isActive = preset.id == settings.activePresetId;
              return Card(
                color: const Color(0xFF1a1a1a),
                child: ListTile(
                  title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(preset.url, style: const TextStyle(color: Colors.grey), maxLines: 1),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive)
                        const Icon(Icons.check_circle, color: Color(0xFFFACC15))
                      else
                        IconButton(
                          icon: const Icon(Icons.circle_outlined, color: Colors.grey),
                          onPressed: () => notifier.setActivePreset(preset.id),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditor(preset: preset)));
                        },
                      ),
                    ],
                  ),
                ),
              );
            })
          ],
        ],
      ),
    );
  }
}
