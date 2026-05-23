import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  final bool isNew;

  const PresetEditorScreen({super.key, required this.preset, required this.isNew});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late String _method;
  late String _authType;
  late TextEditingController _authValueController;
  late TextEditingController _bodyTemplateController;

  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;

  late List<MapEntry<String, String>> _headers;
  late List<MapEntry<String, String>> _queryParams;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _urlController = TextEditingController(text: widget.preset.endpointUrl);
    _method = widget.preset.httpMethod;
    if (_method.isEmpty) _method = 'POST';
    _authType = widget.preset.authType;
    if (_authType.isEmpty) _authType = 'None';
    _authValueController = TextEditingController(text: widget.preset.authValue);
    _bodyTemplateController = TextEditingController(text: widget.preset.bodyTemplate);

    _stdoutController = TextEditingController(text: widget.preset.stdoutPath);
    _stderrController = TextEditingController(text: widget.preset.stderrPath);
    _errorController = TextEditingController(text: widget.preset.errorPath);
    _timeController = TextEditingController(text: widget.preset.executionTimePath);
    _memoryController = TextEditingController(text: widget.preset.memoryPath);

    _headers = widget.preset.headers.map((e) => MapEntry(e['key'].toString(), e['value'].toString())).toList();
    _queryParams = widget.preset.queryParams.map((e) => MapEntry(e['key'].toString(), e['value'].toString())).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _authValueController.dispose();
    _bodyTemplateController.dispose();
    _stdoutController.dispose();
    _stderrController.dispose();
    _errorController.dispose();
    _timeController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameController.text,
      endpointUrl: _urlController.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueController.text,
      bodyTemplate: _bodyTemplateController.text,
      stdoutPath: _stdoutController.text,
      stderrPath: _stderrController.text,
      errorPath: _errorController.text,
      executionTimePath: _timeController.text,
      memoryPath: _memoryController.text,
      headers: _headers.map((e) => {'key': e.key, 'value': e.value}).toList(),
      queryParams: _queryParams.map((e) => {'key': e.key, 'value': e.value}).toList(),
    );

    if (widget.isNew) {
      ref.read(compilerProvider.notifier).addPreset(updated);
    } else {
      ref.read(compilerProvider.notifier).updatePreset(updated);
    }
    Navigator.pop(context);
  }

  Widget _buildDynamicList(String title, List<MapEntry<String, String>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFFACC15)),
              onPressed: () {
                setState(() {
                  list.add(const MapEntry('', ''));
                });
              },
            )
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> kv = entry.value;
          return Padding(
            key: ValueKey('$title-$idx'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: kv.key,
                    decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder()),
                    onChanged: (val) => list[idx] = MapEntry(val, list[idx].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: kv.value,
                    decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                    onChanged: (val) => list[idx] = MapEntry(list[idx].key, val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      list.removeAt(idx);
                    });
                  },
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _method = val);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _authType = val);
              },
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _authValueController,
                decoration: const InputDecoration(labelText: 'Auth Value', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 24),
            _buildDynamicList('Headers', _headers),
            const SizedBox(height: 16),
            _buildDynamicList('Query Params', _queryParams),
            const SizedBox(height: 24),
            const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text(
              'Use {code}, {stdin}, {language} as placeholders. Example:\n{"script": "{code}", "language": "dart"}',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stdoutController,
              decoration: const InputDecoration(labelText: 'stdout path (e.g. data.output)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stderrController,
              decoration: const InputDecoration(labelText: 'stderr path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _errorController,
              decoration: const InputDecoration(labelText: 'error path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'execution time path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoryController,
              decoration: const InputDecoration(labelText: 'memory path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
