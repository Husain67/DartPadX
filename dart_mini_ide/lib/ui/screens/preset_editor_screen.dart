import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../models/compiler_preset.dart';
import '../../providers/settings_provider.dart';
import '../../utils/theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditorScreen({Key? key, this.preset}) : super(key: key);

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _endpointUrl;
  late String _httpMethod;
  late String _authType;
  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  late Map<String, String> _headers;
  late Map<String, String> _queryParams;

  @override
  void initState() {
    super.initState();
    _name = widget.preset?.name ?? '';
    _endpointUrl = widget.preset?.endpointUrl ?? '';
    _httpMethod = widget.preset?.httpMethod ?? 'POST';
    _authType = widget.preset?.authType ?? 'None';
    _bodyTemplate = widget.preset?.bodyTemplate ?? '{"code": "{code}"}';
    _stdoutPath = widget.preset?.stdoutPath ?? '';
    _stderrPath = widget.preset?.stderrPath ?? '';
    _errorPath = widget.preset?.errorPath ?? '';
    _executionTimePath = widget.preset?.executionTimePath ?? '';
    _memoryPath = widget.preset?.memoryPath ?? '';
    _headers = Map.from(widget.preset?.headers ?? {});
    _queryParams = Map.from(widget.preset?.queryParams ?? {});
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = widget.preset?.copyWith(
        name: _name,
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        authType: _authType,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
        headers: _headers,
        queryParams: _queryParams,
      ) ?? CompilerPreset.create(
        name: _name,
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        authType: _authType,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
        headers: _headers,
        queryParams: _queryParams,
      );

      ref.read(settingsProvider.notifier).savePreset(newPreset);
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    Fluttertoast.showToast(msg: "Testing connection...");

    try {
      Uri uri = Uri.parse(_endpointUrl);
      if (_queryParams.isNotEmpty) {
        final mergedParams = Map<String, dynamic>.from(uri.queryParameters);
        mergedParams.addAll(_queryParams);
        uri = uri.replace(queryParameters: mergedParams);
      }

      final headers = Map<String, String>.from(_headers);
      if (_authType == 'Bearer Token' && headers.containsKey('Authorization')) {
        headers['Authorization'] = 'Bearer ${headers['Authorization']}';
      } else if (_authType == 'Basic Auth' && headers.containsKey('Authorization')) {
        final authVal = headers['Authorization']!;
        final bytes = utf8.encode(authVal);
        headers['Authorization'] = 'Basic ${base64.encode(bytes)}';
      }

      String bodyStr = _bodyTemplate;
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
      bodyStr = bodyStr.replaceAll('{stdin}', '');
      bodyStr = bodyStr.replaceAll('{code}', jsonEncode("print('Hello from custom API');").replaceAll(RegExp(r'^"|"$'), ''));

      http.Response response;
      if (_httpMethod == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (_httpMethod == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.post(uri, headers: headers, body: bodyStr);
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgColorEnd,
          title: Text('Status: ${response.statusCode}'),
          content: SingleChildScrollView(
            child: Text(response.body, style: const TextStyle(fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
          ],
        )
      );

    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", backgroundColor: Colors.red);
    }
  }

  void _addKeyValue(Map<String, String> map, String title) async {
    String k = '';
    String v = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgColorEnd,
        title: Text('Add $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Key'), onChanged: (val) => k = val),
            TextField(decoration: const InputDecoration(labelText: 'Value'), onChanged: (val) => v = val),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (k.isNotEmpty) {
              setState(() => map[k] = v);
            }
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow), tooltip: 'Test Connection', onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save), tooltip: 'Save', onPressed: _save),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _endpointUrl,
                      decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                      onSaved: (val) => _endpointUrl = val!,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _endpointUrl));
                      Fluttertoast.showToast(msg: "URL Copied");
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _httpMethod,
                decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _httpMethod = val!),
                onSaved: (val) => _httpMethod = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _authType,
                decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _authType = val!),
                onSaved: (val) => _authType = val!,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryYellow), onPressed: () => _addKeyValue(_headers, 'Header'))
                ],
              ),
              ..._headers.entries.map((e) => ListTile(
                title: Text(e.key), subtitle: Text(e.value),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _headers.remove(e.key))),
              )),
              const Divider(color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryYellow), onPressed: () => _addKeyValue(_queryParams, 'Query Param'))
                ],
              ),
              ..._queryParams.entries.map((e) => ListTile(
                title: Text(e.key), subtitle: Text(e.value),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _queryParams.remove(e.key))),
              )),
              const Divider(color: Colors.white24),
              const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Use {code}, {language}, {stdin} as placeholders.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _bodyTemplate,
                maxLines: 5,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"code": "{code}"}'),
                onSaved: (val) => _bodyTemplate = val!,
              ),
              const SizedBox(height: 24),
              const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _stdoutPath,
                decoration: const InputDecoration(labelText: 'stdout path (e.g. data.output)', border: UnderlineInputBorder()),
                onSaved: (val) => _stdoutPath = val!,
              ),
              TextFormField(
                initialValue: _stderrPath,
                decoration: const InputDecoration(labelText: 'stderr path', border: UnderlineInputBorder()),
                onSaved: (val) => _stderrPath = val!,
              ),
              TextFormField(
                initialValue: _errorPath,
                decoration: const InputDecoration(labelText: 'error path', border: UnderlineInputBorder()),
                onSaved: (val) => _errorPath = val!,
              ),
              TextFormField(
                initialValue: _executionTimePath,
                decoration: const InputDecoration(labelText: 'execution time path', border: UnderlineInputBorder()),
                onSaved: (val) => _executionTimePath = val!,
              ),
              TextFormField(
                initialValue: _memoryPath,
                decoration: const InputDecoration(labelText: 'memory path', border: UnderlineInputBorder()),
                onSaved: (val) => _memoryPath = val!,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
