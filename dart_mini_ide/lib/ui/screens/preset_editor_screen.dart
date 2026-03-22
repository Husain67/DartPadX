import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/compiler_preset.dart';
import '../../providers/compiler_provider.dart';
import '../../utils/theme.dart';
import '../../utils/json_mapper.dart';

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
  late TextEditingController _bodyTemplateCtrl;

  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _execTimePathCtrl;
  late TextEditingController _memoryPathCtrl;

  late List<Map<String, String>> _headers;
  late List<Map<String, String>> _queryParams;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _urlCtrl = TextEditingController(text: p?.url ?? '');
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _bodyTemplateCtrl = TextEditingController(text: p?.bodyTemplate ?? '{}');

    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? '');
    _execTimePathCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? '');

    _headers = p?.headers.map((e) => Map<String, String>.from(e)).toList() ?? [];
    _queryParams = p?.queryParams.map((e) => Map<String, String>.from(e)).toList() ?? [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _execTimePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final preset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameCtrl.text,
        url: _urlCtrl.text,
        method: _method,
        authType: _authType,
        headers: _headers,
        queryParams: _queryParams,
        bodyTemplate: _bodyTemplateCtrl.text,
        stdoutPath: _stdoutPathCtrl.text,
        stderrPath: _stderrPathCtrl.text,
        errorPath: _errorPathCtrl.text,
        executionTimePath: _execTimePathCtrl.text,
        memoryPath: _memoryPathCtrl.text,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(preset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(preset);
      }
      Navigator.pop(context);
    }
  }

  void _testConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testing connection...')));

    try {
      var uri = Uri.parse(_urlCtrl.text);
      if (_queryParams.isNotEmpty) {
        final Map<String, dynamic> qParams = Map.from(uri.queryParameters);
        for (var q in _queryParams) {
          if (q['key']!.isNotEmpty) qParams[q['key']!] = q['value'];
        }
        uri = uri.replace(queryParameters: qParams);
      }

      final Map<String, String> requestHeaders = {};
      for (var h in _headers) {
         if (h['key']!.isNotEmpty) requestHeaders[h['key']!] = h['value']!;
      }

      String requestBody = '';
      if (_method == 'POST' || _method == 'PUT') {
        final code = "void main() { print('Hello from Custom API!'); }";
        final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
        requestBody = _bodyTemplateCtrl.text
            .replaceAll('{code}', '"$safeCode"')
            .replaceAll('{stdin}', '')
            .replaceAll('{language}', 'dart');
      }

      http.Response response;
      if (_method == 'GET') {
        response = await http.get(uri, headers: requestHeaders);
      } else if (_method == 'PUT') {
        response = await http.put(uri, headers: requestHeaders, body: requestBody);
      } else {
        response = await http.post(uri, headers: requestHeaders, body: requestBody);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = jsonDecode(response.body);
        final rawStdout = _stdoutPathCtrl.text.isNotEmpty ? JsonMapper.getValueByPath(decodedResponse, _stdoutPathCtrl.text) : '';

        if (mounted) {
           showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Test Successful'),
              content: SingleChildScrollView(
                child: Text('Parsed Output: ${rawStdout ?? "null"}\n\nRaw Response: ${response.body}'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.statusCode} - ${response.body}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildKeyValueList(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.whiteCream)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.yellowAccent),
              onPressed: () {
                setState(() {
                  items.add({'key': '', 'value': ''});
                });
              },
            )
          ],
        ),
        for (int i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: items[i]['key'],
                    onChanged: (val) => items[i]['key'] = val,
                    decoration: const InputDecoration(labelText: 'Key', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: items[i]['value'],
                    onChanged: (val) => items[i]['value'] = val,
                    decoration: const InputDecoration(labelText: 'Value', border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      items.removeAt(i);
                    });
                  },
                )
              ],
            ),
          )
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _method,
                      decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                      items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _method = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _authType,
                      decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                      items: ['None', 'Header', 'Bearer', 'Basic', 'Query'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _authType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildKeyValueList('Headers', _headers),
              const SizedBox(height: 16),
              _buildKeyValueList('Query Params', _queryParams),
              const SizedBox(height: 16),
              const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.whiteCream)),
              const Text('Use {code}, {language}, {stdin} placeholders', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyTemplateCtrl,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.whiteCream)),
              const SizedBox(height: 8),
              TextFormField(controller: _stdoutPathCtrl, decoration: const InputDecoration(labelText: 'stdout path', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextFormField(controller: _stderrPathCtrl, decoration: const InputDecoration(labelText: 'stderr path', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextFormField(controller: _errorPathCtrl, decoration: const InputDecoration(labelText: 'error path', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextFormField(controller: _execTimePathCtrl, decoration: const InputDecoration(labelText: 'executionTime path', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextFormField(controller: _memoryPathCtrl, decoration: const InputDecoration(labelText: 'memory path', border: OutlineInputBorder())),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.bolt),
                  label: const Text('Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
