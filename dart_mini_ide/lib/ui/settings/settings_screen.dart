import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../providers/preset_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import 'preset_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload, color: Colors.white),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(presetState.presets),
          ),
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(ref),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Execution Provider',
              style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Turn off to use a custom compiler preset', style: TextStyle(color: Colors.white54)),
              value: settings.useDefaultOneCompiler,
              activeTrackColor: const Color(0xFFFACC15),
              onChanged: (val) => ref.read(settingsProvider.notifier).toggleUseDefaultOneCompiler(val),
            ),
            const Divider(color: Colors.white24, height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Compiler Presets',
                  style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                  },
                  icon: const Icon(Icons.add, size: 16, color: Colors.black),
                  label: const Text('New Preset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...presetState.presets.map((preset) => _buildPresetCard(context, ref, preset, settings)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(BuildContext context, WidgetRef ref, CompilerPreset preset, SettingsState settings) {
    final isSelected = !settings.useDefaultOneCompiler && settings.activeCustomPresetId == preset.id;
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? const Color(0xFFFACC15) : Colors.transparent, width: 1),
      ),
      child: ListTile(
        title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check_circle, color: isSelected ? const Color(0xFFFACC15) : Colors.white24),
              onPressed: () {
                ref.read(settingsProvider.notifier).toggleUseDefaultOneCompiler(false);
                ref.read(settingsProvider.notifier).setActiveCustomPreset(preset.id);
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: const Color(0xFF2A2A2A),
              onSelected: (val) {
                if (val == 'edit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                } else if (val == 'duplicate') {
                  ref.read(presetProvider.notifier).duplicatePreset(preset);
                } else if (val == 'delete') {
                  ref.read(presetProvider.notifier).deletePreset(preset.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Color(0xFFEF4444)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    final jsonList = presets.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/presets.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Presets JSON');
  }

  Future<void> _importPresets(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        for (var item in jsonList) {
          final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
          ref.read(presetProvider.notifier).addPreset(preset);
        }
        Fluttertoast.showToast(msg: 'Presets imported successfully');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to import presets');
      }
    }
  }
}
