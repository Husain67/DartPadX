import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/compiler_preset.dart';
import '../../providers/compiler_provider.dart';
import '../theme.dart';

class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditor({super.key, this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _endpointUrl;
  late String _httpMethod;
  late String _authType;
  String? _authKey;
  late List<Map<String, String>> _headers;
  late List<Map<String, String>> _queryParams;
  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _name = p?.name ?? 'New Preset';
    _endpointUrl = p?.endpointUrl ?? '';
    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authKey = p?.authKey;
    _headers = List<Map<String, String>>.from((p?.headers ?? []).map((e) => Map<String, String>.from(e)));
    _queryParams = List<Map<String, String>>.from((p?.queryParams ?? []).map((e) => Map<String, String>.from(e)));
    _bodyTemplate = p?.bodyTemplate ?? '{"content": "{code}"}';
    _stdoutPath = p?.stdoutPath ?? 'stdout';
    _stderrPath = p?.stderrPath ?? 'stderr';
    _errorPath = p?.errorPath ?? 'error';
    _executionTimePath = p?.executionTimePath ?? 'cpuTime';
    _memoryPath = p?.memoryPath ?? 'memory';
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
        authKey: _authKey,
        headers: _headers,
        queryParams: _queryParams,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );
      ref.read(compilerProvider.notifier).savePreset(newPreset);
      Navigator.pop(context);
    }
  }

  Widget _buildMapEditor(String title, List<Map<String, String>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.accentYellow),
              onPressed: () => setState(() => data.add({'key': '', 'value': ''})),
            )
          ],
        ),
        ...data.asMap().entries.map((entry) {
          int idx = entry.key;
          Map<String, String> item = entry.value;
          return Row(
            key: ValueKey('${title}_$idx'),
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item['key'],
                  decoration: const InputDecoration(labelText: 'Key', isDense: true),
                  onChanged: (val) => item['key'] = val,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item['value'],
                  decoration: const InputDecoration(labelText: 'Value', isDense: true),
                  onChanged: (val) => item['value'] = val,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => data.removeAt(idx)),
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
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: AppTheme.accentYellow), onPressed: _save),
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
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _name = val!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _endpointUrl,
                    decoration: const InputDecoration(labelText: 'Endpoint URL'),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => _endpointUrl = val!,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppTheme.accentYellow),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _endpointUrl));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endpoint copied to clipboard')));
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _httpMethod = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => _authType = val!),
            ),
            if (_authType != 'None')
              TextFormField(
                initialValue: _authKey,
                decoration: InputDecoration(labelText: 'Auth Key/Token (for $_authType)'),
                onSaved: (val) => _authKey = val,
              ),
            const Divider(height: 32),
            _buildMapEditor('Headers', _headers),
            const Divider(height: 32),
            _buildMapEditor('Query Parameters', _queryParams),
            const Divider(height: 32),
            TextFormField(
              initialValue: _bodyTemplate,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Request Body Template (JSON)',
                helperText: 'Use placeholders: {code}, {stdin}, {language}',
              ),
              onSaved: (val) => _bodyTemplate = val ?? '',
            ),
            const Divider(height: 32),
            const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textLight)),
            const SizedBox(height: 8),
            TextFormField(initialValue: _stdoutPath, decoration: const InputDecoration(labelText: 'stdout path'), onSaved: (val) => _stdoutPath = val ?? ''),
            TextFormField(initialValue: _stderrPath, decoration: const InputDecoration(labelText: 'stderr path'), onSaved: (val) => _stderrPath = val ?? ''),
            TextFormField(initialValue: _errorPath, decoration: const InputDecoration(labelText: 'error path'), onSaved: (val) => _errorPath = val ?? ''),
            TextFormField(initialValue: _executionTimePath, decoration: const InputDecoration(labelText: 'execution time path'), onSaved: (val) => _executionTimePath = val ?? ''),
            TextFormField(initialValue: _memoryPath, decoration: const InputDecoration(labelText: 'memory path'), onSaved: (val) => _memoryPath = val ?? ''),
          ],
        ),
      ),
    );
  }
}
