import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/preset_provider.dart';
import '../../data/compiler_preset.dart';
import 'package:uuid/uuid.dart';
import '../../providers/execution_provider.dart';

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
  late TextEditingController _bodyController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;

  String _method = 'POST';
  String _authType = 'None';

  // Headers list for dynamic table
  List<MapEntry<TextEditingController, TextEditingController>> _headers = [];
  // Query Params list for dynamic table
  List<MapEntry<TextEditingController, TextEditingController>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _urlController = TextEditingController(text: p?.endpointUrl ?? '');
    _bodyController = TextEditingController(text: p?.requestBodyTemplate ?? '');
    _stdoutController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrController = TextEditingController(text: p?.stderrPath ?? '');
    _errorController = TextEditingController(text: p?.errorPath ?? '');
    _timeController = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryController = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _method = p.httpMethod;
      _authType = p.authType;
      p.headers.forEach((k, v) {
        _headers.add(MapEntry(TextEditingController(text: k), TextEditingController(text: v)));
      });
      p.queryParams.forEach((k, v) {
        _queryParams.add(MapEntry(TextEditingController(text: k), TextEditingController(text: v)));
      });
    } else {
      _headers.add(MapEntry(TextEditingController(text: 'Content-Type'), TextEditingController(text: 'application/json')));
    }
  }

  CompilerPreset _buildTempPreset() {
    Map<String, String> headersMap = {};
    for (var entry in _headers) {
      if (entry.key.text.isNotEmpty) {
        headersMap[entry.key.text] = entry.value.text;
      }
    }

    Map<String, String> queryParamsMap = {};
    for (var entry in _queryParams) {
      if (entry.key.text.isNotEmpty) {
        queryParamsMap[entry.key.text] = entry.value.text;
      }
    }

    return CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameController.text,
      endpointUrl: _urlController.text,
      httpMethod: _method,
      authType: _authType,
      headers: headersMap,
      queryParams: queryParamsMap,
      requestBodyTemplate: _bodyController.text,
      stdoutPath: _stdoutController.text,
      stderrPath: _stderrController.text,
      errorPath: _errorController.text,
      executionTimePath: _timeController.text,
      memoryPath: _memoryController.text,
    );
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      final newPreset = _buildTempPreset();
      if (widget.preset == null) {
        ref.read(presetProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(presetProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Custom API' : 'Edit API Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _savePreset),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Platform Name (e.g. JDoodle)'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Endpoint URL',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {}, // Implementation placeholder
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _method,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.accent),
                  onPressed: () {
                    setState(() => _headers.add(MapEntry(TextEditingController(), TextEditingController())));
                  },
                ),
              ],
            ),
            ..._headers.asMap().entries.map((entry) {
              int idx = entry.key;
              var kv = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(child: TextFormField(controller: kv.key, decoration: const InputDecoration(hintText: 'Key'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: kv.value, decoration: const InputDecoration(hintText: 'Value'))),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: AppColors.outputRed),
                      onPressed: () => setState(() => _headers.removeAt(idx)),
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.accent),
                  onPressed: () {
                    setState(() => _queryParams.add(MapEntry(TextEditingController(), TextEditingController())));
                  },
                ),
              ],
            ),
            ..._queryParams.asMap().entries.map((entry) {
              int idx = entry.key;
              var kv = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(child: TextFormField(controller: kv.key, decoration: const InputDecoration(hintText: 'Key'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: kv.value, decoration: const InputDecoration(hintText: 'Value'))),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: AppColors.outputRed),
                      onPressed: () => setState(() => _queryParams.removeAt(idx)),
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            const Text('Request Body JSON Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '{"script": "{code}", "language": "{language}"}',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'stdout path')),
            const SizedBox(height: 8),
            TextFormField(controller: _stderrController, decoration: const InputDecoration(labelText: 'stderr path')),
            const SizedBox(height: 8),
            TextFormField(controller: _errorController, decoration: const InputDecoration(labelText: 'error path')),
            const SizedBox(height: 8),
            TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'execution time path')),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final tempPreset = _buildTempPreset();
                  ref.read(executionProvider.notifier).testCustomPreset(tempPreset);
                  Navigator.pop(context);
                }
              },
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
