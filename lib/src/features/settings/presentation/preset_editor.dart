import 'package:flutter/material.dart';
import 'package:dartmini_ide/src/features/settings/presentation/test_connection_dialog.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dartmini_ide/src/features/settings/domain/compiler_preset.dart';
import 'package:dartmini_ide/src/features/settings/providers/compiler_provider.dart';

class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditor({super.key, this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _bodyController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memController;

  String _httpMethod = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _urlController = TextEditingController(text: widget.preset?.endpointUrl ?? '');
    _bodyController = TextEditingController(text: widget.preset?.requestBodyTemplate ?? '');
    _stdoutController = TextEditingController(text: widget.preset?.stdoutPath ?? '');
    _stderrController = TextEditingController(text: widget.preset?.stderrPath ?? '');
    _errorController = TextEditingController(text: widget.preset?.errorPath ?? '');
    _timeController = TextEditingController(text: widget.preset?.executionTimePath ?? '');
    _memController = TextEditingController(text: widget.preset?.memoryPath ?? '');

    if (widget.preset != null) {
      _httpMethod = widget.preset!.httpMethod;
      _authType = widget.preset!.authType;
      _headers = widget.preset!.headers.entries.toList();
      _queryParams = widget.preset!.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    _stdoutController.dispose();
    _stderrController.dispose();
    _errorController.dispose();
    _timeController.dispose();
    _memController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameController.text,
        endpointUrl: _urlController.text,
        httpMethod: _httpMethod,
        authType: _authType,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _bodyController.text,
        stdoutPath: _stdoutController.text,
        stderrPath: _stderrController.text,
        errorPath: _errorController.text,
        executionTimePath: _timeController.text,
        memoryPath: _memController.text,
        isPreloaded: widget.preset?.isPreloaded ?? false,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(newPreset);
      }

      Navigator.pop(context);
    }
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> items, void Function(List<MapEntry<String, String>>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('', ''));
                  onChanged(items);
                });
              },
            ),
          ],
        ),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          return Padding(
            key: ValueKey('${title}_$idx'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value.key,
                    decoration: const InputDecoration(hintText: 'Key'),
                    onChanged: (val) {
                      items[idx] = MapEntry(val, items[idx].value);
                      onChanged(items);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value.value,
                    decoration: const InputDecoration(hintText: 'Value'),
                    onChanged: (val) {
                      items[idx] = MapEntry(items[idx].key, val);
                      onChanged(items);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      items.removeAt(idx);
                      onChanged(items);
                    });
                  },
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
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _httpMethod = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            const Divider(height: 32),
            _buildDynamicTable('Headers', _headers, (v) => _headers = v),
            const Divider(height: 32),
            _buildDynamicTable('Query Params', _queryParams, (v) => _queryParams = v),
            const Divider(height: 32),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'e.g. {"code": "{code}", "stdin": "{stdin}"}'),
            ),
            const Divider(height: 32),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'stdout path')),
            const SizedBox(height: 8),
            TextFormField(controller: _stderrController, decoration: const InputDecoration(labelText: 'stderr path')),
            const SizedBox(height: 8),
            TextFormField(controller: _errorController, decoration: const InputDecoration(labelText: 'error path')),
            const SizedBox(height: 8),
            TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'executionTime path')),
            const SizedBox(height: 8),
            TextFormField(controller: _memController, decoration: const InputDecoration(labelText: 'memory path')),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final tempPreset = CompilerPreset(
                    id: widget.preset?.id ?? const Uuid().v4(),
                    name: _nameController.text,
                    endpointUrl: _urlController.text,
                    httpMethod: _httpMethod,
                    authType: _authType,
                    headers: Map.fromEntries(_headers),
                    queryParams: Map.fromEntries(_queryParams),
                    requestBodyTemplate: _bodyController.text,
                    stdoutPath: _stdoutController.text,
                    stderrPath: _stderrController.text,
                    errorPath: _errorController.text,
                    executionTimePath: _timeController.text,
                    memoryPath: _memController.text,
                  );
                  showDialog(
                    context: context,
                    builder: (context) => TestConnectionDialog(preset: tempPreset),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Test Connection', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
