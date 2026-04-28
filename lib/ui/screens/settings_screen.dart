import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/settings_provider.dart';
import '../../providers/compiler_provider.dart';
import '../../models/compiler_preset.dart';
import '../../theme/app_theme.dart';
import 'preset_editor_screen.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _exportPresets(BuildContext context, WidgetRef ref) {
    final presets = ref.read(compilerProvider).presets;
    final jsonStr = jsonEncode(presets.map((p) => p.toJson()).toList());
    Clipboard.setData(ClipboardData(text: jsonStr));
    Fluttertoast.showToast(msg: 'Presets JSON copied to clipboard', backgroundColor: Colors.green);
  }

  void _importPresets(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (c) {
        String jsonInput = '';
        return AlertDialog(
          title: const Text('Import Presets (JSON)'),
          content: TextField(
            maxLines: 5,
            decoration: const InputDecoration(hintText: '[{"name": ...}]'),
            onChanged: (val) => jsonInput = val,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                try {
                  final List<dynamic> parsed = jsonDecode(jsonInput);
                  for (var item in parsed) {
                    final p = CompilerPreset.fromJson(item as Map<String, dynamic>);
                    ref.read(compilerProvider.notifier).savePreset(p);
                  }
                  Fluttertoast.showToast(msg: 'Imported successfully', backgroundColor: Colors.green);
                  Navigator.pop(c);
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Invalid JSON', backgroundColor: Colors.red);
                }
              },
              child: const Text('Import'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & API')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler (Safe)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Turn off to use the Custom Compiler API System below.'),
            value: settings.useDefaultOneCompiler,
            activeTrackColor: AppTheme.primaryAccent.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.primaryAccent,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleUseDefaultOneCompiler(val);
            },
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compiler Presets', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.upload_file), tooltip: 'Export JSON', onPressed: () => _exportPresets(context, ref)),
                  IconButton(icon: const Icon(Icons.download), tooltip: 'Import JSON', onPressed: () => _importPresets(context, ref)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                    },
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          ...compilerState.presets.map((preset) {
            final isActive = !settings.useDefaultOneCompiler && compilerState.activePresetId == preset.id;
            return Card(
              color: isActive ? AppTheme.primaryAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isActive ? AppTheme.primaryAccent : Colors.transparent, width: 1),
                borderRadius: BorderRadius.circular(8)
              ),
              child: ListTile(
                title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive && !settings.useDefaultOneCompiler)
                      TextButton(
                        onPressed: () => ref.read(compilerProvider.notifier).setActivePreset(preset.id),
                        child: const Text('Set Active'),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                        } else if (val == 'duplicate') {
                          ref.read(compilerProvider.notifier).duplicatePreset(preset.id);
                        } else if (val == 'delete') {
                          ref.read(compilerProvider.notifier).deletePreset(preset.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    )
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
