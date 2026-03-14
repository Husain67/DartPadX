import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';
import '../providers/execution_provider.dart';
import '../providers/file_provider.dart';
import 'dart:convert';
import '../utils/theme.dart';
import '../utils/examples.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.backgroundStart,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler API', style: TextStyle(color: AppTheme.textLight)),
              subtitle: const Text('When enabled, custom presets are ignored.', style: TextStyle(color: Colors.grey)),
              value: settings.useOneCompiler,
              activeColor: AppTheme.primaryAccent,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setUseOneCompiler(val);
              },
            ),
            const Divider(color: Colors.grey),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Custom Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
            ),
            ...settings.customPresets.map((preset) => _buildPresetTile(preset, settings.activePresetId)),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Examples Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
            ),
            ...ExampleGallery.examples.entries.map((e) => Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(e.key, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryAccent, size: 16),
                onTap: () {
                  ref.read(fileProvider.notifier).addFile('${e.key.replaceAll(' ', '_')}.dart', e.value);
                  Navigator.pop(context); // Close settings and go to the file
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded ${e.key}')));
                },
              ),
            )),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showPresetDialog(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Preset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.toolbarButtonBg,
                    foregroundColor: AppTheme.textDark,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).exportPresets();
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.toolbarButtonBg,
                    foregroundColor: AppTheme.textDark,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).importPresets();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Import'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.toolbarButtonBg,
                    foregroundColor: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetTile(CompilerPreset preset, String? activeId) {
    final isActive = preset.id == activeId;
    return Card(
      color: isActive ? Colors.grey[800] : Colors.grey[900],
      child: ListTile(
        title: Text(preset.name, style: TextStyle(color: isActive ? AppTheme.primaryAccent : Colors.white)),
        subtitle: Text(preset.endpoint, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showPresetDialog(preset),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.green),
              onPressed: () => ref.read(settingsProvider.notifier).duplicatePreset(preset),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset.id),
            ),
          ],
        ),
        onTap: () {
          ref.read(settingsProvider.notifier).setActivePreset(preset.id);
        },
      ),
    );
  }

  void _showPresetDialog(CompilerPreset? preset) {
    final isNew = preset == null;
    final nameController = TextEditingController(text: preset?.name ?? '');
    final endpointController = TextEditingController(text: preset?.endpoint ?? '');
    String method = preset?.method ?? 'POST';
    String authType = preset?.authType ?? 'None';
    final bodyController = TextEditingController(text: preset?.bodyTemplate ?? '{}');

    // Response Mappings
    final stdoutController = TextEditingController(text: preset?.responseStdoutPath ?? '');
    final stderrController = TextEditingController(text: preset?.responseStderrPath ?? '');
    final timeController = TextEditingController(text: preset?.responseTimePath ?? '');
    final memoryController = TextEditingController(text: preset?.responseMemoryPath ?? '');

    // Assuming a simple text field for headers as JSON representation to keep UI straightforward in dialog,
    // or simply not implementing dynamic rows in a small dialog. Let's use a single textfield for headers JSON.
    // In a full mobile view this would be a list builder, but for this beta we will serialize it to JSON for editing.
    final headersController = TextEditingController(text: jsonEncode(preset?.headers ?? {}));
    final queryParamsController = TextEditingController(text: jsonEncode(preset?.queryParams ?? {}));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(isNew ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Platform Name', labelStyle: TextStyle(color: Colors.grey))),
                    TextField(controller: endpointController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Endpoint URL', labelStyle: TextStyle(color: Colors.grey))),

                    DropdownButtonFormField<String>(
                      value: method,
                      dropdownColor: Colors.grey[800],
                      items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => method = val!),
                      decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.grey)),
                    ),

                    DropdownButtonFormField<String>(
                      value: authType,
                      dropdownColor: Colors.grey[800],
                      items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => authType = val!),
                      decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.grey)),
                    ),

                    TextField(controller: headersController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Headers (JSON)', labelStyle: TextStyle(color: Colors.grey))),
                    TextField(controller: queryParamsController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Query Params (JSON)', labelStyle: TextStyle(color: Colors.grey))),

                    TextField(
                      controller: bodyController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Body Template (JSON)', hintText: 'Use {code}, {language}', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    const Divider(),
                    const Text('Response Mapping (dot notation)', style: TextStyle(color: AppTheme.primaryAccent)),
                    TextField(controller: stdoutController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'stdout path', labelStyle: TextStyle(color: Colors.grey))),
                    TextField(controller: stderrController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'stderr path', labelStyle: TextStyle(color: Colors.grey))),
                    TextField(controller: timeController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'executionTime path', labelStyle: TextStyle(color: Colors.grey))),
                    TextField(controller: memoryController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'memory path', labelStyle: TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    Map<String, String> parsedHeaders = {};
                    Map<String, String> parsedQuery = {};
                    try {
                      parsedHeaders = Map<String, String>.from(jsonDecode(headersController.text));
                      parsedQuery = Map<String, String>.from(jsonDecode(queryParamsController.text));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid JSON in Headers or Query Params')));
                      return;
                    }

                    final testPreset = (preset ?? CompilerPreset(id: '', name: '', endpoint: '')).copyWith(
                      name: nameController.text,
                      endpoint: endpointController.text,
                      method: method,
                      authType: authType,
                      headers: parsedHeaders,
                      queryParams: parsedQuery,
                      bodyTemplate: bodyController.text,
                      responseStdoutPath: stdoutController.text,
                      responseStderrPath: stderrController.text,
                      responseTimePath: timeController.text,
                      responseMemoryPath: memoryController.text,
                    );

                    final testCode = "print('Hello from custom API');";
                    ref.read(executionProvider.notifier).executeCode(testCode, useOneCompiler: false, preset: testPreset);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testing connection... check output sheet')));
                  },
                  child: const Text('Test Connection', style: TextStyle(color: Colors.blue)),
                ),
                TextButton(
                  onPressed: () {
                    Map<String, String> parsedHeaders = {};
                    Map<String, String> parsedQuery = {};
                    try {
                      parsedHeaders = Map<String, String>.from(jsonDecode(headersController.text));
                      parsedQuery = Map<String, String>.from(jsonDecode(queryParamsController.text));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid JSON in Headers or Query Params')));
                      return;
                    }

                    final newPreset = (preset ?? CompilerPreset(id: DateTime.now().millisecondsSinceEpoch.toString(), name: '', endpoint: '')).copyWith(
                      name: nameController.text,
                      endpoint: endpointController.text,
                      method: method,
                      authType: authType,
                      headers: parsedHeaders,
                      queryParams: parsedQuery,
                      bodyTemplate: bodyController.text,
                      responseStdoutPath: stdoutController.text,
                      responseStderrPath: stderrController.text,
                      responseTimePath: timeController.text,
                      responseMemoryPath: memoryController.text,
                    );
                    if (isNew) {
                      ref.read(settingsProvider.notifier).addPreset(newPreset);
                    } else {
                      ref.read(settingsProvider.notifier).updatePreset(newPreset);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: AppTheme.primaryAccent)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
