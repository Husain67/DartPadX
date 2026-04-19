import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme.dart';
import '../providers/settings_provider.dart';
import '../models/compiler_preset.dart';
import 'preset_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            indicatorColor: AppTheme.accentYellow,
            labelColor: AppTheme.accentYellow,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GeneralSettingsTab(),
            _PresetsTab(),
          ],
        ),
      ),
    );
  }
}

class _GeneralSettingsTab extends ConsumerWidget {
  const _GeneralSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Bypass custom preset and use built-in free compiler'),
          value: settings.useDefaultOneCompiler,
          activeTrackColor: AppTheme.accentYellow.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.accentYellow,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).toggleDefaultCompiler(val);
          },
        ),
        const Divider(color: Colors.white24),
        ListTile(
          title: const Text('Export Presets'),
          subtitle: const Text('Backup all custom API configurations to JSON'),
          trailing: const Icon(Icons.upload_file),
          onTap: () => _exportPresets(ref),
        ),
        ListTile(
          title: const Text('Import Presets'),
          subtitle: const Text('Restore custom APIs from JSON file'),
          trailing: const Icon(Icons.download),
          onTap: () => _importPresets(ref),
        ),
      ],
    );
  }

  Future<void> _exportPresets(WidgetRef ref) async {
     final presets = ref.read(settingsProvider).presets;
     final jsonStr = jsonEncode(presets.map((p) => p.toJson()).toList());
     final dir = await getTemporaryDirectory();
     final file = File('${dir.path}/dartmini_presets.json');
     await file.writeAsString(jsonStr);
     await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _importPresets(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(content);

        for (var item in decoded) {
            final p = CompilerPreset.fromJson(item as Map<String, dynamic>);
            // ensure imported presets are not marked as builtin accidentally unless they really are
            if (!p.isBuiltIn) {
                await ref.read(settingsProvider.notifier).savePreset(p);
            }
        }
        Fluttertoast.showToast(msg: "Imported successfully", backgroundColor: AppTheme.successGreen);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e", backgroundColor: AppTheme.errorRed);
    }
  }
}

class _PresetsTab extends ConsumerWidget {
  const _PresetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: settings.presets.length,
            itemBuilder: (context, index) {
              final preset = settings.presets[index];
              final isSelected = !settings.useDefaultOneCompiler && preset.id == settings.activePresetId;

              return ListTile(
                leading: Icon(
                  Icons.api,
                  color: isSelected ? AppTheme.accentYellow : Colors.white54,
                ),
                title: Text(preset.name),
                subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!preset.isBuiltIn)
                       IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () => ref.read(settingsProvider.notifier).duplicatePreset(preset.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                   ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                   ref.read(settingsProvider.notifier).toggleDefaultCompiler(false);
                   Fluttertoast.showToast(msg: "Set as active", backgroundColor: AppTheme.successGreen);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentYellow,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create Custom API Preset'),
            onPressed: () {
              // Create empty and navigate
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PresetEditorScreen(preset: null)),
              );
            },
          ),
        )
      ],
    );
  }
}
