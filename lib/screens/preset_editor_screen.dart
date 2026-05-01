import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../providers/preset_provider.dart';

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
  String? _authValue;
  late List<MapEntry<String, String>> _headers;
  late List<MapEntry<String, String>> _queryParams;
  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  String _testResult = '';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _name = p?.name ?? '';
    _url = p?.url ?? '';
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValue = p?.authValue;
    _headers = p != null ? List.from(p.headers) : [];
    _queryParams = p != null ? List.from(p.queryParams) : [];
    _bodyTemplate = p?.bodyTemplate ?? '{"content": "{code}"}';
    _stdoutPath = p?.stdoutPath ?? '';
    _stderrPath = p?.stderrPath ?? '';
    _errorPath = p?.errorPath ?? '';
    _executionTimePath = p?.executionTimePath ?? '';
    _memoryPath = p?.memoryPath ?? '';
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: widget.preset?.id,
        name: _name,
        url: _url,
        method: _method,
        authType: _authType,
        authValue: _authValue,
        headers: _headers,
        queryParams: _queryParams,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );
      ref.read(presetProvider.notifier).savePreset(newPreset);
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isTesting = true;
      _testResult = 'Testing...';
    });

    try {
      final requestUri = Uri.parse(_url).replace(
        queryParameters: _queryParams.isNotEmpty ? Map.fromEntries(_queryParams) : null
      );

      final reqHeaders = <String, String>{};
      for (var entry in _headers) {
        reqHeaders[entry.key] = entry.value;
      }

      if (_authType == 'API-Key Header' && _authValue != null) {
        reqHeaders['Authorization'] = _authValue!;
      } else if (_authType == 'Bearer Token' && _authValue != null) {
        reqHeaders['Authorization'] = 'Bearer $_authValue';
      } else if (_authType == 'Basic Auth' && _authValue != null) {
        reqHeaders['Authorization'] = 'Basic ${base64Encode(utf8.encode(_authValue!))}';
      }

      String testCode = "void main() { print('Hello from custom API'); }";
      String bodyStr = _bodyTemplate
          .replaceAll('"{code}"', jsonEncode(testCode))
          .replaceAll('"{stdin}"', jsonEncode(''))
          .replaceAll('{code}', jsonEncode(testCode).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{stdin}', jsonEncode('').replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{language}', 'dart');

      http.Response response;
      if (_method.toUpperCase() == 'GET') {
        response = await http.get(requestUri, headers: reqHeaders);
      } else if (_method.toUpperCase() == 'PUT') {
        response = await http.put(requestUri, headers: reqHeaders, body: bodyStr);
      } else {
        response = await http.post(requestUri, headers: reqHeaders, body: bodyStr);
      }

      final _ = response; // use response

      setState(() {
        _testResult = 'Status: ${response.statusCode}\n\nResponse:\n${response.body}';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Widget _buildTextField(String label, String initialValue, void Function(String?) onSaved, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: initialValue,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
        onSaved: onSaved,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildMapEditor(String title, List<MapEntry<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => setState(() => items.add(const MapEntry('', ''))),
            )
          ],
        ),
        ...items.asMap().entries.map((e) {
          int idx = e.key;
          var entry = e.value;
          return Row(
            children: [
              Expanded(child: TextFormField(
                initialValue: entry.key,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.white54)),
                onChanged: (v) => items[idx] = MapEntry(v, items[idx].value),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                initialValue: entry.value,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.white54)),
                onChanged: (v) => items[idx] = MapEntry(items[idx].key, v),
              )),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => setState(() => items.removeAt(idx)),
              )
            ],
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField('Platform Name', _name, (v) => _name = v ?? '', required: true),
            _buildTextField('Endpoint URL', _url, (v) => _url = v ?? '', required: true),
            DropdownButtonFormField<String>(
              initialValue: _method,
              dropdownColor: const Color(0xFF1a1a1a),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder()),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
              onSaved: (v) => _method = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              dropdownColor: const Color(0xFF1a1a1a),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.white54), border: OutlineInputBorder()),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
              onSaved: (v) => _authType = v!,
            ),
            const SizedBox(height: 16),
            if (_authType != 'None')
              _buildTextField('Auth Value (Token/Key)', _authValue ?? '', (v) => _authValue = v),
            _buildMapEditor('Headers', _headers),
            _buildMapEditor('Query Parameters', _queryParams),
            const Text('Request Body Template (JSON)', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTextField('', _bodyTemplate, (v) => _bodyTemplate = v ?? '', maxLines: 5),
            const Text('Response Mapping (dot notation e.g. data.output)', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTextField('stdout path', _stdoutPath, (v) => _stdoutPath = v ?? ''),
            _buildTextField('stderr path', _stderrPath, (v) => _stderrPath = v ?? ''),
            _buildTextField('error path', _errorPath, (v) => _errorPath = v ?? ''),
            _buildTextField('executionTime path', _executionTimePath, (v) => _executionTimePath = v ?? ''),
            _buildTextField('memory path', _memoryPath, (v) => _memoryPath = v ?? ''),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black),
              icon: _isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black)) : const Icon(Icons.network_check),
              label: const Text('Test Connection'),
              onPressed: _isTesting ? null : _testConnection,
            ),
            if (_testResult.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(8),
                color: Colors.black,
                child: Text(_testResult, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
              ),
          ],
        ),
      ),
    );
  }
}
