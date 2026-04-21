
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import '../providers/settings_provider.dart';
import '../providers/compiler_preset_provider.dart';
import '../utils/theme.dart';
import '../models/compiler_preset.dart';
import '../utils/file_actions.dart';
import 'preset_edit_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useDefault = ref.watch(useDefaultOneCompilerProvider);
    final presets = ref.watch(compilerPresetProvider);
    final activeId = ref.watch(activePresetIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings', style: TextStyle(color: Colors.white))),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.bgDarkStart, AppTheme.bgDarkEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white)),
              value: useDefault,
              onChanged: (_) => ref.read(useDefaultOneCompilerProvider.notifier).toggle(),
              activeTrackColor: AppTheme.accentYellow.withValues(alpha: 0.5),
              activeThumbColor: AppTheme.accentYellow,
            ),
            const Divider(color: Colors.white24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentYellow)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.file_download, color: Colors.white),
                      tooltip: 'Export',
                      onPressed: () {
                        final jsonStr = ref.read(compilerPresetProvider.notifier).exportPresets();
                        FileActions.copyToClipboard(jsonStr);
                        Fluttertoast.showToast(msg: 'Presets JSON copied to clipboard');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_upload, color: Colors.white),
                      tooltip: 'Import',
                      onPressed: () => _showImportDialog(context, ref),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppTheme.accentYellow),
                      tooltip: 'Add Blank',
                      onPressed: () {
                        final newPreset = CompilerPreset(
                          id: const Uuid().v4(),
                          name: 'New Preset',
                          url: 'https://',
                          method: 'POST',
                          authType: 'None',
                          authValue: '',
                          headers: [],
                          queryParams: [],
                          bodyTemplate: '{}',
                          responseMappings: {},
                        );
                        ref.read(compilerPresetProvider.notifier).addPreset(newPreset);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!useDefault)
              ...presets.map((p) => ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(p.url, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                leading: activeId == p.id
                  ? const Icon(Icons.check_circle, color: AppTheme.accentYellow)
                  : const Icon(Icons.circle_outlined, color: Colors.white54),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (val) {
                    if (val == 'edit') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditScreen(presetId: p.id)));
                    } else if (val == 'duplicate') {
                      ref.read(compilerPresetProvider.notifier).duplicatePreset(p);
                    } else if (val == 'delete') {
                      ref.read(compilerPresetProvider.notifier).deletePreset(p.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
                onTap: () => ref.read(activePresetIdProvider.notifier).set(p.id),
              )),
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
        title: const Text('Import Presets JSON'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Paste JSON here...'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(compilerPresetProvider.notifier).importPresets(controller.text);
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: 'Presets imported');
            },
            child: const Text('Import', style: TextStyle(color: AppTheme.accentYellow)),
          ),
        ],
      ),
    );
  }
}
