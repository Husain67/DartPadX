import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/preset_provider.dart';
import '../theme/app_theme.dart';
import 'preset_editor_screen.dart'; // To be implemented
import 'examples_screen.dart'; // To be implemented

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.appBarColor,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            _buildGlobalToggle(ref, presetState),
            const Divider(color: Colors.grey),
            Expanded(
              child: ListView.builder(
                itemCount: presetState.presets.length,
                itemBuilder: (context, index) {
                  final preset = presetState.presets[index];
                  final isActive = preset.id == presetState.activePresetId && !presetState.useDefaultCompiler;
                  return ListTile(
                    title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(preset.endpointUrl.isEmpty ? 'No endpoint' : preset.endpointUrl,
                        style: const TextStyle(color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          const Icon(Icons.check_circle, color: AppTheme.primaryAccent),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PresetEditorScreen(preset: preset),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            _showDeleteConfirmation(context, ref, preset.id);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                       ref.read(presetProvider.notifier).setActivePreset(preset.id);
                       if (presetState.useDefaultCompiler) {
                         ref.read(presetProvider.notifier).toggleUseDefaultCompiler(false);
                       }
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExamplesScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('View Examples'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PresetEditorScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Custom API'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalToggle(WidgetRef ref, PresetState state) {
    return SwitchListTile(
      title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
      subtitle: const Text('Fast, reliable, pre-configured.', style: TextStyle(color: Colors.grey)),
      activeThumbColor: AppTheme.primaryAccent,
      value: state.useDefaultCompiler,
      onChanged: (val) {
        ref.read(presetProvider.notifier).toggleUseDefaultCompiler(val);
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String presetId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Preset'),
          content: const Text('Are you sure you want to delete this custom API?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(presetProvider.notifier).deletePreset(presetId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
