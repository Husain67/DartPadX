import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/compiler_preset.dart';
import '../providers/preset_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  late String _name;
  late String _endpointUrl;
  late String _httpMethod;
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

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _id = widget.preset!.id;
      _name = widget.preset!.name;
      _endpointUrl = widget.preset!.endpointUrl;
      _httpMethod = widget.preset!.httpMethod;
      _authType = widget.preset!.authType;
      _authValue = widget.preset!.authValue;
      _headers = widget.preset!.headers.entries.toList();
      _queryParams = widget.preset!.queryParams.entries.toList();
      _bodyTemplate = widget.preset!.bodyTemplate;
      _stdoutPath = widget.preset!.stdoutPath;
      _stderrPath = widget.preset!.stderrPath;
      _errorPath = widget.preset!.errorPath;
      _executionTimePath = widget.preset!.executionTimePath;
      _memoryPath = widget.preset!.memoryPath;
    } else {
      _id = const Uuid().v4();
      _name = 'New Custom Preset';
      _endpointUrl = 'https://';
      _httpMethod = 'POST';
      _authType = 'None';
      _authValue = '';
      _headers = [const MapEntry('Content-Type', 'application/json')];
      _queryParams = [];
      _bodyTemplate = '{"code": "{code}"}';
      _stdoutPath = '';
      _stderrPath = '';
      _errorPath = '';
      _executionTimePath = '';
      _memoryPath = '';
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: _id,
        name: _name,
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        authType: _authType,
        authValue: _authValue,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );

      if (widget.preset == null) {
        ref.read(presetProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(presetProvider.notifier).updatePreset(newPreset);
      }

      Fluttertoast.showToast(msg: "Preset Saved");
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    // Save current form state to vars
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final tempPreset = CompilerPreset(
      id: _id,
      name: _name,
      endpointUrl: _endpointUrl,
      httpMethod: _httpMethod,
      authType: _authType,
      authValue: _authValue,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      bodyTemplate: _bodyTemplate,
      stdoutPath: _stdoutPath,
      stderrPath: _stderrPath,
      errorPath: _errorPath,
      executionTimePath: _executionTimePath,
      memoryPath: _memoryPath,
    );

    Fluttertoast.showToast(msg: "Testing connection...");

    try {
      final finalHeaders = Map<String, String>.from(tempPreset.headers);
      if (tempPreset.authType == 'Bearer Token' && tempPreset.authValue != null) {
        finalHeaders['Authorization'] = 'Bearer ${tempPreset.authValue}';
      } else if (tempPreset.authType == 'Basic Auth' && tempPreset.authValue != null) {
        final encoded = base64Encode(utf8.encode(tempPreset.authValue!));
        finalHeaders['Authorization'] = 'Basic $encoded';
      } else if (tempPreset.authType == 'API-Key Header' && tempPreset.authValue != null) {
        finalHeaders.forEach((key, value) {
          if (value.contains('{authValue}')) {
            finalHeaders[key] = value.replaceAll('{authValue}', tempPreset.authValue!);
          }
        });
      }

      var uri = Uri.parse(tempPreset.endpointUrl);
      if (tempPreset.queryParams.isNotEmpty) {
        final queryParams = Map<String, dynamic>.from(uri.queryParameters);
        queryParams.addAll(tempPreset.queryParams);
        uri = uri.replace(queryParameters: queryParams);
      }

      const code = "void main() { print('Hello from custom API'); }";
      final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');

      String bodyContent = tempPreset.bodyTemplate;
      bodyContent = bodyContent.replaceAll('{code}', escapedCode);
      bodyContent = bodyContent.replaceAll('{stdin}', '');
      bodyContent = bodyContent.replaceAll('{language}', 'dart');

      http.Response response;
      if (tempPreset.httpMethod == 'GET') {
        response = await http.get(uri, headers: finalHeaders);
      } else if (tempPreset.httpMethod == 'PUT') {
        response = await http.put(uri, headers: finalHeaders, body: bodyContent);
      } else {
        response = await http.post(uri, headers: finalHeaders, body: bodyContent);
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Test Result', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Status Code: ${response.statusCode}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                const Text('Raw Response:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black,
                  child: Text(response.body, style: const TextStyle(color: Colors.white54, fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Color(0xFFFACC15))),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Test Error', style: TextStyle(color: Colors.redAccent)),
          content: Text(e.toString(), style: const TextStyle(color: Colors.white54)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Color(0xFFFACC15))),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Preset', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.network_check, color: Colors.blueAccent),
            tooltip: 'Test Connection',
            onPressed: _testConnection,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFFACC15)),
            onPressed: _save,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('General'),
            _buildTextField(
              initialValue: _name,
              label: 'Platform Name',
              onSaved: (val) => _name = val ?? '',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              initialValue: _endpointUrl,
              label: 'Endpoint URL',
              onSaved: (val) => _endpointUrl = val ?? '',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF252525),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'HTTP Method',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              initialValue: _httpMethod,
              items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _httpMethod = val!),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Authentication'),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF252525),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Auth Type',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              initialValue: _authType,
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _authType = val!),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              _buildTextField(
                initialValue: _authValue,
                label: 'Auth Value / Key / Token',
                onSaved: (val) => _authValue = val,
              ),
            ],

            const SizedBox(height: 24),
            _buildSectionTitle('Headers'),
            ..._headers.asMap().entries.map((entry) {
              int idx = entry.key;
              MapEntry<String, String> header = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: _buildTextField(initialValue: header.key, label: 'Key', onChanged: (val) => _headers[idx] = MapEntry(val, header.value)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(initialValue: header.value, label: 'Value', onChanged: (val) => _headers[idx] = MapEntry(header.key, val)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                    onPressed: () => setState(() => _headers.removeAt(idx)),
                  ),
                ],
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _headers.add(const MapEntry('', ''))),
              icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
              label: const Text('Add Header', style: TextStyle(color: Color(0xFFFACC15))),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Request Body Template'),
            const Text(
              'Use {code}, {stdin}, {language} as placeholders.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _bodyTemplate,
              maxLines: 6,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
              ),
              onSaved: (val) => _bodyTemplate = val ?? '',
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Response Mapping (Dot Notation)'),
            _buildTextField(initialValue: _stdoutPath, label: 'stdout path (e.g. data.output)', onSaved: (val) => _stdoutPath = val ?? ''),
            const SizedBox(height: 8),
            _buildTextField(initialValue: _stderrPath, label: 'stderr path', onSaved: (val) => _stderrPath = val ?? ''),
            const SizedBox(height: 8),
            _buildTextField(initialValue: _errorPath, label: 'error path', onSaved: (val) => _errorPath = val ?? ''),
            const SizedBox(height: 8),
            _buildTextField(initialValue: _executionTimePath, label: 'executionTime path', onSaved: (val) => _executionTimePath = val ?? ''),
            const SizedBox(height: 8),
            _buildTextField(initialValue: _memoryPath, label: 'memory path', onSaved: (val) => _memoryPath = val ?? ''),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildTextField({
    String? initialValue,
    required String label,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onSaved: onSaved,
      onChanged: onChanged,
    );
  }
}
