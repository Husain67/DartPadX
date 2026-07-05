import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/theme.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import 'preset_edit_screen.dart';

class CompilerPresetsScreen extends ConsumerWidget {
  const CompilerPresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PresetEditScreen(
                    preset: CompilerPreset(name: 'New Preset', endpointUrl: ''),
                    isNew: true,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: state.presets.length,
        itemBuilder: (context, index) {
          final preset = state.presets[index];
          final isActive = state.activePreset.id == preset.id;

          return ListTile(
            leading: Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              color: isActive ? AppTheme.primaryAccent : AppTheme.textMuted,
            ),
            title: Text(preset.name),
            subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PresetEditScreen(preset: preset),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: state.presets.length > 1 ? () {
                    ref.read(compilerProvider.notifier).deletePreset(preset.id);
                  } : null,
                ),
              ],
            ),
            onTap: () {
              ref.read(compilerProvider.notifier).setActivePreset(preset.id);
            },
          );
        },
      ),
    );
  }

  void _exportPresets(BuildContext context, WidgetRef ref) {
    final presets = ref.read(compilerProvider).presets;
    final data = presets.map((p) => {
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

    final jsonStr = jsonEncode(data);
    Clipboard.setData(ClipboardData(text: jsonStr));

    Fluttertoast.showToast(msg: 'Presets exported to clipboard as JSON', backgroundColor: AppTheme.primaryAccent, textColor: AppTheme.pureBlack);
  }

  void _importPresets(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data!.text!);
        for (var map in jsonList) {
          final preset = CompilerPreset(
            name: map['name'] ?? 'Imported Preset',
            endpointUrl: map['endpointUrl'] ?? '',
            httpMethod: map['httpMethod'] ?? 'POST',
            authType: map['authType'] ?? 'None',
            headers: Map<String, String>.from(map['headers'] ?? {}),
            queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
            bodyTemplate: map['bodyTemplate'] ?? '',
            stdoutPath: map['stdoutPath'] ?? '',
            stderrPath: map['stderrPath'] ?? '',
            errorPath: map['errorPath'] ?? '',
            executionTimePath: map['executionTimePath'] ?? '',
            memoryPath: map['memoryPath'] ?? '',
          );
          ref.read(compilerProvider.notifier).addPreset(preset);
        }
        Fluttertoast.showToast(msg: 'Imported ${jsonList.length} presets', backgroundColor: AppTheme.primaryAccent, textColor: AppTheme.pureBlack);
      } catch (e) {
        Fluttertoast.showToast(msg: 'Invalid JSON format in clipboard');
      }
    }
  }
}
