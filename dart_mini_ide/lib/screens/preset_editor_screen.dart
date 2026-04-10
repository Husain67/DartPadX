import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../providers/compiler_provider.dart';
import '../theme.dart';
import 'package:http/http.dart' as http;

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;

  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  List<MapEntry<TextEditingController, TextEditingController>> _headers = [];
  List<MapEntry<TextEditingController, TextEditingController>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.platformName ?? '');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _method = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{}');

    _stdoutCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timeCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      p.headers.forEach((k, v) {
        _headers.add(MapEntry(TextEditingController(text: k), TextEditingController(text: v)));
      });
      p.queryParams.forEach((k, v) {
        _queryParams.add(MapEntry(TextEditingController(text: k), TextEditingController(text: v)));
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Map<String, String> headersMap = {};
      for (var entry in _headers) {
        if (entry.key.text.isNotEmpty) headersMap[entry.key.text] = entry.value.text;
      }
      Map<String, String> paramsMap = {};
      for (var entry in _queryParams) {
        if (entry.key.text.isNotEmpty) paramsMap[entry.key.text] = entry.value.text;
      }

      final preset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        platformName: _nameCtrl.text,
        endpointUrl: _urlCtrl.text,
        httpMethod: _method,
        authType: _authType,
        authValue: _authValueCtrl.text,
        headers: headersMap,
        queryParams: paramsMap,
        requestBodyTemplate: _bodyCtrl.text,
        stdoutPath: _stdoutCtrl.text,
        stderrPath: _stderrCtrl.text,
        errorPath: _errorCtrl.text,
        executionTimePath: _timeCtrl.text,
        memoryPath: _memoryCtrl.text,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(preset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(preset);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    final code = "print('Hello from custom API');";
    final stdin = "";

    Map<String, String> headersMap = {};
    for (var entry in _headers) {
      if (entry.key.text.isNotEmpty) headersMap[entry.key.text] = entry.value.text;
    }

    if (_authType == 'API-Key Header' && _authValueCtrl.text.isNotEmpty) {
        headersMap['x-rapidapi-key'] = _authValueCtrl.text;
    } else if (_authType == 'Bearer Token' && _authValueCtrl.text.isNotEmpty) {
      headersMap['Authorization'] = 'Bearer \${_authValueCtrl.text}';
    } else if (_authType == 'Basic Auth' && _authValueCtrl.text.isNotEmpty) {
      final basicAuth = base64Encode(utf8.encode(_authValueCtrl.text));
      headersMap['Authorization'] = 'Basic $basicAuth';
    }

    String body = _bodyCtrl.text;
    String escapedCode = jsonEncode(code);
    escapedCode = escapedCode.substring(1, escapedCode.length - 1);
    String escapedStdin = jsonEncode(stdin);
    escapedStdin = escapedStdin.substring(1, escapedStdin.length - 1);

    body = body.replaceAll('{code}', escapedCode);
    body = body.replaceAll('{stdin}', escapedStdin);
    body = body.replaceAll('{language}', 'dart');

    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      var uri = Uri.parse(_urlCtrl.text);
      Map<String, String> paramsMap = {};
      for (var entry in _queryParams) {
        if (entry.key.text.isNotEmpty) paramsMap[entry.key.text] = entry.value.text;
      }
      if (paramsMap.isNotEmpty) {
        uri = uri.replace(queryParameters: paramsMap);
      }

      http.Response response;
      if (_method == 'GET') {
        response = await http.get(uri, headers: headersMap);
      } else {
        response = await http.post(uri, headers: headersMap, body: body);
      }

      Navigator.pop(context); // close loading

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Test Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status Code: \${response.statusCode}'),
                const SizedBox(height: 8),
                const Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(response.body, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
    }
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
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ElevatedButton.icon(
                onPressed: _testConnection,
                icon: const Icon(Icons.network_check),
                label: const Text('Test Connection'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Platform Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(labelText: 'Endpoint URL'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _method = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _authType = val!),
              ),
              if (_authType != 'None') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _authValueCtrl,
                  decoration: const InputDecoration(labelText: 'Auth Value'),
                ),
              ],
              const SizedBox(height: 24),
              _buildKeyValueList('Headers', _headers),
              const SizedBox(height: 24),
              _buildKeyValueList('Query Params', _queryParams),
              const SizedBox(height: 24),
              const Text('Request Body JSON Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 8,
                decoration: const InputDecoration(hintText: 'e.g. {"code": "{code}"}'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 24),
              const Text('Response Mappings (dot notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path')),
              const SizedBox(height: 8),
              TextFormField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path')),
              const SizedBox(height: 8),
              TextFormField(controller: _errorCtrl, decoration: const InputDecoration(labelText: 'error path')),
              const SizedBox(height: 8),
              TextFormField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'execution time path')),
              const SizedBox(height: 8),
              TextFormField(controller: _memoryCtrl, decoration: const InputDecoration(labelText: 'memory path')),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyValueList(String title, List<MapEntry<TextEditingController, TextEditingController>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.accentYellow),
              onPressed: () {
                setState(() => list.add(MapEntry(TextEditingController(), TextEditingController())));
              },
            ),
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(child: TextFormField(controller: item.key, decoration: const InputDecoration(hintText: 'Key'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: item.value, decoration: const InputDecoration(hintText: 'Value'))),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () => setState(() => list.removeAt(index)),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
