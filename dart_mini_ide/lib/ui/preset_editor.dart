import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/preset_provider.dart';

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
  late TextEditingController _authValueController;
  late TextEditingController _bodyController;

  late TextEditingController _stdoutPathController;
  late TextEditingController _stderrPathController;
  late TextEditingController _errorPathController;
  late TextEditingController _timePathController;
  late TextEditingController _memoryPathController;

  String _httpMethod = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final p = widget.preset;

    _nameController = TextEditingController(text: p?.name ?? 'New Preset');
    _urlController = TextEditingController(text: p?.endpointUrl ?? '');
    _authValueController = TextEditingController(text: p?.authValue ?? '');
    _bodyController = TextEditingController(text: p?.bodyTemplate ?? '{}');

    _stdoutPathController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathController = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathController = TextEditingController(text: p?.errorPath ?? '');
    _timePathController = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathController = TextEditingController(text: p?.memoryPath ?? '');

    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _authValueController.dispose();
    _bodyController.dispose();
    _stdoutPathController.dispose();
    _stderrPathController.dispose();
    _errorPathController.dispose();
    _timePathController.dispose();
    _memoryPathController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final Map<String, String> headersMap = {};
      for (var e in _headers) {
        if (e.key.trim().isNotEmpty) headersMap[e.key.trim()] = e.value;
      }

      final Map<String, String> queryMap = {};
      for (var e in _queryParams) {
        if (e.key.trim().isNotEmpty) queryMap[e.key.trim()] = e.value;
      }

      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? _uuid.v4(),
        name: _nameController.text.trim(),
        endpointUrl: _urlController.text.trim(),
        httpMethod: _httpMethod,
        authType: _authType,
        authValue: _authValueController.text.trim(),
        headers: headersMap,
        queryParams: queryMap,
        bodyTemplate: _bodyController.text,
        stdoutPath: _stdoutPathController.text.trim(),
        stderrPath: _stderrPathController.text.trim(),
        errorPath: _errorPathController.text.trim(),
        executionTimePath: _timePathController.text.trim(),
        memoryPath: _memoryPathController.text.trim(),
      );

      ref.read(presetProvider.notifier).savePreset(newPreset);
      ref.read(selectedPresetIdProvider.notifier).state = newPreset.id;
      Navigator.pop(context);
    }
  }

  Widget _buildMapEditor(String title, List<MapEntry<String, String>> entries, VoidCallback onAdd, Function(int) onRemove, Function(int, String, String) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onAdd),
          ],
        ),
        ...entries.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.key,
                    decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder()),
                    onChanged: (val) => onUpdate(idx, val, entry.value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value,
                    decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                    onChanged: (val) => onUpdate(idx, entry.key, val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => onRemove(idx),
                ),
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
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                    initialValue: _httpMethod,
                    items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _httpMethod = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                    initialValue: _authType,
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _authValueController,
                decoration: const InputDecoration(labelText: 'Auth Value (Token/Key)', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 24),
            _buildMapEditor(
              'Headers',
              _headers,
              () => setState(() => _headers.add(const MapEntry('', ''))),
              (idx) => setState(() => _headers.removeAt(idx)),
              (idx, k, v) => setState(() => _headers[idx] = MapEntry(k, v)),
            ),
            const SizedBox(height: 16),
            _buildMapEditor(
              'Query Params',
              _queryParams,
              () => setState(() => _queryParams.add(const MapEntry('', ''))),
              (idx) => setState(() => _queryParams.removeAt(idx)),
              (idx, k, v) => setState(() => _queryParams[idx] = MapEntry(k, v)),
            ),
            const SizedBox(height: 24),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyController,
              maxLines: 8,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (JSON Path Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(controller: _stdoutPathController, decoration: const InputDecoration(labelText: 'stdout path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _stderrPathController, decoration: const InputDecoration(labelText: 'stderr path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _errorPathController, decoration: const InputDecoration(labelText: 'error path (fallback)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _timePathController, decoration: const InputDecoration(labelText: 'execution time path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _memoryPathController, decoration: const InputDecoration(labelText: 'memory path', border: OutlineInputBorder())),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
