import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/settings_provider.dart';
import '../../providers/preset_provider.dart';
import '../../providers/file_provider.dart';
import '../../models/compiler_preset.dart';
import '../../utils/constants.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            indicatorColor: AppColors.accentYellow,
            labelColor: AppColors.accentYellow,
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
    final settings = ref.watch(settingsProvider);
    final presets = ref.watch(presetProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Disable to use a custom API preset'),
          value: settings.useDefaultOneCompiler,
          activeTrackColor: AppColors.accentYellow,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).toggleUseDefault(val);
          },
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Custom API Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.download, color: AppColors.accentYellow),
                  tooltip: 'Export Presets',
                  onPressed: () => _exportPresets(presets),
                ),
                IconButton(
                  icon: const Icon(Icons.upload, color: AppColors.accentYellow),
                  tooltip: 'Import Presets',
                  onPressed: () => _importPresets(ref),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        ...presets.map((preset) => Card(
          color: Colors.black45,
          child: ListTile(
            title: Text(preset.platformName),
            subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!settings.useDefaultOneCompiler && settings.activePresetId == preset.id)
                  const Icon(Icons.check_circle, color: AppColors.successGreen)
                else
                  TextButton(
                    onPressed: () {
                      ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                      ref.read(settingsProvider.notifier).toggleUseDefault(false);
                    },
                    child: const Text('Set Default', style: TextStyle(color: AppColors.accentYellow)),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                    } else if (value == 'duplicate') {
                      ref.read(presetProvider.notifier).duplicatePreset(preset);
                    } else if (value == 'delete') {
                      ref.read(presetProvider.notifier).deletePreset(preset.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.errorRed))),
                  ],
                ),
              ],
            ),
          ),
        )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
          },
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text('Add New Preset', style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentYellow),
        )
      ],
    );
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    try {
      final jsonList = presets.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/dart_mini_ide_presets.json';
      final file = File(path);
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(path)], text: 'Exported Presets from DartMini IDE');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error exporting presets');
    }
  }

  Future<void> _importPresets(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final importedPresets = jsonList.map((j) => CompilerPreset.fromJson(j)).toList();
        ref.read(presetProvider.notifier).replaceAll(importedPresets);
        Fluttertoast.showToast(msg: 'Imported successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error importing presets');
    }
  }
}

class _ExamplesTab extends ConsumerWidget {
  const _ExamplesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {
        'title': 'Hello World',
        'code': "void main() {\\n  print('Hello, World!');\\n}"
      },
      {
        'title': 'Variables & Types',
        'code': "void main() {\\n  String name = 'Dart';\\n  int year = 2011;\\n  print('\$name was created in \$year.');\\n}"
      },
      {
        'title': 'Lists & Loops',
        'code': "void main() {\\n  List<String> colors = ['Red', 'Green', 'Blue'];\\n  for (var color in colors) {\\n    print(color);\\n  }\\n}"
      },
      {
        'title': 'Classes',
        'code': "class Person {\\n  String name;\\n  Person(this.name);\\n  void greet() => print('Hi, I am \$name');\\n}\\n\\nvoid main() {\\n  var p = Person('Alice');\\n  p.greet();\\n}"
      },
      {
        'title': 'Async / Await',
        'code': "Future<void> fetch() async {\\n  print('Fetching...');\\n  await Future.delayed(Duration(seconds: 1));\\n  print('Done!');\\n}\\n\\nvoid main() async {\\n  await fetch();\\n}"
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: examples.length,
      itemBuilder: (context, index) {
        final ex = examples[index];
        return Card(
          color: Colors.black45,
          child: ListTile(
            title: Text(ex['title']!),
            trailing: const Icon(Icons.file_download, color: AppColors.accentYellow),
            onTap: () {
              ref.read(fileProvider.notifier).addFile(
                "${ex['title']!.replaceAll(' ', '_')}.dart",
                content: ex['code']!,
              );
              Navigator.pop(context); // Close settings
              Fluttertoast.showToast(msg: "Loaded ${ex['title']}");
            },
          ),
        );
      },
    );
  }
}
