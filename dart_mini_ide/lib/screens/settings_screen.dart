import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/compiler_provider.dart';
import '../theme.dart';
import 'preset_editor_screen.dart';
import 'examples_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
              },
              icon: const Icon(Icons.library_books, color: Colors.black),
              label: const Text('Examples Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentYellow,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Compiler Settings',
              style: TextStyle(color: AppTheme.accentYellow, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Use Default OneCompiler'),
              subtitle: const Text('If off, uses the selected custom preset.'),
              value: compilerState.useDefaultOneCompiler,
              activeTrackColor: AppTheme.accentYellow,
              onChanged: (val) {
                ref.read(compilerProvider.notifier).toggleUseDefault(val);
              },
            ),

            const Divider(color: Colors.white24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custom Presets', style: TextStyle(color: Colors.white, fontSize: 16)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        _showImportDialog(context, ref);
                      },
                      child: const Text('Import'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final jsonStr = ref.read(compilerProvider.notifier).exportPresets();
                        await Clipboard.setData(ClipboardData(text: jsonStr));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presets exported to clipboard')));
                      },
                      child: const Text('Export'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppTheme.accentYellow),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            ...compilerState.presets.map((preset) {
              final isSelected = preset.id == compilerState.selectedPresetId;
              return Card(
                color: isSelected && !compilerState.useDefaultOneCompiler ? Colors.white12 : Colors.black45,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isSelected && !compilerState.useDefaultOneCompiler ? AppTheme.accentYellow : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(preset.platformName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                        onPressed: () => ref.read(compilerProvider.notifier).duplicatePreset(preset),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(compilerProvider.notifier).setSelectedPreset(preset.id);
                  },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import JSON'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Paste JSON here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(compilerProvider.notifier).importPresets(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
