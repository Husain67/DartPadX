import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../providers/compiler_notifier.dart';
import '../../models/compiler_preset.dart';
import '../../theme/app_theme.dart';
import '../widgets/preset_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Compilers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Presets JSON',
            onPressed: () => _importPresets(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Presets JSON',
            onPressed: () => _exportPresets(context, ref),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text('Active Preset:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: compilerState.activePresetId,
                      dropdownColor: AppTheme.surfaceColor,
                      items: compilerState.presets.map((preset) {
                        return DropdownMenuItem<String>(
                          value: preset.id,
                          child: Text(preset.name + (preset.isDefault ? ' (Default)' : '')),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(compilerProvider.notifier).setActivePreset(val);
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PresetEditor()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: compilerState.presets.length,
                itemBuilder: (context, index) {
                  final preset = compilerState.presets[index];
                  return Card(
                    color: AppTheme.surfaceColor,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: ListTile(
                      title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(preset.endpointUrl.isNotEmpty ? preset.endpointUrl : 'No Endpoint URL', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Duplicate',
                            onPressed: () => ref.read(compilerProvider.notifier).duplicatePreset(preset.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'Edit',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PresetEditor(preset: preset)),
                              );
                            },
                          ),
                          if (!preset.isDefault)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(context, ref, preset.id),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: const Text('Are you sure you want to delete this preset?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(compilerProvider.notifier).deletePreset(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportPresets(BuildContext context, WidgetRef ref) {
    final jsonStr = ref.read(compilerProvider.notifier).exportPresets();
    Clipboard.setData(ClipboardData(text: jsonStr));
    Fluttertoast.showToast(msg: "Presets JSON copied to clipboard");
  }

  void _importPresets(BuildContext context, WidgetRef ref) {
    String jsonInput = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Presets'),
        content: TextField(
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Paste JSON here...',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => jsonInput = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              try {
                ref.read(compilerProvider.notifier).importPresets(jsonInput);
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: "Presets imported successfully");
              } catch (e) {
                Fluttertoast.showToast(msg: "Invalid JSON format");
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
