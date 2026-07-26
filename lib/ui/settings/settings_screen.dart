import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/providers/compiler_provider.dart';
import '../../data/providers/file_provider.dart';
import 'preset_editor.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void _initTabs() {
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAccent,
          tabs: const [
            Tab(text: 'Compilers'),
            Tab(text: 'Examples'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompilersTab(),
          _buildExamplesTab(),
        ],
      ),
    );
  }

  Widget _buildCompilersTab() {
    final compilerState = ref.watch(compilerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Fast & reliable default execution'),
          value: compilerState.useDefaultOneCompiler,
          // ignore: deprecated_member_use
          activeColor: AppTheme.primaryAccent,
          onChanged: (val) {
            ref.read(compilerProvider.notifier).toggleDefaultCompiler(val);
          },
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Custom API Presets',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        if (!compilerState.useDefaultOneCompiler &&
            compilerState.presets.isEmpty)
          const Text('No presets available. Add one below.',
              style: TextStyle(color: Colors.white54)),
        ...compilerState.presets.map((preset) {
          final isSelected = preset.id == compilerState.activePresetId &&
              !compilerState.useDefaultOneCompiler;
          return Card(
            color: isSelected
                ? AppTheme.primaryAccent.withValues(alpha: 0.1)
                : AppTheme.bgLightDark,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: isSelected ? AppTheme.primaryAccent : Colors.white12),
                borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              title: Text(preset.name),
              subtitle: Text(preset.endpoint, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      final duplicate = preset.copyWith(
                          id: const Uuid().v4(),
                          name: '\${preset.name} (Copy)');
                      ref.read(compilerProvider.notifier).savePreset(duplicate);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PresetEditor(preset: preset)));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        size: 20, color: Colors.redAccent),
                    onPressed: () => ref
                        .read(compilerProvider.notifier)
                        .deletePreset(preset.id),
                  ),
                ],
              ),
              onTap: () {
                if (!compilerState.useDefaultOneCompiler) {
                  ref
                      .read(compilerProvider.notifier)
                      .setActivePreset(preset.id);
                }
              },
            ),
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryAccent,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add New Preset'),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PresetEditor()));
          },
        ),
      ],
    );
  }

  Widget _buildExamplesTab() {
    final examples = {
      'Hello World': 'void main() {\n  print("Hello, World!");\n}',
      'Input/Output':
          'import "dart:io";\nvoid main() {\n  String? name = stdin.readLineSync();\n  print("Hi \$name");\n}',
      'Async/Await':
          'Future<void> main() async {\n  print("Wait...");\n  await Future.delayed(Duration(seconds:1));\n  print("Done!");\n}',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: examples.entries
          .map((e) => Card(
                color: AppTheme.bgLightDark,
                child: ListTile(
                  title: Text(e.key),
                  trailing: const Icon(Icons.download),
                  onTap: () {
                    ref.read(fileProvider.notifier).importFile(
                        '\${e.key.replaceAll(" ", "_")}.dart', e.value);
                    Navigator.pop(context);
                  },
                ),
              ))
          .toList(),
    );
  }
}
