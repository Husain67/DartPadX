import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import '../providers/file_provider.dart';
import '../models/compiler_preset.dart';
import '../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();
  final _stdoutController = TextEditingController();
  final _stderrController = TextEditingController();
  final _errorController = TextEditingController();
  final _timeController = TextEditingController();
  final _memoryController = TextEditingController();

  List<MapEntry<String, String>> _headersList = [];
  List<MapEntry<String, String>> _queryParamsList = [];

  String _selectedMethod = 'POST';
  String _selectedAuth = 'None';
  CompilerPreset? _editingPreset;

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    _stdoutController.dispose();
    _stderrController.dispose();
    _errorController.dispose();
    _timeController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  void _loadPreset(CompilerPreset preset) {
    _editingPreset = preset;
    _urlController.text = preset.endpointUrl;
    _selectedMethod = preset.httpMethod;
    _selectedAuth = preset.authType;
    _headersList = preset.headers.entries.toList();
    _queryParamsList = preset.queryParams.entries.toList();
    _bodyController.text = preset.bodyTemplate;
    _stdoutController.text = preset.stdoutPath;
    _stderrController.text = preset.stderrPath;
    _errorController.text = preset.errorPath;
    _timeController.text = preset.timePath;
    _memoryController.text = preset.memoryPath;
    setState(() {});
  }

  void _savePreset() {
    if (_editingPreset == null) return;

    Map<String, String> newHeaders = {for (var e in _headersList) e.key: e.value};
    Map<String, String> newParams = {for (var e in _queryParamsList) e.key: e.value};

    final newPreset = _editingPreset!.copyWith(
      endpointUrl: _urlController.text,
      httpMethod: _selectedMethod,
      authType: _selectedAuth,
      headers: newHeaders,
      queryParams: newParams,
      bodyTemplate: _bodyController.text,
      stdoutPath: _stdoutController.text,
      stderrPath: _stderrController.text,
      errorPath: _errorController.text,
      timePath: _timeController.text,
      memoryPath: _memoryController.text,
    );

    ref.read(compilerProvider.notifier).updatePreset(newPreset);
    Fluttertoast.showToast(msg: "Preset saved");
  }

  void _addNewPreset() {
    final newPreset = CompilerPreset(name: 'New Preset', endpointUrl: '');
    ref.read(compilerProvider.notifier).addPreset(newPreset);
    _loadPreset(newPreset);
  }

  void _duplicatePreset() {
    if (_editingPreset == null) return;
    final duplicated = _editingPreset!.copyWith(name: '${_editingPreset!.name} (Copy)', isPreloaded: false);
    ref.read(compilerProvider.notifier).addPreset(duplicated);
    Fluttertoast.showToast(msg: "Preset duplicated");
  }

  void _deletePreset() {
    if (_editingPreset == null || _editingPreset!.isPreloaded) return;
    ref.read(compilerProvider.notifier).deletePreset(_editingPreset!.id);
    _editingPreset = null;
    setState(() {});
    Fluttertoast.showToast(msg: "Preset deleted");
  }

  Future<void> _exportPresets() async {
     try {
        final presets = ref.read(compilerProvider).presets;
        final jsonList = presets.map((p) => {
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
            'timePath': p.timePath,
            'memoryPath': p.memoryPath,
        }).toList();

        final jsonString = jsonEncode(jsonList);
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/dartmini_presets.json');
        await file.writeAsString(jsonString);
        Fluttertoast.showToast(msg: "Exported to ${file.path}");
     } catch (e) {
        Fluttertoast.showToast(msg: "Export failed");
     }
  }

  Future<void> _importPresets() async {
     FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
     );
     if (result != null && result.files.single.path != null) {
        try {
           File file = File(result.files.single.path!);
           String content = await file.readAsString();
           List<dynamic> jsonList = jsonDecode(content);

           for (var json in jsonList) {
               final preset = CompilerPreset(
                   name: json['name'] ?? 'Imported Preset',
                   endpointUrl: json['endpointUrl'] ?? '',
                   httpMethod: json['httpMethod'] ?? 'POST',
                   authType: json['authType'] ?? 'None',
                   headers: Map<String, String>.from(json['headers'] ?? {}),
                   queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
                   bodyTemplate: json['bodyTemplate'] ?? '',
                   stdoutPath: json['stdoutPath'] ?? '',
                   stderrPath: json['stderrPath'] ?? '',
                   errorPath: json['errorPath'] ?? '',
                   timePath: json['timePath'] ?? '',
                   memoryPath: json['memoryPath'] ?? '',
               );
               ref.read(compilerProvider.notifier).addPreset(preset);
           }
           Fluttertoast.showToast(msg: "Presets imported");
        } catch (e) {
           Fluttertoast.showToast(msg: "Import failed");
        }
     }
  }

  Future<void> _testConnection() async {
    if (_editingPreset == null) return;

    try {
      final code = "void main() { print('Hello from custom API'); }";

      Map<String, String> newHeaders = {for (var e in _headersList) e.key: e.value};
      Map<String, String> newParams = {for (var e in _queryParamsList) e.key: e.value};

      final tempPreset = _editingPreset!.copyWith(
        endpointUrl: _urlController.text,
        httpMethod: _selectedMethod,
        authType: _selectedAuth,
        headers: newHeaders,
        queryParams: newParams,
        bodyTemplate: _bodyController.text,
        stdoutPath: _stdoutController.text,
        stderrPath: _stderrController.text,
        errorPath: _errorController.text,
        timePath: _timeController.text,
        memoryPath: _memoryController.text,
      );

      final result = await ApiService.runCustomPreset(tempPreset, code, '');

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Connection Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Stdout:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(result['stdout'] ?? 'None', style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
                const Text('Stderr:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(result['stderr'] ?? 'None', style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Failed'),
          content: SingleChildScrollView(child: Text(e.toString())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & API'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _importPresets, tooltip: 'Import JSON'),
          IconButton(icon: const Icon(Icons.upload), onPressed: _exportPresets, tooltip: 'Export JSON'),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600;
          return Column(
            children: [
              SwitchListTile(
                title: const Text('Use Default OneCompiler'),
                subtitle: const Text('Disables custom presets'),
                value: state.useDefaultOneCompiler,
                onChanged: (val) {
                  ref.read(compilerProvider.notifier).toggleDefault(val);
                },
              ),
              const Divider(),
              Expanded(
                child: state.useDefaultOneCompiler
                  ? _buildExamplesGallery()
                  : (isDesktop ? _buildDesktopLayout(state) : _buildMobileLayout(state)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildExamplesGallery() {
    final examples = {
      'Hello World': "void main() {\n  print('Hello World!');\n}",
      'Input/Output': "import 'dart:io';\nvoid main() {\n  String? name = stdin.readLineSync();\n  print('Hello, \$name!');\n}",
      'List & Loop': "void main() {\n  var list = [1, 2, 3];\n  for (var i in list) {\n    print(i);\n  }\n}",
      'Class': "class Person {\n  String name;\n  Person(this.name);\n  void greet() => print('Hi, \$name');\n}\nvoid main() {\n  var p = Person('Dart');\n  p.greet();\n}",
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Examples Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...examples.entries.map((e) => Card(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            title: Text(e.key),
            trailing: const Icon(Icons.download),
            onTap: () {
              ref.read(fileProvider.notifier).createFile('${e.key.replaceAll(' ', '_').toLowerCase()}.dart', e.value);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Loaded ${e.key}");
            },
          ),
        )),
      ],
    );
  }

  Widget _buildDesktopLayout(CompilerState state) {
      return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              SizedBox(
                  width: 250,
                  child: Column(
                      children: [
                          ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Add New Preset'),
                              onTap: _addNewPreset,
                          ),
                          const Divider(),
                          Expanded(
                              child: ListView(
                                  children: state.presets.map((preset) {
                                      return ListTile(
                                          title: Text(preset.name),
                                          selected: state.activePresetId == preset.id,
                                          selectedColor: Theme.of(context).primaryColor,
                                          onTap: () {
                                              ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                                              _loadPreset(preset);
                                          },
                                      );
                                  }).toList(),
                              ),
                          ),
                      ]
                  ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _buildEditorForm()),
          ]
      );
  }

  Widget _buildMobileLayout(CompilerState state) {
      return Column(
          children: [
              Container(
                  height: 60,
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add New'),
                                  onPressed: _addNewPreset,
                              ),
                          ),
                          ...state.presets.map((preset) {
                              bool isSelected = state.activePresetId == preset.id;
                              return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  child: ChoiceChip(
                                      label: Text(preset.name),
                                      selected: isSelected,
                                      onSelected: (val) {
                                          if (val) {
                                              ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                                              _loadPreset(preset);
                                          }
                                      },
                                  ),
                              );
                          }).toList(),
                      ]
                  )
              ),
              const Divider(height: 1),
              Expanded(child: _buildEditorForm()),
          ]
      );
  }

  Widget _buildEditorForm() {
      if (_editingPreset == null) return const Center(child: Text('Select a preset to edit'));

      return ListView(
          padding: const EdgeInsets.all(16),
          children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Expanded(
                          child: TextFormField(
                              initialValue: _editingPreset!.name,
                              decoration: const InputDecoration(labelText: 'Preset Name', isDense: true),
                              onChanged: (val) {
                                _editingPreset = _editingPreset!.copyWith(name: val);
                                setState((){});
                              },
                          ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.copy), onPressed: _duplicatePreset, tooltip: 'Duplicate'),
                      if (!_editingPreset!.isPreloaded)
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deletePreset, tooltip: 'Delete'),
                      ElevatedButton(onPressed: _savePreset, child: const Text('Save')),
                  ],
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(labelText: 'Endpoint URL'),
              ),
              const SizedBox(height: 16),
              Row(
                  children: [
                      Expanded(
                          child: DropdownButtonFormField<String>(
                              value: _selectedMethod,
                              items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setState(() => _selectedMethod = v!),
                              decoration: const InputDecoration(labelText: 'HTTP Method'),
                          ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: DropdownButtonFormField<String>(
                              value: _selectedAuth,
                              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setState(() => _selectedAuth = v!),
                              decoration: const InputDecoration(labelText: 'Auth Type'),
                          ),
                      ),
                  ],
              ),
              const SizedBox(height: 16),
              _buildDynamicTable('Headers', _headersList, () => setState(() => _headersList.add(const MapEntry('', '')))),
              const SizedBox(height: 16),
              _buildDynamicTable('Query Params', _queryParamsList, () => setState(() => _queryParamsList.add(const MapEntry('', '')))),
              const SizedBox(height: 16),
              const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                  controller: _bodyController,
                  maxLines: 6,
                  decoration: const InputDecoration(hintText: '{\n  "code": "{code}",\n  "stdin": "{stdin}"\n}'),
                  style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                  children: [
                      Expanded(child: TextField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'stdout path'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _stderrController, decoration: const InputDecoration(labelText: 'stderr path'))),
                  ],
              ),
              const SizedBox(height: 8),
              Row(
                  children: [
                      Expanded(child: TextField(controller: _errorController, decoration: const InputDecoration(labelText: 'error path'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _timeController, decoration: const InputDecoration(labelText: 'time path'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _memoryController, decoration: const InputDecoration(labelText: 'memory path'))),
                  ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _testConnection,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  child: const Text('Test Connection', style: TextStyle(color: Colors.white)),
              ),
          ],
      );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> items, VoidCallback onAdd) {
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Add'), onPressed: onAdd),
                  ],
              ),
              if (items.isEmpty) const Text('None', style: TextStyle(color: Colors.grey)),
              for (int i = 0; i < items.length; i++)
                  Padding(
                      key: ValueKey('row_$i'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                          children: [
                              Expanded(
                                  child: TextFormField(
                                      initialValue: items[i].key,
                                      decoration: const InputDecoration(hintText: 'Key', isDense: true),
                                      onChanged: (val) => items[i] = MapEntry(val, items[i].value),
                                  ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: TextFormField(
                                      initialValue: items[i].value,
                                      decoration: const InputDecoration(hintText: 'Value', isDense: true),
                                      onChanged: (val) => items[i] = MapEntry(items[i].key, val),
                                  ),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () => setState(() => items.removeAt(i)),
                              ),
                          ],
                      ),
                  ),
          ],
      );
  }
}
