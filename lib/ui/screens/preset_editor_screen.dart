
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../models/compiler_preset.dart';
import '../../providers/app_state.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? existingPreset;
  const PresetEditorScreen({Key? key, this.existingPreset}) : super(key: key);

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _endpoint;
  late String _method;
  late String _authType;
  late String _authValue;
  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _timePath;
  late String _memoryPath;

  late List<MapEntry<String, String>> _headers;
  late List<MapEntry<String, String>> _queryParams;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPreset;
    _name = p?.name ?? '';
    _endpoint = p?.endpoint ?? '';
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValue = p?.authValue ?? '';
    _bodyTemplate = p?.bodyTemplate ?? '{}';
    _stdoutPath = p?.stdoutPath ?? '';
    _stderrPath = p?.stderrPath ?? '';
    _errorPath = p?.errorPath ?? '';
    _timePath = p?.timePath ?? '';
    _memoryPath = p?.memoryPath ?? '';

    _headers = p?.headers.entries.toList() ?? [];
    _queryParams = p?.queryParams.entries.toList() ?? [];
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final Map<String, String> hdrs = {};
      for (var e in _headers) {
        if (e.key.trim().isNotEmpty) hdrs[e.key.trim()] = e.value.trim();
      }

      final Map<String, String> qParams = {};
      for (var e in _queryParams) {
        if (e.key.trim().isNotEmpty) qParams[e.key.trim()] = e.value.trim();
      }

      final preset = CompilerPreset(
        id: widget.existingPreset?.id ?? const Uuid().v4(),
        name: _name,
        endpoint: _endpoint,
        method: _method,
        authType: _authType,
        authValue: _authValue,
        headers: hdrs,
        queryParams: qParams,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        timePath: _timePath,
        memoryPath: _memoryPath,
      );

      if (widget.existingPreset == null) {
        ref.read(compilerProvider.notifier).addPreset(preset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(preset);
      }

      Navigator.pop(context);
    }
  }

  Widget _buildDynamicList(String title, List<MapEntry<String, String>> list, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent), onPressed: onAdd),
          ],
        ),
        if (list.isEmpty)
           const Text('No items added.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          return Padding(
            key: ValueKey('${title}_$idx'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: list[idx].key,
                    decoration: const InputDecoration(labelText: 'Key', isDense: true),
                    onChanged: (v) => list[idx] = MapEntry(v, list[idx].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: list[idx].value,
                    decoration: const InputDecoration(labelText: 'Value', isDense: true),
                    onChanged: (v) => list[idx] = MapEntry(list[idx].key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      list.removeAt(idx);
                    });
                  },
                )
              ],
            ),
          );
        })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPreset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Preset Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _endpoint,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _endpoint = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _authValue,
                decoration: const InputDecoration(labelText: 'Auth Value (Token/Key)'),
                onSaved: (v) => _authValue = v ?? '',
              ),
            ],
            const SizedBox(height: 24),
            _buildDynamicList('Headers', _headers, () => setState(() => _headers.add(const MapEntry('', '')))),
            const SizedBox(height: 24),
            _buildDynamicList('Query Params', _queryParams, () => setState(() => _queryParams.add(const MapEntry('', '')))),
            const SizedBox(height: 24),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Use {code}, {stdin}, {language} placeholders. Must be valid JSON if endpoint expects JSON.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _bodyTemplate,
              maxLines: 8,
              decoration: const InputDecoration(hintText: '{\n  "code": "{code}"\n}'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              onSaved: (v) => _bodyTemplate = v ?? '',
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _stdoutPath,
              decoration: const InputDecoration(labelText: 'stdout path (e.g. data.output)'),
              onSaved: (v) => _stdoutPath = v ?? '',
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _stderrPath,
              decoration: const InputDecoration(labelText: 'stderr path'),
              onSaved: (v) => _stderrPath = v ?? '',
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _errorPath,
              decoration: const InputDecoration(labelText: 'error path'),
              onSaved: (v) => _errorPath = v ?? '',
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _timePath,
              decoration: const InputDecoration(labelText: 'execution time path'),
              onSaved: (v) => _timePath = v ?? '',
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _memoryPath,
              decoration: const InputDecoration(labelText: 'memory path'),
              onSaved: (v) => _memoryPath = v ?? '',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
