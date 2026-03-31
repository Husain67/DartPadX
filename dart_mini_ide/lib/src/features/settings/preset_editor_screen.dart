import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import '../../ui/theme/theme_constants.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _httpMethod;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;

  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  late Map<String, String> _headers;
  late Map<String, String> _queryParams;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.platformName);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _httpMethod = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _authValueCtrl = TextEditingController(text: widget.preset.authValue);
    _bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    _stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorCtrl = TextEditingController(text: widget.preset.errorPath);
    _timeCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memoryCtrl = TextEditingController(text: widget.preset.memoryPath);

    _headers = Map.from(widget.preset.headers);
    _queryParams = Map.from(widget.preset.queryParams);
  }

  void _save() {
    final updated = widget.preset.copyWith(
      platformName: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      authValue: _authValueCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memoryCtrl.text,
      headers: _headers,
      queryParams: _queryParams,
    );
    ref.read(presetsProvider.notifier).updatePreset(updated);
    Fluttertoast.showToast(msg: "Preset saved");
    Navigator.pop(context);
  }

  void _duplicate() {
    final duplicated = widget.preset.copyWith(
      id: const Uuid().v4(),
      platformName: '${_nameCtrl.text} (Copy)',
    );
    ref.read(presetsProvider.notifier).addPreset(duplicated);
    Fluttertoast.showToast(msg: "Preset duplicated");
    Navigator.pop(context);
  }

  void _delete() {
    ref.read(presetsProvider.notifier).deletePreset(widget.preset.id);
    Fluttertoast.showToast(msg: "Preset deleted");
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    Fluttertoast.showToast(msg: "Testing connection...");

    try {
      final uri = Uri.parse(_urlCtrl.text.trim());

      final Map<String, String> finalHeaders = {..._headers};
      if (_authType == 'API-Key Header') {
        final parts = _authValueCtrl.text.split(':');
        if (parts.length == 2) finalHeaders[parts[0]] = parts[1];
      } else if (_authType == 'Bearer Token') {
        finalHeaders['Authorization'] = 'Bearer ${_authValueCtrl.text}';
      } else if (_authType == 'Basic Auth') {
        final auth = base64Encode(utf8.encode(_authValueCtrl.text));
        finalHeaders['Authorization'] = 'Basic $auth';
      }

      final String testCode = "print('Hello from custom API');";
      final codeJsonEscaped = jsonEncode(testCode);
      final codeStripped = codeJsonEscaped.substring(1, codeJsonEscaped.length - 1);

      String finalBody = _bodyCtrl.text
          .replaceAll('{code}', codeStripped)
          .replaceAll('{language}', 'dart')
          .replaceAll('{stdin}', '');

      final requestUri = uri.replace(queryParameters: _queryParams.isEmpty ? null : _queryParams);

      http.Response response;
      if (_httpMethod == 'POST') {
        response = await http.post(requestUri, headers: finalHeaders, body: finalBody);
      } else if (_httpMethod == 'GET') {
        response = await http.get(requestUri, headers: finalHeaders);
      } else if (_httpMethod == 'PUT') {
        response = await http.put(requestUri, headers: finalHeaders, body: finalBody);
      } else {
        throw Exception("Unsupported method $_httpMethod");
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Connection Result'),
          content: SingleChildScrollView(
            child: Text(
              "Status: ${response.statusCode}\nBody:\n${response.body}",
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Test failed: $e");
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildUrlField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Endpoint URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _urlCtrl.text));
              Fluttertoast.showToast(msg: "Copied URL");
            },
          )
        ],
      ),
    );
  }

  Widget _buildDynamicMapEditor(String title, Map<String, String> map) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: ThemeConstants.primaryAccent),
              onPressed: () {
                setState(() {
                  map['new_key_${map.length}'] = 'value';
                });
              },
            ),
          ],
        ),
        if (map.isEmpty)
          const Text('No items added.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ...map.entries.map((entry) {
          final keyCtrl = TextEditingController(text: entry.key);
          final valCtrl = TextEditingController(text: entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: keyCtrl,
                    decoration: const InputDecoration(hintText: 'Key', isDense: true),
                    onChanged: (newKey) {
                      final val = map.remove(entry.key);
                      map[newKey] = val ?? '';
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: valCtrl,
                    decoration: const InputDecoration(hintText: 'Value', isDense: true),
                    onChanged: (newVal) {
                      map[entry.key] = newVal;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      map.remove(entry.key);
                    });
                  },
                ),
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
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), tooltip: 'Duplicate', onPressed: _duplicate),
          IconButton(icon: const Icon(Icons.delete), tooltip: 'Delete', onPressed: _delete),
          IconButton(icon: const Icon(Icons.check), tooltip: 'Save', onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Platform Name', _nameCtrl),
            _buildUrlField(),
            DropdownButtonFormField<String>(
              value: _httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _httpMethod = v!),
            ),
            DropdownButtonFormField<String>(
              value: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            if (_authType != 'None')
              _buildTextField('Auth Value (Token/Key)', _authValueCtrl),

            const SizedBox(height: 16),
            const Divider(),
            _buildDynamicMapEditor('Headers', _headers),

            const SizedBox(height: 16),
            const Divider(),
            _buildDynamicMapEditor('Query Parameters', _queryParams),

            const SizedBox(height: 16),
            const Divider(),
            const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {language}, {stdin} placeholders.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            _buildTextField('', _bodyCtrl, lines: 8),

            const SizedBox(height: 16),
            const Divider(),
            const Text('Response Dot-Paths (e.g. data.output.stdout)', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildTextField('Stdout Path', _stdoutCtrl),
            _buildTextField('Stderr Path', _stderrCtrl),
            _buildTextField('Error Path', _errorCtrl),
            _buildTextField('Execution Time Path', _timeCtrl),
            _buildTextField('Memory Path', _memoryCtrl),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testConnection,
              style: ElevatedButton.styleFrom(backgroundColor: ThemeConstants.primaryAccent),
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        backgroundColor: ThemeConstants.primaryAccent,
        child: const Icon(Icons.save),
      ),
    );
  }
}
