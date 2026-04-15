import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/preset_provider.dart';
import '../providers/settings_provider.dart';
import 'preset_editor_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final presets = ref.watch(presetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Global Settings
          const Text('Compiler Settings', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Uses built-in API key. Turn off to use Custom Presets.', style: TextStyle(color: Colors.white54)),
            value: settings.useDefaultOneCompiler,
            activeTrackColor: const Color(0xFFFACC15),
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(val);
            },
          ),
          const Divider(color: Colors.white12, height: 32),

          // Presets Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom API Presets', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white70),
                    tooltip: 'Export Presets',
                    onPressed: () => _exportPresets(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload, color: Colors.white70),
                    tooltip: 'Import Presets',
                    onPressed: () => _importPresets(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),

          // Presets List
          ...presets.map((preset) {
            final isSelected = settings.selectedPresetId == preset.id && !settings.useDefaultOneCompiler;
            return Card(
              color: const Color(0xFF151515),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFFACC15) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: const Color(0xFF252525),
                  onSelected: (val) {
                    if (val == 'select') {
                      ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
                      ref.read(settingsProvider.notifier).setSelectedPresetId(preset.id);
                      Fluttertoast.showToast(msg: "Selected ${preset.name}");
                    } else if (val == 'edit') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                    } else if (val == 'duplicate') {
                      ref.read(presetProvider.notifier).duplicatePreset(preset);
                      Fluttertoast.showToast(msg: "Preset duplicated");
                    } else if (val == 'delete') {
                      ref.read(presetProvider.notifier).deletePreset(preset.id);
                      Fluttertoast.showToast(msg: "Preset deleted");
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'select', child: Text('Set Active', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _exportPresets(BuildContext context, WidgetRef ref) async {
    try {
      final json = ref.read(presetProvider.notifier).exportPresets();
      Fluttertoast.showToast(msg: "Exporting to Share dialog...");
      Share.share('DartMini IDE Presets JSON:\n\n$json');
    } catch (e) {
      Fluttertoast.showToast(msg: "Export Failed");
    }
  }

  Future<void> _importPresets(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        ref.read(presetProvider.notifier).importPresets(content);
        Fluttertoast.showToast(msg: "Presets Imported");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import Failed");
    }
  }
}
