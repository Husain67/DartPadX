import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import '../services/compiler_service.dart';
import 'theme.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Compiler Presets'),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildPresetsTab(),
          ],
        ),
      ),
    );
  }


  Widget _buildGeneralTab() {
    final compilerState = ref.watch(compilerProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Fast & reliable default execution', style: TextStyle(color: Colors.white54)),
          value: compilerState.useOneCompiler,
          // ignore: deprecated_member_use
          activeColor: AppTheme.primaryAccent,
          onChanged: (val) {
            ref.read(compilerProvider.notifier).toggleUseOneCompiler(val);
          },
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        const Text('Backup & Restore', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
             // Export presets
             final presets = ref.read(compilerProvider).presets;
             final list = presets.map((p) => {
               'name': p.name,
               'endpointUrl': p.endpointUrl,
               'httpMethod': p.httpMethod,
               'authType': p.authType,
               'headers': p.headers,
               'queryParams': p.queryParams,
               'requestBodyTemplate': p.requestBodyTemplate,
               'stdoutPath': p.stdoutPath,
               'stderrPath': p.stderrPath,
               'errorPath': p.errorPath,
               'executionTimePath': p.executionTimePath,
               'memoryPath': p.memoryPath,
             }).toList();

             final jsonStr = jsonEncode(list);

             try {
                String? outputFile = await FilePicker.platform.saveFile(
                  dialogTitle: 'Export Presets',
                  fileName: 'dartmini_presets.json',
                );

                if (outputFile != null) {
                   File file = File(outputFile);
                   await file.writeAsString(jsonStr);
                   Fluttertoast.showToast(msg: "Presets exported successfully");
                }
             } catch (e) {
                Fluttertoast.showToast(msg: "Error exporting presets: $e");
             }
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('Export Presets to JSON'),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            // Import presets
             FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
                withData: true,
              );
              if (result != null) {
                try {
                  final file = result.files.first;
                  final content = utf8.decode(file.bytes!);
                  final List<dynamic> jsonList = jsonDecode(content);

                  for (var item in jsonList) {
                    final preset = CompilerPreset(
                       name: item['name'] ?? 'Imported Preset',
                       endpointUrl: item['endpointUrl'] ?? '',
                       httpMethod: item['httpMethod'] ?? 'POST',
                       authType: item['authType'] ?? 'None',
                       headers: Map<String, String>.from(item['headers'] ?? {}),
                       queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
                       requestBodyTemplate: item['requestBodyTemplate'] ?? '',
                       stdoutPath: item['stdoutPath'] ?? '',
                       stderrPath: item['stderrPath'] ?? '',
                       errorPath: item['errorPath'] ?? '',
                       executionTimePath: item['executionTimePath'] ?? '',
                       memoryPath: item['memoryPath'] ?? '',
                    );
                    ref.read(compilerProvider.notifier).addPreset(preset);
                  }

                  Fluttertoast.showToast(msg: "Imported ${jsonList.length} presets");
                } catch(e) {
                  Fluttertoast.showToast(msg: "Failed to parse JSON presets");
                }
              }
          },
          icon: const Icon(Icons.download),
          label: const Text('Import Presets from JSON'),
        ),
      ],
    );
  }


  Widget _buildPresetsTab() {
    final compilerState = ref.watch(compilerProvider);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: compilerState.presets.length,
            itemBuilder: (context, index) {
              final preset = compilerState.presets[index];
              final isSelected = preset.id == compilerState.activePresetId;

              return ListTile(
                title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppTheme.primaryAccent)
                    else
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white54),
                        onPressed: () => ref.read(compilerProvider.notifier).setActivePreset(preset.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () => _editPreset(preset),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _editPreset(null),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Add New Preset'),
          ),
        ),
      ],
    );
  }

  void _editPreset(CompilerPreset? preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresetEditorScreen(preset: preset),
      ),
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _endpointUrl;
  late String _httpMethod;
  late String _requestBodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  late Map<String, String> _headers;

  @override
  void initState() {
    super.initState();
    _name = widget.preset?.name ?? '';
    _endpointUrl = widget.preset?.endpointUrl ?? '';
    _httpMethod = widget.preset?.httpMethod ?? 'POST';
    _requestBodyTemplate = widget.preset?.requestBodyTemplate ?? '{\n  "code": "{code}",\n  "language": "{language}"\n}';
    _stdoutPath = widget.preset?.stdoutPath ?? 'stdout';
    _stderrPath = widget.preset?.stderrPath ?? 'stderr';
    _errorPath = widget.preset?.errorPath ?? 'error';
    _executionTimePath = widget.preset?.executionTimePath ?? '';
    _memoryPath = widget.preset?.memoryPath ?? '';
    _headers = Map.from(widget.preset?.headers ?? {'Content-Type': 'application/json'});
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _name,
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        requestBodyTemplate: _requestBodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
        headers: _headers,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(newPreset);
      }

      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final tempPreset = CompilerPreset(
      name: _name,
      endpointUrl: _endpointUrl,
      httpMethod: _httpMethod,
      requestBodyTemplate: _requestBodyTemplate,
      stdoutPath: _stdoutPath,
      stderrPath: _stderrPath,
      errorPath: _errorPath,
      executionTimePath: _executionTimePath,
      memoryPath: _memoryPath,
      headers: _headers,
    );

    try {
      final res = await CompilerService.runCode(
        code: "print('Hello from custom API');",
        useOneCompiler: false,
        preset: tempPreset,
      );
      Fluttertoast.showToast(msg: "Success! Stdout: \${res.stdout.isNotEmpty ? res.stdout : 'none'}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: \$e", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Test Connection',
            onPressed: _testConnection,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Platform Name', filled: true),
                validator: (val) => val!.isEmpty ? 'Required' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _endpointUrl,
                decoration: const InputDecoration(labelText: 'Endpoint URL', filled: true),
                validator: (val) => val!.isEmpty ? 'Required' : null,
                onSaved: (val) => _endpointUrl = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _httpMethod,
                decoration: const InputDecoration(labelText: 'HTTP Method', filled: true),
                items: ['POST', 'GET'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _httpMethod = val!),
              ),
              const SizedBox(height: 24),
              const Text('Headers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ..._headers.entries.map((e) => Row(
                children: [
                  Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white70))),
                  Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white70))),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() => _headers.remove(e.key)),
                  )
                ],
              )),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Header'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      String k = '';
                      String v = '';
                      return AlertDialog(
                        title: const Text('Add Header'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(decoration: const InputDecoration(labelText: 'Key'), onChanged: (val) => k = val),
                            TextField(decoration: const InputDecoration(labelText: 'Value'), onChanged: (val) => v = val),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          TextButton(onPressed: () {
                            if (k.isNotEmpty) {
                              setState(() => _headers[k] = v);
                            }
                            Navigator.pop(context);
                          }, child: const Text('Add')),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Request Body Template (JSON)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Placeholders: {code}, {language}, {stdin}', style: TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _requestBodyTemplate,
                maxLines: 6,
                decoration: const InputDecoration(filled: true, border: OutlineInputBorder()),
                onSaved: (val) => _requestBodyTemplate = val!,
              ),
              const SizedBox(height: 24),
              const Text('Response Mapping (Dot Notation)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _stdoutPath,
                decoration: const InputDecoration(labelText: 'stdout path (e.g. data.output)', filled: true),
                onSaved: (val) => _stdoutPath = val!,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _stderrPath,
                decoration: const InputDecoration(labelText: 'stderr path', filled: true),
                onSaved: (val) => _stderrPath = val!,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _errorPath,
                decoration: const InputDecoration(labelText: 'error path', filled: true),
                onSaved: (val) => _errorPath = val!,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _executionTimePath,
                decoration: const InputDecoration(labelText: 'execution time path', filled: true),
                onSaved: (val) => _executionTimePath = val!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
