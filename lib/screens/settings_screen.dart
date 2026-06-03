// ignore_for_file: prefer_const_constructors
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Compiler Settings',
                style: TextStyle(color: Color(0xFFFACC15), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use Default OneCompiler (Recommended)'),
                subtitle: const Text('Uses built-in API key for instant execution.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                value: compilerState.useDefaultOneCompiler,
                // ignore: deprecated_member_use
                activeColor: const Color(0xFFFACC15),
                onChanged: (val) => ref.read(compilerProvider.notifier).toggleUseDefaultOneCompiler(val),
              ),
              if (!compilerState.useDefaultOneCompiler) ...[
                const Divider(color: Color(0xFF333333)),
                const Text('Active Custom Preset', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: compilerState.activePresetId.isEmpty ? null : compilerState.activePresetId,
                  dropdownColor: const Color(0xFF1A1A1A),
                  items: compilerState.presets.map((preset) {
                    return DropdownMenuItem(
                      value: preset.id,
                      child: Text(preset.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(compilerProvider.notifier).setActivePreset(val);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Preset',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Preset'),
                        onPressed: () => _openPresetEditor(null),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (compilerState.activePreset != null && compilerState.activePreset!.id != 'onecompiler')
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Active'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A2A2A), foregroundColor: Colors.white),
                          onPressed: () => _openPresetEditor(compilerState.activePreset),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (compilerState.activePreset != null && compilerState.activePreset!.id != 'onecompiler')
                   ElevatedButton(
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                     onPressed: () {
                        ref.read(compilerProvider.notifier).deletePreset(compilerState.activePreset!.id);
                        Fluttertoast.showToast(msg: "Preset deleted");
                     },
                     child: const Text('Delete Active Preset'),
                   ),
              ]
            ],
          );
        }
      ),
    );
  }

  void _openPresetEditor(CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
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

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late String _method;
  late String _authType;
  late TextEditingController _bodyTemplateController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;

  final List<MapEntry<TextEditingController, TextEditingController>> _headers = [];
  final List<MapEntry<TextEditingController, TextEditingController>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _urlController = TextEditingController(text: p?.endpointUrl ?? '');
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _bodyTemplateController = TextEditingController(text: p?.requestBodyTemplate ?? '{\n  "code": "{code}",\n  "stdin": "{stdin}"\n}');
    _stdoutController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrController = TextEditingController(text: p?.stderrPath ?? '');
    _errorController = TextEditingController(text: p?.errorPath ?? '');
    _timeController = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryController = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      p.headers.forEach((k, v) {
        _headers.add(MapEntry(TextEditingController(text: k), TextEditingController(text: v)));
      });
      p.queryParams.forEach((k, v) {
        _queryParams.add(MapEntry(TextEditingController(text: k), TextEditingController(text: v)));
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _bodyTemplateController.dispose();
    _stdoutController.dispose();
    _stderrController.dispose();
    _errorController.dispose();
    _timeController.dispose();
    _memoryController.dispose();
    for (var h in _headers) { h.key.dispose(); h.value.dispose(); }
    for (var q in _queryParams) { q.key.dispose(); q.value.dispose(); }
    super.dispose();
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      Map<String, String> headersMap = {};
      for (var h in _headers) {
        if (h.key.text.isNotEmpty) headersMap[h.key.text] = h.value.text;
      }
      Map<String, String> paramsMap = {};
      for (var q in _queryParams) {
        if (q.key.text.isNotEmpty) paramsMap[q.key.text] = q.value.text;
      }

      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        endpointUrl: _urlController.text,
        method: _method,
        authType: _authType,
        headers: headersMap,
        queryParams: paramsMap,
        requestBodyTemplate: _bodyTemplateController.text,
        stdoutPath: _stdoutController.text,
        stderrPath: _stderrController.text,
        errorPath: _errorController.text,
        executionTimePath: _timeController.text,
        memoryPath: _memoryController.text,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(newPreset);
      }

      ref.read(compilerProvider.notifier).setActivePreset(newPreset.id);

      Fluttertoast.showToast(msg: 'Preset Saved');
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    Fluttertoast.showToast(msg: "Testing connection...");
    try {
      Map<String, String> headersMap = {};
      for (var h in _headers) { if (h.key.text.isNotEmpty) headersMap[h.key.text] = h.value.text; }

      String body = _bodyTemplateController.text;
      String encodedCode = jsonEncode("void main() { print('Hello from custom API'); }");
      encodedCode = encodedCode.substring(1, encodedCode.length - 1);
      body = body.replaceAll('{code}', encodedCode);
      body = body.replaceAll('{stdin}', '');

      Map<String, String> paramsMap = {};
      for (var q in _queryParams) { if (q.key.text.isNotEmpty) paramsMap[q.key.text] = q.value.text; }

      final uri = Uri.parse(_urlController.text).replace(queryParameters: paramsMap.isNotEmpty ? paramsMap : null);

      http.Response response;
      if (_method == 'POST') {
        response = await http.post(uri, headers: headersMap, body: body);
      } else {
        response = await http.get(uri, headers: headersMap);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Test Result: ${response.statusCode}'),
          content: SingleChildScrollView(child: Text(response.body, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );

    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Widget _buildKeyValueList(String title, List<MapEntry<TextEditingController, TextEditingController>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
        const SizedBox(height: 8),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return Padding(
            key: ValueKey('$title-$idx'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: item.key, decoration: const InputDecoration(hintText: 'Key', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: item.value, decoration: const InputDecoration(hintText: 'Value', isDense: true))),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () => setState(() => list.removeAt(idx)),
                )
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => list.add(MapEntry(TextEditingController(), TextEditingController()))),
          icon: const Icon(Icons.add),
          label: const Text('Add Row'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow), tooltip: 'Test Connection', onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save), tooltip: 'Save', onPressed: _savePreset),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Preset Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _method,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    dropdownColor: const Color(0xFF1A1A1A),
                    items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    dropdownColor: const Color(0xFF1A1A1A),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Query Param'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildKeyValueList('Headers', _headers),
            _buildKeyValueList('Query Params', _queryParams),

            const Text('Request Body (JSON Template)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
            const SizedBox(height: 8),
            const Text('Use {code} and {stdin} as placeholders.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateController,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(hintText: '{\n  "content": "{code}"\n}'),
            ),
            const SizedBox(height: 24),

            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
            const SizedBox(height: 8),
            TextFormField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'stdout path (e.g., output.stdout)')),
            const SizedBox(height: 8),
            TextFormField(controller: _stderrController, decoration: const InputDecoration(labelText: 'stderr path')),
            const SizedBox(height: 8),
            TextFormField(controller: _errorController, decoration: const InputDecoration(labelText: 'error path')),
            const SizedBox(height: 8),
            TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'execution time path')),
            const SizedBox(height: 8),
            TextFormField(controller: _memoryController, decoration: const InputDecoration(labelText: 'memory path')),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _savePreset,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Save Preset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
