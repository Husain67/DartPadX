import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _authKeyCtrl;
  late final TextEditingController _authValueCtrl;
  late final TextEditingController _bodyCtrl;

  // Mapping
  late final TextEditingController _stdoutCtrl;
  late final TextEditingController _stderrCtrl;
  late final TextEditingController _errorCtrl;
  late final TextEditingController _execTimeCtrl;
  late final TextEditingController _memoryCtrl;

  late String _method;
  late String _authType;

  late List<MapEntry<String, String>> _headers;
  late List<MapEntry<String, String>> _queryParams;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _authKeyCtrl = TextEditingController(text: widget.preset.authKey);
    _authValueCtrl = TextEditingController(text: widget.preset.authValue);
    _bodyCtrl = TextEditingController(text: widget.preset.bodyTemplate);

    _stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorCtrl = TextEditingController(text: widget.preset.errorPath);
    _execTimeCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memoryCtrl = TextEditingController(text: widget.preset.memoryPath);

    _method = widget.preset.httpMethod;
    if (!['GET', 'POST', 'PUT'].contains(_method)) _method = 'POST';

    _authType = widget.preset.authType;
    if (!['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].contains(_authType)) {
      _authType = 'None';
    }

    _headers = widget.preset.headers.entries.toList();
    _queryParams = widget.preset.queryParams.entries.toList();
  }

  void _save() {
    final newPreset = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authKey: _authKeyCtrl.text,
      authValue: _authValueCtrl.text,
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _execTimeCtrl.text,
      memoryPath: _memoryCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
    );

    ref.read(settingsProvider.notifier).savePreset(newPreset);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Preset Name')),
            const SizedBox(height: 16),
            TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _method,
              items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
              decoration: const InputDecoration(labelText: 'HTTP Method'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
              decoration: const InputDecoration(labelText: 'Auth Type'),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              if (_authType == 'API-Key Header' || _authType == 'Query Param')
                TextField(controller: _authKeyCtrl, decoration: const InputDecoration(labelText: 'Auth Key')),
              TextField(controller: _authValueCtrl, decoration: const InputDecoration(labelText: 'Auth Value'), obscureText: true),
            ],
            const SizedBox(height: 16),
            const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._headers.asMap().entries.map((e) => Row(
              children: [
                Expanded(child: TextFormField(initialValue: e.value.key, onChanged: (v) => _headers[e.key] = MapEntry(v, e.value.value))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(initialValue: e.value.value, onChanged: (v) => _headers[e.key] = MapEntry(e.value.key, v))),
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _headers.removeAt(e.key))),
              ],
            )),
            TextButton(onPressed: () => setState(() => _headers.add(const MapEntry('', ''))), child: const Text('Add Header')),

            const SizedBox(height: 16),
            const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._queryParams.asMap().entries.map((e) => Row(
              children: [
                Expanded(child: TextFormField(initialValue: e.value.key, onChanged: (v) => _queryParams[e.key] = MapEntry(v, e.value.value))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(initialValue: e.value.value, onChanged: (v) => _queryParams[e.key] = MapEntry(e.value.key, v))),
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _queryParams.removeAt(e.key))),
              ],
            )),
            TextButton(onPressed: () => setState(() => _queryParams.add(const MapEntry('', ''))), child: const Text('Add Query Param')),

            const SizedBox(height: 16),
            const Text('Body Template ({code}, {stdin})', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _bodyCtrl, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder())),

            const SizedBox(height: 16),
            const Text('Response Mapping', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'Stdout Path (e.g. output.run)')),
            TextField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'Stderr Path')),
            TextField(controller: _errorCtrl, decoration: const InputDecoration(labelText: 'Error Path')),
            TextField(controller: _execTimeCtrl, decoration: const InputDecoration(labelText: 'Execution Time Path')),
            TextField(controller: _memoryCtrl, decoration: const InputDecoration(labelText: 'Memory Path')),
          ],
        ),
      ),
    );
  }
}
