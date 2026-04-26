import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/preset_provider.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Execution Configuration',
            style: TextStyle(
                color: Color(0xFFFACC15),
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Uses the built-in RapidAPI OneCompiler key.'),
            value: settingsState.useDefaultOneCompiler,
            activeTrackColor: const Color(0xFFFACC15).withValues(alpha: 0.5),
            activeThumbColor: const Color(0xFFFACC15),
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(val);
            },
          ),
          const Divider(height: 32, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Compiler Presets',
                style: TextStyle(
                    color: Color(0xFFFACC15),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text('New', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PresetEditorScreen(preset: null),
                    ),
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          if (presetState.presets.isEmpty)
            const Text('No presets available.',
                style: TextStyle(color: Colors.white54))
          else
            ...presetState.presets.map((preset) {
              final isActive = preset.id == presetState.activePresetId;
              return Card(
                color: const Color(0xFF1a1a1a),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isActive && !settingsState.useDefaultOneCompiler
                        ? const Color(0xFFFACC15)
                        : Colors.white12,
                    width: isActive && !settingsState.useDefaultOneCompiler ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(preset.platformName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${preset.httpMethod} ${preset.endpointUrl}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (preset.isReadOnly)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.lock, size: 16, color: Colors.white30),
                        ),
                      PopupMenuButton<String>(
                        color: const Color(0xFF121212),
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) {
                          if (val == 'select') {
                            ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
                            ref.read(presetProvider.notifier).setActivePreset(preset.id);
                          } else if (val == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PresetEditorScreen(preset: preset),
                              ),
                            );
                          } else if (val == 'duplicate') {
                            ref.read(presetProvider.notifier).duplicatePreset(preset);
                          } else if (val == 'delete') {
                            ref.read(presetProvider.notifier).deletePreset(preset.id);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'select',
                            child: Text('Set Active'),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(preset.isReadOnly ? 'View' : 'Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate'),
                          ),
                          if (!preset.isReadOnly)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
                    ref.read(presetProvider.notifier).setActivePreset(preset.id);
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
