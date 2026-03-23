import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/compiler_provider.dart';
import '../providers/file_provider.dart';
import '../models/compiler_preset.dart';
import '../theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'preset_editor.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Execution Engine', style: TextStyle(color: AppTheme.accentYellow, fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Turn off to use custom presets below.', style: TextStyle(color: Colors.grey)),
            value: state.useDefaultOneCompiler,
            activeColor: AppTheme.accentYellow,
            onChanged: (val) {
              ref.read(compilerProvider.notifier).toggleUseDefault(val);
            },
          ),
          const Divider(color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compiler Presets', style: TextStyle(color: AppTheme.accentYellow, fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    tooltip: 'Export Presets',
                    onPressed: () {
                      final presets = state.presets.map((p) => p.toJson()).toList();
                      final jsonStr = jsonEncode(presets);
                      Share.share(jsonStr, subject: 'DartMini Presets');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppTheme.accentYellow),
                    onPressed: () => _editPreset(null),
                  ),
                ],
              ),
            ],
          ),
          ...state.presets.map((preset) {
            final isActive = preset.id == state.activePresetId && !state.useDefaultOneCompiler;
            return Card(
              color: isActive ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isActive ? AppTheme.accentYellow : Colors.grey[800]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                      onPressed: () {
                        final copy = CompilerPreset.fromJson(preset.toJson());
                        final newPreset = CompilerPreset(
                          id: const Uuid().v4(),
                          name: '${copy.name} (Copy)',
                          endpointUrl: copy.endpointUrl,
                          httpMethod: copy.httpMethod,
                          authType: copy.authType,
                          authValue: copy.authValue,
                          headers: Map.from(copy.headers),
                          queryParams: Map.from(copy.queryParams),
                          bodyTemplate: copy.bodyTemplate,
                          stdoutPath: copy.stdoutPath,
                          stderrPath: copy.stderrPath,
                          errorPath: copy.errorPath,
                          executionTimePath: copy.executionTimePath,
                          memoryPath: copy.memoryPath,
                        );
                        ref.read(compilerProvider.notifier).addPreset(newPreset);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                      onPressed: () => _editPreset(preset),
                    ),
                    if (state.presets.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                      ),
                  ],
                ),
                onTap: () {
                  ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  ref.read(compilerProvider.notifier).toggleUseDefault(false);
                },
              ),
            );
          }),
          const SizedBox(height: 32),
          const Text('Examples Gallery', style: TextStyle(color: AppTheme.accentYellow, fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            title: const Text('Hello World', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _loadExample('Hello World', "void main() {\n  print('Hello World!');\n}"),
          ),
          ListTile(
            title: const Text('Async Programming', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _loadExample('Async', "Future<void> main() async {\n  print('Fetching data...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}"),
          ),
        ],
      ),
    );
  }

  void _loadExample(String name, String code) {
    ref.read(fileProvider.notifier).createFile('example_${name.toLowerCase().replaceAll(' ', '_')}.dart', content: code);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Loaded $name example", backgroundColor: Colors.green);
  }

  void _editPreset(CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
  }
}
