import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/compiler_notifier.dart';
import '../models/compiler_preset.dart';
import '../services/execution_service.dart';

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
            indicatorColor: Color(0xFFFACC15),
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _GeneralSettingsTab(),
            _CompilerPresetsTab(),
          ],
        ),
      ),
    );
  }
}

class _GeneralSettingsTab extends StatelessWidget {
  const _GeneralSettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          title: Text('Theme'),
          subtitle: Text('Deep Dark (Default)'),
          leading: Icon(Icons.palette),
        ),
        ListTile(
          title: Text('About'),
          subtitle: Text('DartMini IDE Beta'),
          leading: Icon(Icons.info),
        ),
      ],
    );
  }
}

class _CompilerPresetsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CompilerPresetsTab> createState() => _CompilerPresetsTabState();
}

class _CompilerPresetsTabState extends ConsumerState<_CompilerPresetsTab> {
  CompilerPreset? _selectedPreset;

  void _exportPresets() {
    final state = ref.read(compilerProvider);
    final jsonList = state.presets.map((p) => {
      'id': p.id,
      'name': p.name,
      'endpointUrl': p.endpointUrl,
      'httpMethod': p.httpMethod,
      'authType': p.authType,
      'authValue': p.authValue,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'requestBodyTemplate': p.requestBodyTemplate,
      'responseStdoutPath': p.responseStdoutPath,
      'responseStderrPath': p.responseStderrPath,
      'responseErrorPath': p.responseErrorPath,
      'responseTimePath': p.responseTimePath,
      'responseMemoryPath': p.responseMemoryPath,
      'isDefault': p.isDefault,
    }).toList();
    Clipboard.setData(ClipboardData(text: jsonEncode(jsonList)));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presets exported to clipboard')));
  }

