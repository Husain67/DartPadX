import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler API Settings'),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              activeTrackColor: AppTheme.primaryYellow,
              title: const Text('Use Default OneCompiler'),
              subtitle: const Text('Built-in zero config API'),
              value: settings.useDefaultOneCompiler,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).toggleUseDefault(val);
              },
            ),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custom Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                  },
                  icon: const Icon(Icons.add, color: AppTheme.primaryYellow),
                  label: const Text('New', style: TextStyle(color: AppTheme.primaryYellow)),
                )
              ],
            ),
            const SizedBox(height: 8),
            ...settings.presets.map((preset) {
              final isSelected = !settings.useDefaultOneCompiler && settings.activePresetId == preset.id;
              return Card(
                color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.black45,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isSelected ? AppTheme.primaryYellow : Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) async {
                      if (val == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                      } else if (val == 'select') {
                        await ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                        await ref.read(settingsProvider.notifier).toggleUseDefault(false);
                      } else if (val == 'duplicate') {
                        ref.read(settingsProvider.notifier).duplicatePreset(preset);
                      } else if (val == 'delete') {
                        ref.read(settingsProvider.notifier).deletePreset(preset.id);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'select', child: Text('Set as Active')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            const Text('Backup & Restore', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final jsonStr = ref.read(settingsProvider.notifier).exportPresetsJson();
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      Fluttertoast.showToast(msg: 'Presets JSON copied to clipboard');
                    },
                    child: const Text('Export JSON'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data != null && data.text != null) {
                        try {
                          await ref.read(settingsProvider.notifier).importPresetsJson(data.text!);
                          Fluttertoast.showToast(msg: 'Presets imported successfully');
                        } catch (e) {
                          Fluttertoast.showToast(msg: 'Invalid JSON format');
                        }
                      }
                    },
                    child: const Text('Import JSON'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
