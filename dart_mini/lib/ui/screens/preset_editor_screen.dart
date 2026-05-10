import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/preset_model.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _authValueController;
  late TextEditingController _bodyController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;

  String _method = 'POST';
  String _authType = 'None';
  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  String _testResult = '';

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _urlController = TextEditingController(text: p?.url ?? '');
    _authValueController = TextEditingController(text: p?.authValue ?? '');
    _bodyController = TextEditingController(text: p?.bodyTemplate ?? '{"content": "{code}"}');
    _stdoutController = TextEditingController(text: p?.stdoutPath ?? 'stdout');
    _stderrController = TextEditingController(text: p?.stderrPath ?? 'stderr');
    _errorController = TextEditingController(text: p?.errorPath ?? 'error');
    _timeController = TextEditingController(text: p?.executionTimePath ?? 'time');
    _memoryController = TextEditingController(text: p?.memoryPath ?? 'memory');

    if (p != null) {
      _method = p.method;
      _authType = p.authType;
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
    _stdoutController.dispose();
    _stderrController.dispose();
    _errorController.dispose();
    _timeController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  void _save() {
    final Map<String, String> hdrs = {for (var e in _headers) e.key: e.value};
    final Map<String, String> params = {for (var e in _queryParams) e.key: e.value};

    final preset = CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameController.text,
      url: _urlController.text,
      method: _method,
      authType: _authType,
      authValue: _authValueController.text,
      headers: hdrs,
      queryParams: params,
      bodyTemplate: _bodyController.text,
      stdoutPath: _stdoutController.text,
      stderrPath: _stderrController.text,
      errorPath: _errorController.text,
      executionTimePath: _timeController.text,
      memoryPath: _memoryController.text,
      isReadOnly: widget.preset?.isReadOnly ?? false,
    );

    ref.read(settingsProvider.notifier).savePreset(preset);
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    setState(() => _testResult = 'Testing...');
    try {
      final Map<String, String> hdrs = {for (var e in _headers) e.key: e.value};
      final Map<String, String> params = {for (var e in _queryParams) e.key: e.value};

      if (_authType == 'API-Key Header' && _authValueController.text.isNotEmpty) {
        hdrs['Authorization'] = _authValueController.text;
      } else if (_authType == 'Bearer Token' && _authValueController.text.isNotEmpty) {
        hdrs['Authorization'] = 'Bearer ${_authValueController.text}';
      } else if (_authType == 'Basic Auth' && _authValueController.text.isNotEmpty) {
        hdrs['Authorization'] = 'Basic ${base64Encode(utf8.encode(_authValueController.text))}';
      }

      String finalUrl = _urlController.text;
      if (params.isNotEmpty) {
        final uri = Uri.parse(finalUrl);
        finalUrl = uri.replace(queryParameters: params).toString();
      } else if (_authType == 'Query Param' && _authValueController.text.isNotEmpty) {
        final uri = Uri.parse(finalUrl);
        finalUrl = uri.replace(queryParameters: {'api_key': _authValueController.text}).toString();
      }

      String body = _bodyController.text;
      String safeCode = jsonEncode("print('Hello from custom API');");
      safeCode = safeCode.substring(1, safeCode.length - 1);
      body = body.replaceAll('{code}', safeCode);
      body = body.replaceAll('{stdin}', '');

      http.Response response; // ignore: unused_local_variable
      final uri = Uri.parse(finalUrl);

      if (_method == 'POST') {
        response = await http.post(uri, headers: hdrs, body: body);
      } else if (_method == 'GET') {
        response = await http.get(uri, headers: hdrs);
      } else {
        response = await http.put(uri, headers: hdrs, body: body);
      }

      setState(() {
        _testResult = 'Status: ${response.statusCode}\n\nResponse:\n${response.body}';
      });
    } catch (e) {
      setState(() => _testResult = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReadOnly = widget.preset?.isReadOnly ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          if (widget.preset != null && !isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                ref.read(settingsProvider.notifier).deletePreset(widget.preset!.id);
                Navigator.pop(context);
              },
            ),
        ],
      ),
      body: isReadOnly
          ? const Center(child: Text('This default preset cannot be edited.'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Preset Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'Endpoint URL'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _method,
            items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _method = v!),
            decoration: const InputDecoration(labelText: 'HTTP Method'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _authType,
            items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) => setState(() => _authType = v!),
            decoration: const InputDecoration(labelText: 'Auth Type'),
          ),
          if (_authType != 'None') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _authValueController,
              decoration: const InputDecoration(labelText: 'Auth Value'),
            ),
          ],

          const Divider(height: 32),
          const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ..._headers.asMap().entries.map((entry) {
             int idx = entry.key;
             return Row(
               children: [
                 Expanded(
                   child: TextFormField(
                     initialValue: entry.value.key,
                     onChanged: (v) => setState(() => _headers[idx] = MapEntry(v, _headers[idx].value)),
                     decoration: const InputDecoration(hintText: 'Key'),
                   )
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: TextFormField(
                     initialValue: entry.value.value,
                     onChanged: (v) => setState(() => _headers[idx] = MapEntry(_headers[idx].key, v)),
                     decoration: const InputDecoration(hintText: 'Value'),
                   )
                 ),
                 IconButton(
                   icon: const Icon(Icons.remove_circle, color: Colors.red),
                   onPressed: () => setState(() => _headers.removeAt(idx)),
                 )
               ],
             );
          }),
          TextButton(
            onPressed: () => setState(() => _headers.add(const MapEntry('', ''))),
            child: const Text('Add Header Row'),
          ),

          const Divider(height: 32),
          const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ..._queryParams.asMap().entries.map((entry) {
             int idx = entry.key;
             return Row(
               children: [
                 Expanded(
                   child: TextFormField(
                     initialValue: entry.value.key,
                     onChanged: (v) => setState(() => _queryParams[idx] = MapEntry(v, _queryParams[idx].value)),
                     decoration: const InputDecoration(hintText: 'Key'),
                   )
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: TextFormField(
                     initialValue: entry.value.value,
                     onChanged: (v) => setState(() => _queryParams[idx] = MapEntry(_queryParams[idx].key, v)),
                     decoration: const InputDecoration(hintText: 'Value'),
                   )
                 ),
                 IconButton(
                   icon: const Icon(Icons.remove_circle, color: Colors.red),
                   onPressed: () => setState(() => _queryParams.removeAt(idx)),
                 )
               ],
             );
          }),
          TextButton(
            onPressed: () => setState(() => _queryParams.add(const MapEntry('', ''))),
            child: const Text('Add Param Row'),
          ),

          const Divider(height: 32),
          const Text('Body JSON Template', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const Text('{code}, {stdin}, {language} are replaced dynamically', style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '{"script": "{code}"}',
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),

          const Divider(height: 32),
          const Text('Response Mapping Paths (dot notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          TextField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'stdout path')),
          TextField(controller: _stderrController, decoration: const InputDecoration(labelText: 'stderr path')),
          TextField(controller: _errorController, decoration: const InputDecoration(labelText: 'error path')),
          TextField(controller: _timeController, decoration: const InputDecoration(labelText: 'executionTime path')),
          TextField(controller: _memoryController, decoration: const InputDecoration(labelText: 'memory path')),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _testConnection,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
            child: const Text('Test Connection'),
          ),
          if (_testResult.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              color: Colors.black45,
              child: Text(_testResult, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save Preset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
