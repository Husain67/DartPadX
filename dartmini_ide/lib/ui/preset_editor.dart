import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../providers/compiler_preset_provider.dart';


class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  const PresetEditor({super.key, required this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late TextEditingController _authKeyCtrl;
  late TextEditingController _bodyCtrl;

  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  String _testOutput = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _method = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _authValueCtrl = TextEditingController(text: widget.preset.authValue);
    _authKeyCtrl = TextEditingController(text: widget.preset.authKey);
    _bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);

    _stdoutPathCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrPathCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorPathCtrl = TextEditingController(text: widget.preset.errorPath);
    _timePathCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memoryPathCtrl = TextEditingController(text: widget.preset.memoryPath);

    _headers = widget.preset.headers.entries.toList();
    _queryParams = widget.preset.queryParams.entries.toList();
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      authKey: _authKeyCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );
    ref.read(compilerPresetProvider.notifier).updatePreset(updated);
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    setState(() => _testOutput = 'Testing...');

    // Create temporary preset from current UI state
    final p = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      authKey: _authKeyCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    try {
      final uri = Uri.parse(p.endpointUrl).replace(
        queryParameters: p.queryParams.isNotEmpty ? p.queryParams : null,
      );

      final hdrs = Map<String, String>.from(p.headers);

      if (p.authType == 'API-Key Header' && p.authKey.isNotEmpty) {
        hdrs[p.authKey] = p.authValue;
      } else if (p.authType == 'Bearer Token') {
        hdrs['Authorization'] = 'Bearer ${p.authValue}';
      } else if (p.authType == 'Basic Auth') {
        final encoded = base64Encode(utf8.encode(p.authValue));
        hdrs['Authorization'] = 'Basic $encoded';
        final _ = encoded;
      }

      String body = p.requestBodyTemplate;
      String codeEscaped = jsonEncode("print('Hello from custom API!');");
      codeEscaped = codeEscaped.substring(1, codeEscaped.length - 1);
      body = body.replaceAll('{code}', codeEscaped);
      body = body.replaceAll('{stdin}', '');
      body = body.replaceAll('{language}', 'dart');

      http.Response response;
      if (p.httpMethod == 'POST') {
        response = await http.post(uri, headers: hdrs, body: body);
      } else if (p.httpMethod == 'PUT') {
        response = await http.put(uri, headers: hdrs, body: body);
      } else {
        response = await http.get(uri, headers: hdrs);
      }
      final _ = response;

      setState(() {
        _testOutput = 'Status Code: ${response.statusCode}\n\nRaw Response:\n${response.body}';
      });

    } catch (e) {
      setState(() {
        _testOutput = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Preset', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () {
               ref.read(compilerPresetProvider.notifier).deletePreset(widget.preset.id);
               Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFFACC15)),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildTextField('Platform Name', _nameCtrl),
             const SizedBox(height: 16),
             _buildTextField('Endpoint URL', _urlCtrl, isUrl: true),
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(
                   child: DropdownButtonFormField<String>(
                     initialValue: _method,
                     dropdownColor: const Color(0xFF1E1E1E),
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(labelText: 'Method', labelStyle: TextStyle(color: Colors.white54)),
                     items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                     onChanged: (val) => setState(() => _method = val!),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: DropdownButtonFormField<String>(
                     initialValue: _authType,
                     dropdownColor: const Color(0xFF1E1E1E),
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.white54)),
                     items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                     onChanged: (val) => setState(() => _authType = val!),
                   ),
                 ),
               ],
             ),
             if (_authType != 'None') ...[
               const SizedBox(height: 16),
               if (_authType == 'API-Key Header' || _authType == 'Query Param')
                  _buildTextField('Auth Key', _authKeyCtrl),
               const SizedBox(height: 16),
               _buildTextField('Auth Value / Token', _authValueCtrl, obscureText: true),
             ],
             const SizedBox(height: 24),
             const Text('Request Body Template (JSON)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
             const SizedBox(height: 8),
             TextField(
               controller: _bodyCtrl,
               maxLines: 8,
               style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
               decoration: const InputDecoration(
                 filled: true, fillColor: Color(0xFF1E1E1E),
                 border: OutlineInputBorder(),
               ),
             ),
             const SizedBox(height: 24),
             const Text('Response Mapping (Dot Notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             const SizedBox(height: 8),
             _buildTextField('stdout Path (e.g. data.output)', _stdoutPathCtrl),
             const SizedBox(height: 8),
             _buildTextField('stderr Path (e.g. data.error)', _stderrPathCtrl),
             const SizedBox(height: 8),
             _buildTextField('error Path (e.g. exception)', _errorPathCtrl),
             const SizedBox(height: 8),
             _buildTextField('executionTime Path (e.g. cpuTime)', _timePathCtrl),
             const SizedBox(height: 8),
             _buildTextField('memory Path (e.g. memory)', _memoryPathCtrl),

             const SizedBox(height: 32),
             ElevatedButton(
               style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), minimumSize: const Size.fromHeight(50)),
               onPressed: _testConnection,
               child: const Text('Test Connection', style: TextStyle(color: Colors.white)),
             ),
             const SizedBox(height: 16),
             if (_testOutput.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  color: const Color(0xFF1E1E1E),
                  child: Text(_testOutput, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)),
                )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isUrl = false, bool obscureText = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: const OutlineInputBorder(),
        suffixIcon: isUrl ? IconButton(
          icon: const Icon(Icons.copy, color: Colors.white54, size: 16),
          onPressed: () {
            // copy to clipboard logic could go here
          },
        ) : null,
      ),
    );
  }
}
