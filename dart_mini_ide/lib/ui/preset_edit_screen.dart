import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';

class PresetEditScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  final bool isNew;

  const PresetEditScreen({super.key, required this.preset, this.isNew = false});

  @override
  ConsumerState<PresetEditScreen> createState() => _PresetEditScreenState();
}

class _PresetEditScreenState extends ConsumerState<PresetEditScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _execTimeCtrl;
  late TextEditingController _memoryCtrl;
  late TextEditingController _errorCtrl;

  String _httpMethod = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _bodyCtrl = TextEditingController(text: widget.preset.bodyTemplate);
    _stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    _execTimeCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memoryCtrl = TextEditingController(text: widget.preset.memoryPath);
    _errorCtrl = TextEditingController(text: widget.preset.errorPath);

    _httpMethod = widget.preset.httpMethod;
    _authType = widget.preset.authType;

    _headers = widget.preset.headers.entries.toList();
    _queryParams = widget.preset.queryParams.entries.toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutCtrl.dispose();
    _stderrCtrl.dispose();
    _execTimeCtrl.dispose();
    _memoryCtrl.dispose();
    _errorCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      executionTimePath: _execTimeCtrl.text,
      memoryPath: _memoryCtrl.text,
      errorPath: _errorCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: Map.fromEntries(_headers.where((e) => e.key.isNotEmpty)),
      queryParams: Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty)),
    );

    if (widget.isNew) {
      ref.read(compilerProvider.notifier).addPreset(updated);
    } else {
      ref.read(compilerProvider.notifier).updatePreset(updated);
    }
    Navigator.pop(context);
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name')),
          const SizedBox(height: 16),
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _httpMethod,
            decoration: const InputDecoration(labelText: 'HTTP Method'),
            items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) { if (v != null) setState(() => _httpMethod = v); },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _authType,
            decoration: const InputDecoration(labelText: 'Auth Type'),
            items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) { if (v != null) setState(() => _authType = v); },
          ),
          const SizedBox(height: 24),
          _buildDynamicTable('Headers', _headers, () => setState(() => _headers.add(const MapEntry('', '')))),
          const SizedBox(height: 24),
          _buildDynamicTable('Query Params', _queryParams, () => setState(() => _queryParams.add(const MapEntry('', '')))),
          const SizedBox(height: 24),
          TextField(
            controller: _bodyCtrl,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'JSON Body Template', helperText: 'Use {code}, {stdin}, {language}'),
          ),
          const SizedBox(height: 24),
          const Text('Response Mapping Paths', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'Stdout Path (e.g. data.stdout)')),
          const SizedBox(height: 16),
          TextField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'Stderr Path')),
          const SizedBox(height: 16),
          TextField(controller: _errorCtrl, decoration: const InputDecoration(labelText: 'Error Path')),
          const SizedBox(height: 16),
          TextField(controller: _execTimeCtrl, decoration: const InputDecoration(labelText: 'Execution Time Path')),
          const SizedBox(height: 16),
          TextField(controller: _memoryCtrl, decoration: const InputDecoration(labelText: 'Memory Path')),
        ],
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> items, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(icon: const Icon(Icons.add), label: const Text('Add Row'), onPressed: onAdd),
          ],
        ),
        ...items.asMap().entries.map((e) {
          int idx = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(child: TextFormField(
                  initialValue: e.value.key,
                  decoration: const InputDecoration(labelText: 'Key'),
                  onChanged: (v) => setState(() => items[idx] = MapEntry(v, items[idx].value)),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(
                  initialValue: e.value.value,
                  decoration: const InputDecoration(labelText: 'Value'),
                  onChanged: (v) => setState(() => items[idx] = MapEntry(items[idx].key, v)),
                )),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => items.removeAt(idx)),
                ),
              ],
            ),
          );
        })
      ],
    );
  }
}
