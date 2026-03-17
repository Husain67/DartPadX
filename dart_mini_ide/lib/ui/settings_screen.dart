import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../providers.dart';
import '../models.dart';
import '../theme.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(context, ref),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler API', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: const Text('Turn off to use custom presets', style: TextStyle(color: AppTheme.textSecondary)),
              value: settings.useDefaultOneCompiler,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(val);
              },
              activeColor: AppTheme.primaryAccent,
            ),
            const Divider(color: Colors.white24, height: 32),
            const Text('Custom Compiler Presets', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...settings.presets.map((preset) => _buildPresetTile(context, ref, preset, settings)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create New Preset'),
              onPressed: () {
                final newPreset = CompilerPreset(
                  id: uuid.v4(),
                  name: 'New Preset',
                  endpointUrl: 'https://',
                  httpMethod: 'POST',
                  authType: 'None',
                  headers: {},
                  queryParams: {},
                  bodyTemplate: '{}',
                  stdoutPath: '',
                  stderrPath: '',
                  errorPath: '',
                  executionTimePath: '',
                  memoryPath: '',
                );
                Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: newPreset, isNew: true)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetTile(BuildContext context, WidgetRef ref, CompilerPreset preset, SettingsState settings) {
    final isActive = settings.activePresetId == preset.id && !settings.useDefaultOneCompiler;
    return Card(
      color: AppTheme.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isActive ? AppTheme.primaryAccent : Colors.transparent),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(preset.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        subtitle: Text(preset.endpointUrl, style: const TextStyle(color: AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) const Icon(Icons.check_circle, color: AppTheme.primaryAccent),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
              color: AppTheme.backgroundLight,
              onSelected: (value) {
                if (value == 'set_active') {
                  ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                  ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
                } else if (value == 'edit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                } else if (value == 'duplicate') {
                  ref.read(settingsProvider.notifier).duplicatePreset(preset);
                } else if (value == 'delete') {
                  ref.read(settingsProvider.notifier).deletePreset(preset.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'set_active', child: Text('Set Active')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
        },
      ),
    );
  }

  Future<void> _exportPresets(BuildContext context, WidgetRef ref) async {
    final presets = ref.read(settingsProvider).presets;
    final jsonList = presets.map((p) => {
      'name': p.name,
      'endpointUrl': p.endpointUrl,
      'httpMethod': p.httpMethod,
      'authType': p.authType,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'bodyTemplate': p.bodyTemplate,
      'stdoutPath': p.stdoutPath,
      'stderrPath': p.stderrPath,
      'errorPath': p.errorPath,
      'executionTimePath': p.executionTimePath,
      'memoryPath': p.memoryPath,
    }).toList();

    try {
      final jsonStr = jsonEncode(jsonList);
      final dir = await getTemporaryDirectory();
      final file = File('\${dir.path}/presets_export.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], text: 'My DartMini IDE Presets');
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: \$e");
    }
  }

  Future<void> _importPresets(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(content);

        for (var item in jsonList) {
          final p = CompilerPreset(
            id: uuid.v4(),
            name: item['name'] ?? 'Imported Preset',
            endpointUrl: item['endpointUrl'] ?? '',
            httpMethod: item['httpMethod'] ?? 'POST',
            authType: item['authType'] ?? 'None',
            headers: Map<String, String>.from(item['headers'] ?? {}),
            queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
            bodyTemplate: item['bodyTemplate'] ?? '{}',
            stdoutPath: item['stdoutPath'] ?? '',
            stderrPath: item['stderrPath'] ?? '',
            errorPath: item['errorPath'] ?? '',
            executionTimePath: item['executionTimePath'] ?? '',
            memoryPath: item['memoryPath'] ?? '',
          );
          ref.read(settingsProvider.notifier).addPreset(p);
        }
        Fluttertoast.showToast(msg: "\${jsonList.length} presets imported successfully.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed. Invalid JSON.");
    }
  }
}
