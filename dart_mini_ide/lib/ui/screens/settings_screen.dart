import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import '../../core/theme.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Custom Compiler Preset'),
            subtitle: const Text('Enable to use your own API configuration instead of OneCompiler default.'),
            value: settings.useCustomPreset,
            onChanged: (val) => notifier.toggleUseCustomPreset(val),
            activeTrackColor: AppTheme.accentYellow,
          ),
          const Divider(color: Colors.white12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.accentYellow),
                  onPressed: () => _editPreset(context, null),
                ),
              ],
            ),
          ),
          if (settings.presets.isEmpty)
             const Padding(padding: EdgeInsets.all(16), child: Text("No presets available.")),
          ...settings.presets.map((preset) {
            final isActive = preset.id == settings.activePresetId;
            return ListTile(
              title: Text(preset.name, style: TextStyle(color: isActive ? AppTheme.accentYellow : Colors.white)),
              subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive && settings.useCustomPreset) const Icon(Icons.check_circle, color: AppTheme.accentYellow),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editPreset(context, preset);
                      } else if (value == 'duplicate') {
                        notifier.addPreset(preset.copyWith(id: const Uuid().v4(), name: '${preset.name} (Copy)'));
                      } else if (value == 'delete') {
                        notifier.deletePreset(preset.id);
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                notifier.setActivePreset(preset.id);
                if (!settings.useCustomPreset) {
                   notifier.toggleUseCustomPreset(true);
                }
              },
            );
          }),
        ],
      ),
    );
  }

  void _editPreset(BuildContext context, CompilerPreset? preset) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PresetEditorScreen(preset: preset)),
    );
  }
}
