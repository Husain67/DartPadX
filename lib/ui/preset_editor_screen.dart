import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/compiler_preset.dart';
import '../providers/preset_provider.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset; // Null means new

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late CompilerPreset _editablePreset;


  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _editablePreset = widget.preset!.copyWith();
    } else {
      _editablePreset = CompilerPreset(
        id: const Uuid().v4(),
        platformName: 'New Preset',
        endpointUrl: 'https://',
        httpMethod: 'POST',
        authType: 'None',
      );
    }
  }

  Future<void> _testConnection() async {
    final code = "void main() { print('Hello from custom API'); }";
    final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    final bodyStr = _editablePreset.requestBodyTemplate
        .replaceAll('{code}', '"$safeCode"')
        .replaceAll('{language}', '"dart"')
        .replaceAll('{stdin}', '""');

    final headers = <String, String>{};
    for (var h in _editablePreset.headers) {
      headers[h.key] = h.value.replaceAll('{auth}', _editablePreset.authValue);
    }

    if (_editablePreset.authType == 'Bearer Token') {
      headers['Authorization'] = 'Bearer ${_editablePreset.authValue}';
    } else if (_editablePreset.authType == 'Basic Auth') {
      final bytes = utf8.encode(_editablePreset.authValue);
      headers['Authorization'] = 'Basic ${base64.encode(bytes)}';
    }

    Uri uri = Uri.parse(_editablePreset.endpointUrl);
    if (_editablePreset.queryParams.isNotEmpty) {
      final qp = Map<String, String>.from(uri.queryParameters);
      for (var q in _editablePreset.queryParams) {
        qp[q.key] = q.value.replaceAll('{auth}', _editablePreset.authValue);
      }
      uri = uri.replace(queryParameters: qp);
    }

    try {
      http.Response response;
      if (_editablePreset.httpMethod == 'GET') {
        response = await http.get(uri, headers: headers);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Test Connection Response'),
          content: SingleChildScrollView(
            child: Text('Status: ${response.statusCode}\\n\\nBody:\\n${response.body}'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (widget.preset == null) {
        ref.read(presetProvider.notifier).addPreset(_editablePreset);
      } else {
        ref.read(presetProvider.notifier).updatePreset(_editablePreset);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = _editablePreset.isReadOnly;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : (isReadOnly ? 'View Preset' : 'Edit Preset')),
        actions: [
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isReadOnly)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.2),
                child: const Text('This preset is read-only. Duplicate it to edit.', style: TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _editablePreset.platformName,
              decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
              readOnly: isReadOnly,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _editablePreset.platformName = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _editablePreset.endpointUrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
              readOnly: isReadOnly,
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _editablePreset.endpointUrl = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _editablePreset.httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: isReadOnly ? null : (v) {
                setState(() { _editablePreset.httpMethod = v!; });
              },
              onSaved: (v) => _editablePreset.httpMethod = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _editablePreset.authType,
              decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: isReadOnly ? null : (v) {
                setState(() { _editablePreset.authType = v!; });
              },
              onSaved: (v) => _editablePreset.authType = v!,
            ),
            if (_editablePreset.authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _editablePreset.authValue,
                decoration: const InputDecoration(labelText: 'Auth Value (API Key / Token)', border: OutlineInputBorder()),
                readOnly: isReadOnly,
                onSaved: (v) => _editablePreset.authValue = v!,
              ),
            ],
            const SizedBox(height: 16),
            const Text('Request Body Template JSON', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _editablePreset.requestBodyTemplate,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              maxLines: 5,
              readOnly: isReadOnly,
              onSaved: (v) => _editablePreset.requestBodyTemplate = v!,
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (dot notation, e.g. run.stdout)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(initialValue: _editablePreset.stdoutPath, decoration: const InputDecoration(labelText: 'stdout', border: OutlineInputBorder()), readOnly: isReadOnly, onSaved: (v) => _editablePreset.stdoutPath = v!)),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(initialValue: _editablePreset.stderrPath, decoration: const InputDecoration(labelText: 'stderr', border: OutlineInputBorder()), readOnly: isReadOnly, onSaved: (v) => _editablePreset.stderrPath = v!)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testConnection,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black),
              child: const Text('Test Connection'),
            )
          ],
        ),
      ),
    );
  }
}
