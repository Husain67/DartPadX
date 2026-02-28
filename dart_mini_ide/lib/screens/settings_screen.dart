import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'add_preset_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Compiler Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryAccent,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Toggle to use custom compiler presets.'),
            value: settingsState.useDefault,
            activeTrackColor: AppTheme.primaryAccent,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleUseDefault(val);
            },
          ),
          const Divider(color: AppTheme.dividerColor),
          if (!settingsState.useDefault) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Custom Presets',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddPresetScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Preset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...settingsState.presets.map((preset) {
              final isActive = preset.id == settingsState.activePresetId;
              return Card(
                color: isActive ? Colors.grey[900] : AppTheme.backgroundEnd,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(preset.name),
                  subtitle: Text(preset.endpointUrl, overflow: TextOverflow.ellipsis),
                  trailing: isActive
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryAccent)
                      : TextButton(
                          onPressed: () {
                            ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                          },
                          child: const Text('Set Active'),
                        ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddPresetScreen(presetToEdit: preset)),
                    );
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
