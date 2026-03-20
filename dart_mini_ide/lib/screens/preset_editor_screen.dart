import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _platformNameCtrl;
  late TextEditingController _endpointUrlCtrl;
  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _executionTimePathCtrl;
  late TextEditingController _memoryPathCtrl;

  String _httpMethod = 'POST';
  String _authType = 'None';
  Map<String, String> _headers = {};
  Map<String, String> _queryParams = {};

  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _platformNameCtrl = TextEditingController(text: p?.platformName ?? '');
    _endpointUrlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _bodyTemplateCtrl = TextEditingController(text: p?.bodyTemplate ?? '{}');
    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? '');
    _executionTimePathCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? '');

    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _headers = Map.from(p?.headers ?? {});
    _queryParams = Map.from(p?.queryParams ?? {});
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      final p = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        platformName: _platformNameCtrl.text,
        endpointUrl: _endpointUrlCtrl.text,
        httpMethod: _httpMethod,
        authType: _authType,
        headers: _headers,
        queryParams: _queryParams,
        bodyTemplate: _bodyTemplateCtrl.text,
        stdoutPath: _stdoutPathCtrl.text,
        stderrPath: _stderrPathCtrl.text,
        errorPath: _errorPathCtrl.text,
        executionTimePath: _executionTimePathCtrl.text,
        memoryPath: _memoryPathCtrl.text,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(p);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(p);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final code = "void main() { print('Hello from custom API'); }";
      final url = Uri.parse(_endpointUrlCtrl.text).replace(queryParameters: _queryParams);
      final body = _bodyTemplateCtrl.text
          .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{language}', 'dart')
          .replaceAll('{stdin}', '');

      http.Response response;
      if (_httpMethod == 'POST') {
        response = await http.post(url, headers: _headers, body: body);
      } else if (_httpMethod == 'GET') {
        response = await http.get(url, headers: _headers);
      } else if (_httpMethod == 'PUT') {
        response = await http.put(url, headers: _headers, body: body);
      } else {
        throw Exception('Unsupported HTTP method: $_httpMethod');
      }

      final rawBody = response.body;
      String parsedOutput = 'No output mapping matched.';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
            final jsonResponse = jsonDecode(rawBody);
            final out = _resolvePath(jsonResponse, _stdoutPathCtrl.text);
            final err = _resolvePath(jsonResponse, _stderrPathCtrl.text) ?? _resolvePath(jsonResponse, _errorPathCtrl.text);

            parsedOutput = 'Stdout: $out\nStderr/Error: $err';
        } catch (e) {
            parsedOutput = 'Could not parse JSON response.';
        }
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Test Result (\${response.statusCode})', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Parsed Output:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(parsedOutput, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                const Text('Raw Response:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(rawBody, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFFFACC15))),
            ),
          ],
        ),
      );

    } catch (e) {
      Fluttertoast.showToast(msg: "Test failed: $e", backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  String? _resolvePath(Map<String, dynamic> json, String path) {
    if (path.isEmpty) return null;
    final keys = path.split('.');
    dynamic value = json;
    for (var key in keys) {
      if (value is Map && value.containsKey(key)) {
        value = value[key];
      } else {
        return null;
      }
    }
    return value.toString();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFFACC15)),
            onPressed: _savePreset,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_platformNameCtrl, 'Platform Name (e.g., HackerEarth)'),
            const SizedBox(height: 16),
            _buildTextField(_endpointUrlCtrl, 'Endpoint URL (e.g., https://api.hackerearth.com/v4/partner/code-evaluation/submissions/)'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _httpMethod,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _httpMethod = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _authType = val!),
            ),
            const SizedBox(height: 16),
            _buildMapEditor('Headers', _headers),
            const SizedBox(height: 16),
            _buildMapEditor('Query Params', _queryParams),
            const SizedBox(height: 16),
            _buildTextField(_bodyTemplateCtrl, 'Body Template JSON (use {code}, {language}, {stdin})', maxLines: 6),
            const SizedBox(height: 24),
            const Text('Response Mapping (dot notation e.g., result.output)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTextField(_stdoutPathCtrl, 'Stdout Path'),
            const SizedBox(height: 8),
            _buildTextField(_stderrPathCtrl, 'Stderr Path'),
            const SizedBox(height: 8),
            _buildTextField(_errorPathCtrl, 'Error Path'),
            const SizedBox(height: 8),
            _buildTextField(_executionTimePathCtrl, 'Execution Time Path'),
            const SizedBox(height: 8),
            _buildTextField(_memoryPathCtrl, 'Memory Path'),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.bolt, color: Colors.black),
                label: const Text('Test Connection', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMapEditor(String title, Map<String, String> map) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFFFACC15), size: 20),
                onPressed: () {
                  _showAddEntryDialog(title, map);
                },
              )
            ],
          ),
          ...map.entries.map((e) => ListTile(
            dense: true,
            title: Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.white70)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 16),
              onPressed: () {
                setState(() => map.remove(e.key));
              },
            ),
          )),
        ],
      ),
    );
  }

  void _showAddEntryDialog(String title, Map<String, String> map) {
    String key = '';
    String value = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Add $title Entry', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Key'),
              onChanged: (val) => key = val,
            ),
            const SizedBox(height: 8),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Value'),
              onChanged: (val) => value = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15)),
            onPressed: () {
              if (key.isNotEmpty) {
                setState(() => map[key] = value);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: _inputDecoration(label),
      validator: (val) {
        if (label.contains('URL') || label.contains('Platform')) {
          if (val == null || val.isEmpty) return 'Required';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFACC15))),
    );
  }
}
