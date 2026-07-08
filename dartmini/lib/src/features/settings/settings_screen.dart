import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import 'edit_preset_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _exportPresets(List<CompilerPreset> presets) async {
    try {
      final jsonList = presets.map((p) => {
        'id': p.id,
        'name': p.name,
        'endpoint': p.endpoint,
        'method': p.method,
        'authType': p.authType,
        'authValue': p.authValue,
        'headers': p.headers,
        'queryParams': p.queryParams,
        'requestBodyTemplate': p.requestBodyTemplate,
        'stdoutPath': p.stdoutPath,
        'stderrPath': p.stderrPath,
        'errorPath': p.errorPath,
        'executionTimePath': p.executionTimePath,
        'memoryPath': p.memoryPath,
      }).toList();

      final jsonString = jsonEncode(jsonList);

      Directory? dir;
      if (Platform.isAndroid) {
        dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null) {
        final path = '${dir.path}/dartmini_presets.json';
        final file = File(path);
        await file.writeAsString(jsonString);
        Fluttertoast.showToast(msg: 'Presets exported to $path');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Export failed: $e');
    }
  }

  void _importPresets(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
        final content = utf8.decode(result.files.first.bytes!);
        final List<dynamic> jsonList = jsonDecode(content);

        for (var json in jsonList) {
          final preset = CompilerPreset(
            id: json['id'],
            name: json['name'],
            endpoint: json['endpoint'],
            method: json['method'],
            authType: json['authType'],
            authValue: json['authValue'],
            headers: Map<String, String>.from(json['headers']),
            queryParams: Map<String, String>.from(json['queryParams']),
            requestBodyTemplate: json['requestBodyTemplate'],
            stdoutPath: json['stdoutPath'],
            stderrPath: json['stderrPath'],
            errorPath: json['errorPath'],
            executionTimePath: json['executionTimePath'],
            memoryPath: json['memoryPath'],
          );
          ref.read(settingsProvider.notifier).addPreset(preset);
        }
        Fluttertoast.showToast(msg: 'Presets imported successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Import failed: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('Settings & Compilers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(settingsState.presets),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPresetScreen()));
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: settingsState.presets.length,
        itemBuilder: (context, index) {
          final preset = settingsState.presets[index];
          final isActive = preset.id == settingsState.activePresetId;

          return Card(
            color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFF0A0A0A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActive ? const Color(0xFFFACC15) : const Color(0xFF333333),
                width: isActive ? 2 : 1,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(preset.endpoint, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    const Icon(Icons.check_circle, color: Color(0xFFFACC15))
                  else
                    TextButton(
                      onPressed: () => ref.read(settingsProvider.notifier).setActivePreset(preset.id),
                      child: const Text('Set Active', style: TextStyle(color: Colors.white54)),
                    ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                      if (preset.id != 'onecompiler_default')
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => EditPresetScreen(presetId: preset.id)));
                      } else if (value == 'duplicate') {
                        ref.read(settingsProvider.notifier).duplicatePreset(preset.id);
                      } else if (value == 'delete') {
                        ref.read(settingsProvider.notifier).deletePreset(preset.id);
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => EditPresetScreen(presetId: preset.id)));
              },
            ),
          );
        },
      ),
    );
  }
}
