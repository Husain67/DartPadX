import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/preset_provider.dart';
import '../models/preset_model.dart';
import '../theme.dart';
import '../widgets/preset_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(context, ref),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler'),
              subtitle: const Text('Toggle between built-in and custom APIs'),
              value: presetState.useOneCompiler,
              activeColor: AppTheme.primaryAccent, // ignore: deprecated_member_use
              onChanged: (val) {
                ref.read(presetProvider.notifier).setUseOneCompiler(val);
              },
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: presetState.presets.length,
                itemBuilder: (context, index) {
                  final preset = presetState.presets[index];
                  final isActive = !presetState.useOneCompiler && preset.id == presetState.activePresetId;

                  return ListTile(
                    title: Text(preset.name),
                    subtitle: Text(preset.url),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive)
                          const Icon(Icons.check_circle, color: AppTheme.primaryAccent),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white70),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PresetEditorScreen(preset: preset),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(presetProvider.notifier).setActivePreset(preset.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PresetEditorScreen(preset: PresetModel(name: 'New Preset', url: '')),
            ),
          );
        },
      ),
    );
  }

  void _exportPresets(BuildContext context, WidgetRef ref) {
    final presets = ref.read(presetProvider).presets;
    final List<Map<String, dynamic>> presetJson = presets.map((p) => {
      'name': p.name,
      'url': p.url,
      'method': p.method,
      'authType': p.authType,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'bodyTemplate': p.bodyTemplate,
      'responseMappings': p.responseMappings,
    }).toList();

    final jsonString = jsonEncode(presetJson);
    Clipboard.setData(ClipboardData(text: jsonString));
    Fluttertoast.showToast(msg: "Presets JSON copied to clipboard");
  }

  void _importPresets(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      try {
        final List<dynamic> parsed = jsonDecode(data.text!);
        for (var item in parsed) {
          final preset = PresetModel(
            name: item['name'] ?? 'Imported Preset',
            url: item['url'] ?? '',
            method: item['method'] ?? 'POST',
            authType: item['authType'] ?? 'None',
            headers: Map<String, String>.from(item['headers'] ?? {}),
            queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
            bodyTemplate: item['bodyTemplate'] ?? '',
            responseMappings: Map<String, String>.from(item['responseMappings'] ?? {}),
          );
          ref.read(presetProvider.notifier).addPreset(preset);
        }
        Fluttertoast.showToast(msg: "Presets imported successfully");
      } catch (e) {
        Fluttertoast.showToast(msg: "Invalid preset JSON format");
      }
    }
  }
}
