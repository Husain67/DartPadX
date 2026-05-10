import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final presets = ref.read(settingsProvider.notifier).getAllPresets();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Compilers'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _exportPresets(context, ref),
                icon: const Icon(Icons.upload_file),
                label: const Text('Export Presets'),
              ),
              ElevatedButton.icon(
                onPressed: () => _importPresets(context, ref),
                icon: const Icon(Icons.download),
                label: const Text('Import Presets'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Global Execution API',
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Recommended for instant stable execution'),
            value: settings.useDefaultOneCompiler,
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5), activeThumbColor: AppTheme.primaryColor,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(val);
            },
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Custom Compiler Presets',
                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PresetEditorScreen(preset: null)),
                  ).then((_) => ref.refresh(settingsProvider));
                },
              )
            ],
          ),
          ...presets.map((preset) {
            final isActive = !settings.useDefaultOneCompiler && settings.activePresetId == preset.id;
            return Card(
              color: isActive ? Colors.white10 : AppTheme.backgroundColor2,
              child: ListTile(
                title: Text(preset.name),
                subtitle: Text(preset.url.isEmpty ? 'Setup Required' : preset.url),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)),
                        ).then((_) => ref.refresh(settingsProvider)); // Refresh to reflect updates
                      },
                    ),
                  ],
                ),
                onTap: () {
                   ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _exportPresets(BuildContext context, WidgetRef ref) {
    final json = ref.read(settingsProvider.notifier).exportPresets();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exported JSON'),
        content: SingleChildScrollView(
          child: SelectableText(json),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importPresets(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import JSON'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Paste presets JSON here...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).importPresets(controller.text);
              Navigator.pop(ctx);
              // ignore: unused_result
              ref.refresh(settingsProvider);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
