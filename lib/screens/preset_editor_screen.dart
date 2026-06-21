import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../providers/execution_provider.dart';
import 'dart:math';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _url;
  late String _method;
  late String _authType;
  late String _authValue;

  // Use a class with an ID instead of MapEntry to maintain state and allow ValueKey matching.
  late List<_DynamicField> _headers;
  late List<_DynamicField> _queryParams;

  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  @override
  void initState() {
    super.initState();
    final p = widget.preset ?? CompilerPreset(
      id: '', name: 'New Preset', url: 'https://',
    );
    _name = p.name;
    _url = p.url;
    _method = p.method;
    _authType = p.authType;
    _authValue = p.authValue;
    _headers = p.headers.entries.map((e) => _DynamicField(e.key, e.value)).toList();
    _queryParams = p.queryParams.entries.map((e) => _DynamicField(e.key, e.value)).toList();
    _bodyTemplate = p.bodyTemplate;
    _stdoutPath = p.stdoutPath;
    _stderrPath = p.stderrPath;
    _errorPath = p.errorPath;
    _executionTimePath = p.executionTimePath;
    _memoryPath = p.memoryPath;
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final headersMap = {for (var e in _headers) if (e.key.isNotEmpty) e.key: e.value};
      final queryMap = {for (var e in _queryParams) if (e.key.isNotEmpty) e.key: e.value};

      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? '',
        name: _name,
        url: _url,
        method: _method,
        authType: _authType,
        authValue: _authValue,
        headers: headersMap,
        queryParams: queryMap,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
        isBuiltIn: widget.preset?.isBuiltIn ?? false,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  void _testConnection() async {
    _formKey.currentState?.save();

    // Switch active preset to test and execute hello world
    final headersMap = {for (var e in _headers) if (e.key.isNotEmpty) e.key: e.value};
    final queryMap = {for (var e in _queryParams) if (e.key.isNotEmpty) e.key: e.value};

    final tempPreset = CompilerPreset(
      id: 'test_preset',
      name: 'Test',
      url: _url,
      method: _method,
      authType: _authType,
      authValue: _authValue,
      headers: headersMap,
      queryParams: queryMap,
      bodyTemplate: _bodyTemplate,
      stdoutPath: _stdoutPath,
      stderrPath: _stderrPath,
      errorPath: _errorPath,
      executionTimePath: _executionTimePath,
      memoryPath: _memoryPath,
      isBuiltIn: false,
    );

    // Temporarily add and switch to it for test
    ref.read(compilerProvider.notifier).addPreset(tempPreset);
    final previousActive = ref.read(compilerProvider).activePresetId;
    ref.read(compilerProvider.notifier).setActivePreset(tempPreset.id);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator())
      );

      await ref.read(executionProvider.notifier).executeCode("void main() { print('Hello from custom API'); }", "");

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        final result = ref.read(executionProvider);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Test Result'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('STDOUT:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(result.stdout.isNotEmpty ? result.stdout : 'None'),
                  const SizedBox(height: 8),
                  const Text('STDERR/ERROR:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(result.stderr.isNotEmpty ? result.stderr : 'None', style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
      }
    } finally {
      ref.read(compilerProvider.notifier).setActivePreset(previousActive);
      ref.read(compilerProvider.notifier).deletePreset(tempPreset.id);
    }
  }

  Widget _buildDynamicList(String title, List<_DynamicField> list, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
          ],
        ),
        ...list.map((field) {
          return Padding(
            key: ValueKey(field.id),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: field.key,
                    decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder()),
                    onChanged: (v) => field.key = v,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: field.value,
                    decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                    onChanged: (v) => field.value = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => list.removeWhere((f) => f.id == field.id)),
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
          IconButton(icon: const Icon(Icons.play_arrow), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save), onPressed: _save, tooltip: 'Save'),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              onSaved: (v) => _name = v ?? '',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _url,
              decoration: InputDecoration(
                labelText: 'Endpoint URL',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    // Copy URL feature
                  },
                ),
              ),
              onSaved: (v) => _url = v ?? '',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _method,
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
              decoration: const InputDecoration(labelText: 'HTTP Method'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType,
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
              decoration: const InputDecoration(labelText: 'Auth Type'),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _authValue,
                decoration: const InputDecoration(labelText: 'Auth Value'),
                onSaved: (v) => _authValue = v ?? '',
              ),
            ],
            const SizedBox(height: 24),
            _buildDynamicList('Headers', _headers, () => setState(() => _headers.add(_DynamicField('', '')))),
            const SizedBox(height: 16),
            _buildDynamicList('Query Params', _queryParams, () => setState(() => _queryParams.add(_DynamicField('', '')))),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _bodyTemplate,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Request Body Template (JSON)',
                hintText: '{code}, {stdin}, {language} placeholders',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onSaved: (v) => _bodyTemplate = v ?? '',
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _stdoutPath,
              decoration: const InputDecoration(labelText: 'stdout path'),
              onSaved: (v) => _stdoutPath = v ?? '',
            ),
            TextFormField(
              initialValue: _stderrPath,
              decoration: const InputDecoration(labelText: 'stderr path'),
              onSaved: (v) => _stderrPath = v ?? '',
            ),
            TextFormField(
              initialValue: _errorPath,
              decoration: const InputDecoration(labelText: 'error path'),
              onSaved: (v) => _errorPath = v ?? '',
            ),
            TextFormField(
              initialValue: _executionTimePath,
              decoration: const InputDecoration(labelText: 'executionTime path'),
              onSaved: (v) => _executionTimePath = v ?? '',
            ),
            TextFormField(
              initialValue: _memoryPath,
              decoration: const InputDecoration(labelText: 'memory path'),
              onSaved: (v) => _memoryPath = v ?? '',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DynamicField {
  final String id;
  String key;
  String value;

  _DynamicField(this.key, this.value) : id = Random().nextInt(1000000).toString();
}