  void _importPresets() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data!.text!);
        for (var item in jsonList) {
          final p = CompilerPreset(
            id: item['id'] ?? const Uuid().v4(),
            name: item['name'] ?? '',
            endpointUrl: item['endpointUrl'] ?? '',
            httpMethod: item['httpMethod'] ?? 'POST',
            authType: item['authType'] ?? 'None',
            authValue: item['authValue'] ?? '',
            headers: Map<String, String>.from(item['headers'] ?? {}),
            queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
            requestBodyTemplate: item['requestBodyTemplate'] ?? '',
            responseStdoutPath: item['responseStdoutPath'] ?? '',
            responseStderrPath: item['responseStderrPath'] ?? '',
            responseErrorPath: item['responseErrorPath'] ?? '',
            responseTimePath: item['responseTimePath'] ?? '',
            responseMemoryPath: item['responseMemoryPath'] ?? '',
            isDefault: item['isDefault'] ?? false,
          );
          ref.read(compilerProvider.notifier).addPreset(p);
        }
        if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presets imported successfully')));}
      } catch (e) {
        if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import: $e')));}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compilerProvider);
    final presets = state.presets;

    return Row(
      children: [
        // Presets List
        Container(
          width: 200,
          color: const Color(0xFF111111),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(icon: const Icon(Icons.download, size: 20), onPressed: () => _exportPresets(), tooltip: 'Export'),
                    IconButton(icon: const Icon(Icons.upload, size: 20), onPressed: () => _importPresets(), tooltip: 'Import'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    final newPreset = CompilerPreset(
                      id: const Uuid().v4(),
                      name: 'New Preset',
                      endpointUrl: 'https://',
                      httpMethod: 'POST',
                      authType: 'None',
                      authValue: '',
                      headers: {},
                      queryParams: {},
                      requestBodyTemplate: '{\n  "code": "{code}"\n}',
                      responseStdoutPath: 'stdout',
                      responseStderrPath: 'stderr',
                      responseErrorPath: '',
                      responseTimePath: '',
                      responseMemoryPath: '',
                      isDefault: false,
                    );
                    ref.read(compilerProvider.notifier).addPreset(newPreset);
                    setState(() => _selectedPreset = newPreset);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Preset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: presets.length,
                  itemBuilder: (ctx, i) {
                    final p = presets[i];
                    final isSelected = _selectedPreset?.id == p.id;
                    return ListTile(
                      title: Text(p.name, style: TextStyle(fontSize: 14, color: isSelected ? const Color(0xFFFACC15) : Colors.white)),
                      selected: isSelected,
                      tileColor: isSelected ? Colors.white10 : null,
                      onTap: () => setState(() => _selectedPreset = p),
                      trailing: p.isDefault
                          ? const Icon(Icons.check_circle, color: Color(0xFFFACC15), size: 16)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Preset Editor
        Expanded(
          child: _selectedPreset == null
              ? const Center(child: Text('Select a preset to edit'))
              : _PresetEditor(preset: _selectedPreset!),
        ),
      ],
    );
  }
}

class _PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const _PresetEditor({required this.preset});

  @override
  ConsumerState<_PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<_PresetEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _outCtrl, _errCtrl, _excCtrl, _timeCtrl, _memCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant _PresetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset.id != widget.preset.id) {
      _initControllers();
    }
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _method = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _authValueCtrl = TextEditingController(text: widget.preset.authValue);
    _bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    _outCtrl = TextEditingController(text: widget.preset.responseStdoutPath);
    _errCtrl = TextEditingController(text: widget.preset.responseStderrPath);
    _excCtrl = TextEditingController(text: widget.preset.responseErrorPath);
    _timeCtrl = TextEditingController(text: widget.preset.responseTimePath);
    _memCtrl = TextEditingController(text: widget.preset.responseMemoryPath);
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      responseStdoutPath: _outCtrl.text,
      responseStderrPath: _errCtrl.text,
      responseErrorPath: _excCtrl.text,
      responseTimePath: _timeCtrl.text,
      responseMemoryPath: _memCtrl.text,
    );
    ref.read(compilerProvider.notifier).updatePreset(updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset saved')));
  }

  void _testConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testing connection...')));

    // Save current state to a temp preset to test
    final tempPreset = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      responseStdoutPath: _outCtrl.text,
      responseStderrPath: _errCtrl.text,
      responseErrorPath: _excCtrl.text,
      responseTimePath: _timeCtrl.text,
      responseMemoryPath: _memCtrl.text,
    );

    final res = await ExecutionService.runCode(
      preset: tempPreset,
      code: "void main() { print('Hello from custom API'); }",
      stdin: "",
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Test Result'),
          content: SingleChildScrollView(
            child: Text('Stdout:\n${res['stdout']}\n\nStderr:\n${res['stderr']}'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Preset Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                if (!widget.preset.isDefault)
                  TextButton(
                    onPressed: () {
                      ref.read(compilerProvider.notifier).setActivePreset(widget.preset.id);
                    },
                    child: const Text('Set as Default', style: TextStyle(color: Color(0xFFFACC15))),
                  ),
                ElevatedButton(
                  onPressed: _testConnection,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  child: const Text('Test Connection'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black),
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name')),
        const SizedBox(height: 8),
        TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _method,
          items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _method = v!),
          decoration: const InputDecoration(labelText: 'HTTP Method'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _authType,
          items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _authType = v!),
          decoration: const InputDecoration(labelText: 'Auth Type'),
        ),
        if (_authType != 'None')
          TextField(controller: _authValueCtrl, decoration: const InputDecoration(labelText: 'Auth Value')),

        const SizedBox(height: 16),
                const SizedBox(height: 16),
        const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold)),
        _KeyValueTable(
          data: widget.preset.headers,
          onChanged: (newData) {
            ref.read(compilerProvider.notifier).updatePreset(widget.preset.copyWith(headers: newData));
          },
        ),

        const SizedBox(height: 16),
        const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold)),
        _KeyValueTable(
          data: widget.preset.queryParams,
          onChanged: (newData) {
            ref.read(compilerProvider.notifier).updatePreset(widget.preset.copyWith(queryParams: newData));
          },
        ),

        const SizedBox(height: 16),
        const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),

        TextField(
          controller: _bodyCtrl,
          maxLines: 8,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'Use {code}, {stdin}, {language}',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),
        const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(controller: _outCtrl, decoration: const InputDecoration(labelText: 'stdout path')),
        TextField(controller: _errCtrl, decoration: const InputDecoration(labelText: 'stderr path')),
        TextField(controller: _excCtrl, decoration: const InputDecoration(labelText: 'error path')),
        TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'execution time path')),
        TextField(controller: _memCtrl, decoration: const InputDecoration(labelText: 'memory path')),
      ],
    );
  }
}
class _KeyValueTable extends StatefulWidget {
  final Map<String, String> data;
  final ValueChanged<Map<String, String>> onChanged;

  const _KeyValueTable({required this.data, required this.onChanged});

  @override
  State<_KeyValueTable> createState() => _KeyValueTableState();
}

class _KeyValueTableState extends State<_KeyValueTable> {
  late List<MapEntry<String, String>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.data.entries.toList();
  }

  @override
  void didUpdateWidget(covariant _KeyValueTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _entries = widget.data.entries.toList();
    }
  }

  void _save() {
    final Map<String, String> newData = {};
    for (var entry in _entries) {
      if (entry.key.isNotEmpty) {
        newData[entry.key] = entry.value;
      }
    }
    widget.onChanged(newData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _entries.length; i++)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _entries[i].key,
                  onChanged: (v) {
                    _entries[i] = MapEntry(v, _entries[i].value);
                    _save();
                  },
                  decoration: const InputDecoration(hintText: 'Key', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _entries[i].value,
                  onChanged: (v) {
                    _entries[i] = MapEntry(_entries[i].key, v);
                    _save();
                  },
                  decoration: const InputDecoration(hintText: 'Value', isDense: true),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  setState(() => _entries.removeAt(i));
                  _save();
                },
              )
            ],
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Row'),
          onPressed: () {
            setState(() => _entries.add(const MapEntry('', '')));
            _save();
          },
        )
      ],
    );
  }
}
