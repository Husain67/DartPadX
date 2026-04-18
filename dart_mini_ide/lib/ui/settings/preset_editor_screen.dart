import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/compiler_preset.dart';
import '../../providers/execution_provider.dart';
import '../../theme/app_theme.dart';

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
  late String _authType;
  late String _authValue;
  late String _requestBodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final List<String> _methods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _name = p?.name ?? 'New Preset';
    _endpointUrl = p?.endpointUrl ?? '';
    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValue = p?.authValue ?? '';
    _requestBodyTemplate = p?.requestBodyTemplate ?? '{\n  "code": "{code}",\n  "language": "{language}"\n}';
    _stdoutPath = p?.stdoutPath ?? '';
    _stderrPath = p?.stderrPath ?? '';
    _errorPath = p?.errorPath ?? '';
    _executionTimePath = p?.executionTimePath ?? '';
    _memoryPath = p?.memoryPath ?? '';

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _name,
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        authType: _authType,
        authValue: _authValue,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _requestBodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );

      final box = ref.read(compilerPresetBoxProvider);
      box.put(newPreset.id, newPreset);
      Navigator.pop(context);
    }
  }

  Widget _buildDynamicMapSection(String title, List<MapEntry<String, String>> entries, Function(List<MapEntry<String, String>>) update) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.accentYellow),
              onPressed: () {
                setState(() {
                  entries.add(const MapEntry('', ''));
                  update(entries);
                });
              },
            )
          ],
        ),
        ...entries.asMap().entries.map((e) {
          int idx = e.key;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: e.value.key,
                  decoration: const InputDecoration(labelText: 'Key', isDense: true),
                  onChanged: (v) {
                    entries[idx] = MapEntry(v, entries[idx].value);
                    update(entries);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: e.value.value,
                  decoration: const InputDecoration(labelText: 'Value', isDense: true),
                  onChanged: (v) {
                    entries[idx] = MapEntry(entries[idx].key, v);
                    update(entries);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  setState(() {
                    entries.removeAt(idx);
                    update(entries);
                  });
                },
              )
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'Add Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Connection (Dummy Output)'),
              onPressed: () {
                _save(); // First save to box
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test connection is only available via the Run button on the main screen.')));
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _endpointUrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => _endpointUrl = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _httpMethod = v!),
              onSaved: (v) => _httpMethod = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: _authTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
              onSaved: (v) => _authType = v!,
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _authValue,
                decoration: InputDecoration(labelText: 'Auth Value (${_authType == "API-Key Header" ? "Header-Key:Value" : "Token/Basic"})'),
                onSaved: (v) => _authValue = v!,
              ),
            ],
            const SizedBox(height: 24),
            _buildDynamicMapSection('Headers', _headers, (v) => _headers = v),
            const SizedBox(height: 16),
            _buildDynamicMapSection('Query Params', _queryParams, (v) => _queryParams = v),
            const SizedBox(height: 24),
            const Text('Request Body (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language} placeholders.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _requestBodyTemplate,
              maxLines: 8,
              decoration: const InputDecoration(hintText: '{\n  "code": "{code}"\n}'),
              style: const TextStyle(fontFamily: 'monospace'),
              onSaved: (v) => _requestBodyTemplate = v ?? '{}',
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping Paths (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(initialValue: _stdoutPath, decoration: const InputDecoration(labelText: 'stdout path (e.g. data.output)'), onSaved: (v) => _stdoutPath = v!),
            const SizedBox(height: 8),
            TextFormField(initialValue: _stderrPath, decoration: const InputDecoration(labelText: 'stderr path'), onSaved: (v) => _stderrPath = v!),
            const SizedBox(height: 8),
            TextFormField(initialValue: _errorPath, decoration: const InputDecoration(labelText: 'error path'), onSaved: (v) => _errorPath = v!),
            const SizedBox(height: 8),
            TextFormField(initialValue: _executionTimePath, decoration: const InputDecoration(labelText: 'executionTime path'), onSaved: (v) => _executionTimePath = v!),
            const SizedBox(height: 8),
            TextFormField(initialValue: _memoryPath, decoration: const InputDecoration(labelText: 'memory path'), onSaved: (v) => _memoryPath = v!),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
