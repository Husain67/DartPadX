import '../providers/file_provider.dart';
import 'preset_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../providers/settings_provider.dart';
import '../models/compiler_preset.dart';
import '../core/theme.dart';

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
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Compiler Presets'),
              Tab(text: 'Examples Gallery'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PresetsTab(),
            _ExamplesTab(),
          ],
        ),
      ),
    );
  }
}

class _PresetsTab extends ConsumerWidget {
  const _PresetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('RapidAPI endpoint, pre-configured key'),
          activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.primaryColor,
          value: state.useDefaultOneCompiler,
          onChanged: (val) => ref.read(settingsProvider.notifier).toggleUseDefault(val),
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Custom Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Export Presets',
                  onPressed: () {
                    ref.read(settingsProvider.notifier).exportPresets((json) {
                      Clipboard.setData(ClipboardData(text: json));
                      Fluttertoast.showToast(msg: 'Presets JSON copied to clipboard');
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.file_upload),
                  tooltip: 'Import Presets',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      try {
                        await ref.read(settingsProvider.notifier).importPresets(data!.text!);
                        Fluttertoast.showToast(msg: 'Presets imported successfully');
                      } catch (e) {
                        Fluttertoast.showToast(msg: 'Invalid JSON');
                      }
                    }
                  },
                ),
                ElevatedButton.icon(
                  onPressed: state.useDefaultOneCompiler ? null : () {
                     // Add New
                     final newPreset = CompilerPreset(
                       id: const Uuid().v4(),
                       name: 'New Preset',
                       endpointUrl: '',
                     );
                     ref.read(settingsProvider.notifier).savePreset(newPreset);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!state.useDefaultOneCompiler)
          ...state.presets.map((preset) => Card(
            color: state.activePresetId == preset.id ? AppTheme.surfaceColor : AppTheme.backgroundColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: state.activePresetId == preset.id ? AppTheme.primaryColor : Colors.grey.shade800,
                width: state.activePresetId == preset.id ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(preset.name),
              subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.activePresetId != preset.id)
                    TextButton(
                      onPressed: () => ref.read(settingsProvider.notifier).setActivePreset(preset.id),
                      child: const Text('Set Active'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => ref.read(settingsProvider.notifier).duplicatePreset(preset),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset.id),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
              },
            ),
          )),
      ],
    );
  }
}

class _ExamplesTab extends ConsumerWidget {
  const _ExamplesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\n  print('Hello World!');\n}",
      'Async Example': "import 'dart:async';\n\nvoid main() async {\n  print('Start');\n  await Future.delayed(Duration(seconds: 1));\n  print('End');\n}",
      'List & Map': "void main() {\n  final list = [1, 2, 3];\n  final map = {'a': 1, 'b': 2};\n  print(list);\n  print(map);\n}",
      'Class Example': "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi \$name');\n}\n\nvoid main() {\n  Person('Alice').greet();\n}",
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: examples.entries.map((e) => Card(
        color: AppTheme.surfaceColor,
        child: ListTile(
          title: Text(e.key),
          trailing: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
          onTap: () {
            ref.read(fileProvider.notifier).importFile(
              '${e.key.replaceAll(' ', '_').toLowerCase()}.dart',
              e.value
            );
            Fluttertoast.showToast(msg: '\${e.key} loaded');
            Navigator.pop(context);
          },
        ),
      )).toList(),
    );
  }
}
