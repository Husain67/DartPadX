import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/preset_provider.dart';
import '../providers/file_provider.dart';
import '../utils/ui_utils.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                indicatorColor: AppTheme.primaryYellow,
                labelColor: AppTheme.primaryYellow,
                unselectedLabelColor: Colors.white60,
                tabs: [
                  Tab(text: 'Compiler Presets'),
                  Tab(text: 'Examples Gallery'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPresetsTab(context, ref),
                    _buildExamplesTab(context, ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetsTab(BuildContext context, WidgetRef ref) {
    final presetState = ref.watch(presetProvider);
    final presets = presetState.presets;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler (Recommended)', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Uses pre-configured secure API for Dart execution.'),
          value: presetState.useDefaultOneCompiler,
          activeTrackColor: AppTheme.primaryYellow,
          onChanged: (val) {
            ref.read(presetProvider.notifier).toggleUseDefault(val);
          },
        ),
        const Divider(color: Colors.white24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Custom API Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
              },
              icon: const Icon(Icons.add),
              label: const Text('New'),
            )
          ],
        ),
        const SizedBox(height: 16),
        ...presets.map((preset) {
          final isSelected = preset.id == presetState.selectedPresetId && !presetState.useDefaultOneCompiler;
          return Card(
            color: isSelected ? Colors.white10 : AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: isSelected ? AppTheme.primaryYellow : Colors.transparent, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(preset.name, style: TextStyle(color: isSelected ? AppTheme.primaryYellow : Colors.white)),
              subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      final confirm = await UiUtils.showConfirmDialog(context, title: 'Delete Preset', content: 'Delete \${preset.name}?', isDestructive: true);
                      if (confirm == true) {
                        ref.read(presetProvider.notifier).deletePreset(preset.id);
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                ref.read(presetProvider.notifier).selectPreset(preset.id);
                ref.read(presetProvider.notifier).toggleUseDefault(false);
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExamplesTab(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello World!");\n}',
      'Input/Output': 'import "dart:io";\nvoid main() {\n  String? input = stdin.readLineSync();\n  print("You entered: \$input");\n}',
      'List Operations': 'void main() {\n  var list = [1, 2, 3];\n  list.add(4);\n  print(list);\n}',
      'Class Example': 'class Person {\n  String name;\n  Person(this.name);\n}\nvoid main() {\n  var p = Person("Dart");\n  print(p.name);\n}',
      'Async/Await': 'Future<void> main() async {\n  print("Wait...");\n  await Future.delayed(Duration(seconds: 1));\n  print("Done!");\n}',
    };

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: examples.length,
      itemBuilder: (context, index) {
        String key = examples.keys.elementAt(index);
        String code = examples[key]!;
        return Card(
          color: AppTheme.surfaceColor,
          child: ListTile(
            title: Text(key),
            trailing: const Icon(Icons.download),
            onTap: () {
              ref.read(fileProvider.notifier).createNewFile(code);
              UiUtils.showToast('Example loaded');
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}
