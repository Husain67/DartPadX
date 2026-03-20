import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Compiler Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Use Default Compiler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Built-in OneCompiler API. Turn off to use custom presets.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  activeColor: const Color(0xFFFACC15),
                  value: compilerState.useDefault,
                  onChanged: (val) {
                    ref.read(compilerProvider.notifier).toggleUseDefault(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom Presets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                },
                icon: const Icon(Icons.add, color: Colors.black, size: 16),
                label: const Text('Add New', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (compilerState.presets.isEmpty)
            const Center(child: Text('No custom presets found.', style: TextStyle(color: Colors.white54))),
          ...compilerState.presets.map((preset) => _buildPresetCard(preset, compilerState)),

          const SizedBox(height: 32),
          const Text('Data Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final presetsJson = jsonEncode(compilerState.presets.map((p) => p.toJson()).toList());
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/presets.json');
                    await file.writeAsString(presetsJson);
                    await Share.shareXFiles([XFile(file.path)], text: 'Exported DartMini Presets');
                  },
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text('Export JSON', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
                    if (result != null && result.files.single.path != null) {
                      try {
                        final file = File(result.files.single.path!);
                        final content = await file.readAsString();
                        final List<dynamic> jsonList = jsonDecode(content);
                        for (var item in jsonList) {
                          final p = CompilerPreset.fromJson(item as Map<String, dynamic>);
                          ref.read(compilerProvider.notifier).addPreset(p);
                        }
                        Fluttertoast.showToast(msg: "Imported ${jsonList.length} presets");
                      } catch (e) {
                        Fluttertoast.showToast(msg: "Import failed: Invalid JSON");
                      }
                    }
                  },
                  icon: const Icon(Icons.download, color: Colors.black),
                  label: const Text('Import JSON', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPresetCard(CompilerPreset preset, CompilerState state) {
    final isSelected = state.activePresetId == preset.id && !state.useDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFFFACC15) : Colors.white12, width: isSelected ? 2 : 1),
      ),
      child: ListTile(
        onTap: () {
          if (!state.useDefault) {
             ref.read(compilerProvider.notifier).setActivePreset(preset.id);
          }
        },
        title: Text(preset.platformName, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
              onPressed: () => ref.read(compilerProvider.notifier).duplicatePreset(preset),
              tooltip: 'Duplicate',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
              },
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
