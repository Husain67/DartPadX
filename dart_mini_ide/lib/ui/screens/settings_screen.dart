import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../../providers/settings_provider.dart';
import '../../providers/file_provider.dart';
import '../../models/compiler_preset.dart';
import '../../theme/app_theme.dart';
import '../../services/compiler_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'General'),
            Tab(text: 'Compiler Presets'),
            Tab(text: 'Examples'),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildPresetsTab(),
            _buildExamplesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Turn off to use selected custom API preset'),
          value: settings.useOneCompiler,
          // ignore: deprecated_member_use
          activeColor: AppTheme.primaryAccent,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).toggleUseOneCompiler(val);
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('Export Presets'),
          trailing: const Icon(Icons.upload_file),
          onTap: () {
            final jsonStr = ref.read(settingsProvider.notifier).exportPresets();
            Clipboard.setData(ClipboardData(text: jsonStr));
            Fluttertoast.showToast(msg: 'Presets exported to clipboard');
          },
        ),
        ListTile(
          title: const Text('Import Presets'),
          trailing: const Icon(Icons.download),
          onTap: () async {
            final data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null) {
               ref.read(settingsProvider.notifier).importPresets(data.text!);
               Fluttertoast.showToast(msg: 'Presets imported');
            } else {
               Fluttertoast.showToast(msg: 'Clipboard is empty');
            }
          },
        ),
      ],
    );
  }

  Widget _buildPresetsTab() {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              _showEditPresetDialog(null);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Preset'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: settings.presets.length,
            itemBuilder: (context, index) {
              final preset = settings.presets[index];
              final isActive = preset.id == settings.activePresetId && !settings.useOneCompiler;

              return ListTile(
                title: Text(preset.name),
                subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                       const Icon(Icons.check_circle, color: AppTheme.primaryAccent),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                         ref.read(settingsProvider.notifier).duplicatePreset(preset.id);
                         Fluttertoast.showToast(msg: "Preset duplicated");
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditPresetDialog(preset),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                         ref.read(settingsProvider.notifier).removePreset(preset.id);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                  ref.read(settingsProvider.notifier).toggleUseOneCompiler(false);
                  Fluttertoast.showToast(msg: "Set as active preset");
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamplesTab() {
    final examples = [
      {'name': 'Hello World', 'code': "void main() {\n  print('Hello, World!');\n}"},
      {'name': 'List Operations', 'code': "void main() {\n  final list = [1, 2, 3];\n  print(list.map((e) => e * 2).toList());\n}"},
      {'name': 'Basic Class', 'code': "class Person {\n  String name;\n  Person(this.name);\n  void sayHello() => print('Hello, \$name');\n}\n\nvoid main() {\n  var p = Person('DartMini');\n  p.sayHello();\n}"},
      {'name': 'Async / Await', 'code': "import 'dart:async';\n\nFuture<void> main() async {\n  print('Fetching...');\n  await Future.delayed(Duration(seconds: 1));\n  print('Done!');\n}"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: examples.length,
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(examples[index]['name']!),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
               ref.read(fileProvider.notifier).addFile('${examples[index]['name']!.replaceAll(' ', '_')}.dart', examples[index]['code']!);
               Navigator.pop(context);
               Fluttertoast.showToast(msg: 'Example loaded');
            },
          ),
        );
      },
    );
  }

  void _showEditPresetDialog(CompilerPreset? preset) {
    final isNew = preset == null;
    final nameCtrl = TextEditingController(text: preset?.name ?? '');
    final urlCtrl = TextEditingController(text: preset?.url ?? '');
    final methodCtrl = TextEditingController(text: preset?.method ?? 'POST');
    final authTypeCtrl = TextEditingController(text: preset?.authType ?? 'None');
    final headersCtrl = TextEditingController(text: preset != null ? jsonEncode(preset.headers) : '{}');
    final queryParamsCtrl = TextEditingController(text: preset != null ? jsonEncode(preset.queryParams) : '{}');
    final bodyCtrl = TextEditingController(text: preset?.bodyTemplate ?? '');
    final stdoutCtrl = TextEditingController(text: preset?.stdoutPath ?? '');
    final stderrCtrl = TextEditingController(text: preset?.stderrPath ?? '');
    final errorCtrl = TextEditingController(text: preset?.errorPath ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isNew ? 'New Preset' : 'Edit Preset', style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 16),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'URL'))),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                           Clipboard.setData(ClipboardData(text: urlCtrl.text));
                           Fluttertoast.showToast(msg: "URL Copied");
                        }
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: methodCtrl, decoration: const InputDecoration(labelText: 'Method (GET/POST/PUT)')),
                  const SizedBox(height: 8),
                  TextField(controller: authTypeCtrl, decoration: const InputDecoration(labelText: 'Auth Type (None/API-Key/Bearer)')),
                  const SizedBox(height: 8),
                  TextField(controller: headersCtrl, decoration: const InputDecoration(labelText: 'Headers (JSON Format)')),
                  const SizedBox(height: 8),
                  TextField(controller: queryParamsCtrl, decoration: const InputDecoration(labelText: 'Query Params (JSON Format)')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bodyCtrl,
                    decoration: const InputDecoration(labelText: 'Body Template (JSON)', hintText: 'Use {code} and {stdin}'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path (dot notation)')),
                  const SizedBox(height: 8),
                  TextField(controller: stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path (dot notation)')),
                  const SizedBox(height: 8),
                  TextField(controller: errorCtrl, decoration: const InputDecoration(labelText: 'error path (dot notation)')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () async {
                          // Test Connection
                          final tempPreset = CompilerPreset(
                            id: preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameCtrl.text,
                            url: urlCtrl.text,
                            method: methodCtrl.text,
                            authType: authTypeCtrl.text,
                            headers: Map<String, String>.from(jsonDecode(headersCtrl.text)),
                            queryParams: Map<String, String>.from(jsonDecode(queryParamsCtrl.text)),
                            bodyTemplate: bodyCtrl.text,
                            stdoutPath: stdoutCtrl.text,
                            stderrPath: stderrCtrl.text,
                            errorPath: errorCtrl.text,
                          );

                          Fluttertoast.showToast(msg: "Testing connection...");
                          final svc = CompilerService();
                          final out = await svc.executeCode(code: "print('Hello Test');", useDefault: false, preset: tempPreset);
                          if (out.error.isNotEmpty && out.stdout.isEmpty && out.stderr.isEmpty) {
                             if (!ctx.mounted) return;
                             Fluttertoast.showToast(msg: "Test Failed: \${out.error}");
                          } else {
                             if (!ctx.mounted) return;
                             Fluttertoast.showToast(msg: "Test Output: \${out.stdout.isEmpty ? out.stderr : out.stdout}");
                          }
                        },
                        child: const Text('Test'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          try {
                            final newPreset = CompilerPreset(
                              id: preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameCtrl.text,
                              url: urlCtrl.text,
                              method: methodCtrl.text,
                              authType: authTypeCtrl.text,
                              headers: Map<String, String>.from(jsonDecode(headersCtrl.text)),
                              queryParams: Map<String, String>.from(jsonDecode(queryParamsCtrl.text)),
                              bodyTemplate: bodyCtrl.text,
                              stdoutPath: stdoutCtrl.text,
                              stderrPath: stderrCtrl.text,
                              errorPath: errorCtrl.text,
                            );
                            if (isNew) {
                              ref.read(settingsProvider.notifier).addPreset(newPreset);
                            } else {
                              ref.read(settingsProvider.notifier).updatePreset(newPreset);
                            }
                            Navigator.pop(ctx);
                          } catch (e) {
                             Fluttertoast.showToast(msg: "Invalid JSON format in Headers or Query Params");
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
