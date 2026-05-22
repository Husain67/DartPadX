import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/theme.dart';
import '../../models/compiler_preset.dart';
import '../../providers/app_state.dart';
import '../../services/execution_service.dart';
import 'preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralTab(context, ref),
            _buildPresetsTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Turn off to use selected custom preset'),
          activeTrackColor: AppTheme.primaryAccent,
          value: compilerState.useDefaultCompiler,
          onChanged: (val) => ref.read(compilerProvider.notifier).setUseDefaultCompiler(val),
        ),
        const Divider(),
        const ListTile(
          title: Text('Examples Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Load example code snippets'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ExampleChip(label: 'Hello World', code: 'void main() {\n  print("Hello World!");\n}', ref: ref, context: context),
            _ExampleChip(label: 'Input/Output', code: 'import "dart:io";\n\nvoid main() {\n  print("Enter your name:");\n  String? name = stdin.readLineSync();\n  print("Hello, \$name!");\n}', ref: ref, context: context),
            _ExampleChip(label: 'List & Loops', code: 'void main() {\n  var list = [1, 2, 3, 4, 5];\n  for (var item in list) {\n    print("Item: \$item");\n  }\n}', ref: ref, context: context),
             _ExampleChip(label: 'Class', code: 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print("Hi, I am \$name");\n}\n\nvoid main() {\n  var p = Person("DartMini");\n  p.greet();\n}', ref: ref, context: context),
             _ExampleChip(label: 'Async', code: 'Future<void> fetch() async {\n  await Future.delayed(Duration(seconds: 1));\n  print("Data fetched");\n}\n\nvoid main() async {\n  print("Fetching...");\n  await fetch();\n}', ref: ref, context: context),
          ],
        )
      ],
    );
  }

  Widget _buildPresetsTab(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom Compilers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New'),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: compilerState.presets.length,
            itemBuilder: (ctx, i) {
              final preset = compilerState.presets[i];
              final isActive = preset.id == compilerState.activePresetId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isActive ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isActive ? AppTheme.primaryAccent : Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      if (isActive) const Icon(Icons.check_circle, color: AppTheme.primaryAccent, size: 20),
                      if (isActive) const SizedBox(width: 8),
                      Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                               Expanded(
                                 child: ElevatedButton(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
                                   onPressed: () {
                                      ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                                      if (compilerState.useDefaultCompiler) {
                                          ref.read(compilerProvider.notifier).setUseDefaultCompiler(false);
                                          Fluttertoast.showToast(msg: 'Custom compiler enabled');
                                      }
                                   },
                                   child: const Text('Set as Default'),
                                 ),
                               ),
                               const SizedBox(width: 8),
                               Expanded(
                                 child: ElevatedButton(
                                   style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent, foregroundColor: Colors.black),
                                   onPressed: () => _testConnection(context, preset),
                                   child: const Text('Test Connection'),
                                 ),
                               ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(existingPreset: preset))),
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Duplicate'),
                                  onPressed: () {
                                    final dup = preset.copyWith(id: null, name: '${preset.name} (Copy)');
                                    ref.read(compilerProvider.notifier).addPreset(dup);
                                  },
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onPressed: () => _confirmDelete(context, ref, preset),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
        // Export/Import row
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Export All'),
                onPressed: () => _exportPresets(context, compilerState.presets),
              ),
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Import'),
                onPressed: () => _importPresets(context, ref),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CompilerPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: Text('Are you sure you want to delete ${preset.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(compilerProvider.notifier).deletePreset(preset.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      )
    );
  }

  Future<void> _testConnection(BuildContext context, CompilerPreset preset) async {
      if (!context.mounted) return;
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const AlertDialog(
              content: Row(
                  children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text("Testing connection..."),
                  ],
              ),
          ),
      );

      final res = await ExecutionService.executeCode(
          code: "void main() { print('Hello from custom API'); }",
          stdin: "",
          useDefault: false,
          preset: preset
      );

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      if (!context.mounted) return;
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              title: const Text('Test Result'),
              content: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          if (res['error']?.isNotEmpty == true) ...[
                              const Text('Error:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              Text(res['error']),
                              const SizedBox(height: 8),
                          ],
                          const Text('Parsed stdout:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          Text(res['stdout'] ?? ''),
                          const SizedBox(height: 8),
                          const Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(res['raw'] ?? '', style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                      ],
                  ),
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
              ],
          )
      );
  }

  Future<void> _exportPresets(BuildContext context, List<CompilerPreset> presets) async {
      final jsonList = presets.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await Clipboard.setData(ClipboardData(text: jsonString));
      Fluttertoast.showToast(msg: 'Exported JSON copied to clipboard');
  }

  Future<void> _importPresets(BuildContext context, WidgetRef ref) async {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null && data!.text!.isNotEmpty) {
          try {
              final List<dynamic> jsonList = jsonDecode(data.text!);
              for (var item in jsonList) {
                  final preset = CompilerPreset.fromJson(item);
                  ref.read(compilerProvider.notifier).addPreset(preset.copyWith(id: const Uuid().v4()));
              }
              Fluttertoast.showToast(msg: 'Imported ${jsonList.length} presets successfully');
          } catch (e) {
              Fluttertoast.showToast(msg: 'Invalid JSON in clipboard');
          }
      } else {
          Fluttertoast.showToast(msg: 'Clipboard is empty');
      }
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final String code;
  final WidgetRef ref;
  final BuildContext context;

  const _ExampleChip({required this.label, required this.code, required this.ref, required this.context});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFF2D2D2D),
      onPressed: () {
        ref.read(editorProvider.notifier).importFile('${label.replaceAll(' ', '_').toLowerCase()}.dart', code);
        Navigator.pop(context);
        Fluttertoast.showToast(msg: 'Loaded $label');
      },
    );
  }
}
