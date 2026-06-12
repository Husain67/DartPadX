import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../providers/compiler_notifier.dart';
import '../../providers/execution_notifier.dart';
import '../../models/compiler_preset.dart';
import '../../models/response_mapping.dart';
import '../../theme/app_theme.dart';

class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditor({super.key, this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _bodyTemplateController;

  late TextEditingController _stdoutPathController;
  late TextEditingController _stderrPathController;
  late TextEditingController _errorPathController;
  late TextEditingController _timePathController;
  late TextEditingController _memoryPathController;

  String _httpMethod = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;

    _nameController = TextEditingController(text: p?.name ?? '');
    _urlController = TextEditingController(text: p?.endpointUrl ?? '');
    _bodyTemplateController = TextEditingController(text: p?.requestBodyTemplate ?? '');

    _stdoutPathController = TextEditingController(text: p?.responseMapping.stdoutPath ?? '');
    _stderrPathController = TextEditingController(text: p?.responseMapping.stderrPath ?? '');
    _errorPathController = TextEditingController(text: p?.responseMapping.errorPath ?? '');
    _timePathController = TextEditingController(text: p?.responseMapping.timePath ?? '');
    _memoryPathController = TextEditingController(text: p?.responseMapping.memoryPath ?? '');

    if (p != null) {
      _httpMethod = p.httpMethod;
      _authType = p.authType;
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _bodyTemplateController.dispose();
    _stdoutPathController.dispose();
    _stderrPathController.dispose();
    _errorPathController.dispose();
    _timePathController.dispose();
    _memoryPathController.dispose();
    super.dispose();
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      final newMapping = ResponseMapping(
        stdoutPath: _stdoutPathController.text,
        stderrPath: _stderrPathController.text,
        errorPath: _errorPathController.text,
        timePath: _timePathController.text,
        memoryPath: _memoryPathController.text,
      );

      final newPreset = (widget.preset ?? CompilerPreset(name: '', endpointUrl: '', responseMapping: newMapping)).copyWith(
        name: _nameController.text,
        endpointUrl: _urlController.text,
        httpMethod: _httpMethod,
        authType: _authType,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _bodyTemplateController.text,
        responseMapping: newMapping,
      );

      ref.read(compilerProvider.notifier).savePreset(newPreset);
      Fluttertoast.showToast(msg: "Preset saved");
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    final urlStr = _urlController.text;
    if (urlStr.isEmpty) {
      Fluttertoast.showToast(msg: "URL is empty");
      return;
    }

    try {
      var uri = Uri.parse(urlStr);
      final queryParamsMap = Map.fromEntries(_queryParams);

      if (queryParamsMap.isNotEmpty) {
        final mergedParams = Map<String, dynamic>.from(uri.queryParameters);
        mergedParams.addAll(queryParamsMap);
        uri = uri.replace(queryParameters: mergedParams);
      }

      final headers = Map.fromEntries(_headers);

      String mockCode = jsonEncode("print('Hello from custom API');");
      mockCode = mockCode.substring(1, mockCode.length - 1);

      String bodyStr = _bodyTemplateController.text
          .replaceAll('{code}', mockCode)
          .replaceAll('{stdin}', '')
          .replaceAll('{language}', 'dart');

      http.Response response;
      if (_httpMethod == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      String parsedOutput = 'Could not parse response';
      try {
        final decoded = jsonDecode(response.body);
        final execNotifier = ref.read(executionProvider.notifier);

        final stdout = execNotifier.extractValue(decoded, _stdoutPathController.text) ?? '';
        final stderrStr = execNotifier.extractValue(decoded, _stderrPathController.text) ?? '';
        final errorStr = execNotifier.extractValue(decoded, _errorPathController.text) ?? '';
        final time = execNotifier.extractValue(decoded, _timePathController.text) ?? '';
        final mem = execNotifier.extractValue(decoded, _memoryPathController.text) ?? '';

        parsedOutput = 'Parsed stdout: \$stdout\n'
                       'Parsed stderr: \$stderrStr\n'
                       'Parsed error: \$errorStr\n'
                       'Parsed time: \$time\n'
                       'Parsed memory: \$mem';
      } catch (e) {
        parsedOutput = 'JSON Parse Error: \$e';
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Test Result: ${response.statusCode}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(response.body, style: const TextStyle(fontSize: 12)),
                const Divider(),
                const Text('Parsed Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(parsedOutput, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Test failed: \$e");
    }
  }

  Widget _buildMapEditor(String title, List<MapEntry<String, String>> items, Function(List<MapEntry<String, String>>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('', ''));
                  onChanged(items);
                });
              },
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: items[index].key,
                    decoration: const InputDecoration(hintText: 'Key', isDense: true),
                    onChanged: (val) {
                      items[index] = MapEntry(val, items[index].value);
                      onChanged(items);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: items[index].value,
                    decoration: const InputDecoration(hintText: 'Value', isDense: true),
                    onChanged: (val) {
                      items[index] = MapEntry(items[index].key, val);
                      onChanged(items);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      items.removeAt(index);
                      onChanged(items);
                    });
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Test Connection',
            onPressed: _testConnection,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _savePreset,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _httpMethod,
                      decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                      items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => _httpMethod = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _authType,
                      decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                      items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => _authType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMapEditor('Headers', _headers, (val) => _headers = val),
              const Divider(),
              _buildMapEditor('Query Params', _queryParams, (val) => _queryParams = val),
              const Divider(),
              const Text('Request Body Template JSON', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Use {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyTemplateController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const Divider(),
              const Text('Response Mapping (Dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(controller: _stdoutPathController, decoration: const InputDecoration(labelText: 'stdout path', isDense: true)),
              TextFormField(controller: _stderrPathController, decoration: const InputDecoration(labelText: 'stderr path', isDense: true)),
              TextFormField(controller: _errorPathController, decoration: const InputDecoration(labelText: 'error path', isDense: true)),
              TextFormField(controller: _timePathController, decoration: const InputDecoration(labelText: 'executionTime path', isDense: true)),
              TextFormField(controller: _memoryPathController, decoration: const InputDecoration(labelText: 'memory path', isDense: true)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
