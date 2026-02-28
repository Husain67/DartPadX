import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class AddPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset? presetToEdit;

  const AddPresetScreen({super.key, this.presetToEdit});

  @override
  ConsumerState<AddPresetScreen> createState() => _AddPresetScreenState();
}

class _AddPresetScreenState extends ConsumerState<AddPresetScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late String _httpMethod;
  late String _authType;
  late TextEditingController _bodyTemplateController;
  late TextEditingController _stdoutPathController;
  late TextEditingController _stderrPathController;
  late TextEditingController _errorPathController;
  late TextEditingController _executionTimePathController;
  late TextEditingController _memoryPathController;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();

    final p = widget.presetToEdit;
    _nameController = TextEditingController(text: p?.name ?? '');
    _urlController = TextEditingController(text: p?.endpointUrl ?? '');
    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _bodyTemplateController = TextEditingController(text: p?.requestBodyTemplate ?? '{"code": "{code}"}');
    _stdoutPathController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathController = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathController = TextEditingController(text: p?.errorPath ?? '');
    _executionTimePathController = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathController = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _bodyTemplateController.dispose();
    _stdoutPathController.dispose();
    _stderrPathController.dispose();
    _errorPathController.dispose();
    _executionTimePathController.dispose();
    _memoryPathController.dispose();
    super.dispose();
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      final preset = CompilerPreset(
        id: widget.presetToEdit?.id ?? _uuid.v4(),
        name: _nameController.text,
        endpointUrl: _urlController.text,
        httpMethod: _httpMethod,
        authType: _authType,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _bodyTemplateController.text,
        stdoutPath: _stdoutPathController.text,
        stderrPath: _stderrPathController.text,
        errorPath: _errorPathController.text,
        executionTimePath: _executionTimePathController.text,
        memoryPath: _memoryPathController.text,
      );

      if (widget.presetToEdit == null) {
        ref.read(settingsProvider.notifier).addPreset(preset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(preset);
      }

      Navigator.of(context).pop();
    }
  }

  Widget _buildMapEditor(String title, List<MapEntry<String, String>> mapList, void Function(List<MapEntry<String, String>>) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
              onPressed: () {
                setState(() {
                  mapList.add(const MapEntry('', ''));
                });
              },
            )
          ],
        ),
        ...mapList.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> kv = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: kv.key,
                    decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder()),
                    onChanged: (val) {
                      mapList[idx] = MapEntry(val, kv.value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: kv.value,
                    decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                    onChanged: (val) {
                      mapList[idx] = MapEntry(kv.key, val);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      mapList.removeAt(idx);
                    });
                  },
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Text(widget.presetToEdit == null ? 'Add Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreset,
          )
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
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
              items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _httpMethod = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _authType = val!),
            ),
            const SizedBox(height: 24),
            _buildMapEditor('Headers', _headers, (val) => setState(() => _headers = val)),
            const SizedBox(height: 24),
            _buildMapEditor('Query Params', _queryParams, (val) => setState(() => _queryParams = val)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _bodyTemplateController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Request Body Template (JSON)',
                border: OutlineInputBorder(),
                hintText: 'Use {code}, {stdin}, {language}, {name}',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stdoutPathController,
              decoration: const InputDecoration(labelText: 'stdout path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stderrPathController,
              decoration: const InputDecoration(labelText: 'stderr path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _errorPathController,
              decoration: const InputDecoration(labelText: 'error path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _executionTimePathController,
              decoration: const InputDecoration(labelText: 'executionTime path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoryPathController,
              decoration: const InputDecoration(labelText: 'memory path', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
