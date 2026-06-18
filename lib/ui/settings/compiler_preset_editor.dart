import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../../models/compiler_preset.dart';
import '../../providers/compiler_provider.dart';
import '../../core/theme.dart';
import '../../providers/execution_provider.dart';

class CompilerPresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const CompilerPresetEditor({super.key, this.preset});

  @override
  ConsumerState<CompilerPresetEditor> createState() => _CompilerPresetEditorState();
}

class _CompilerPresetEditorState extends ConsumerState<CompilerPresetEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.platformName ?? '');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _method = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{}');
    _stdoutCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timeCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  void _save() {
    final Map<String, String> headersMap = {};
    for (var h in _headers) {
      if (h.key.isNotEmpty) headersMap[h.key] = h.value;
    }
    final Map<String, String> queryParamsMap = {};
    for (var q in _queryParams) {
      if (q.key.isNotEmpty) queryParamsMap[q.key] = q.value;
    }

    final updated = CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      platformName: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      headers: headersMap,
      queryParams: queryParamsMap,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memCtrl.text,
      isDefault: widget.preset?.isDefault ?? false,
    );
    ref.read(compilerProvider.notifier).savePreset(updated);
    Navigator.pop(context);
  }

  void _testConnection() async {
    final Map<String, String> headersMap = {};
    for (var h in _headers) {
      if (h.key.isNotEmpty) headersMap[h.key] = h.value;
    }
    final Map<String, String> queryParamsMap = {};
    for (var q in _queryParams) {
      if (q.key.isNotEmpty) queryParamsMap[q.key] = q.value;
    }

    final tempPreset = CompilerPreset(
      id: 'temp',
      platformName: 'temp',
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      headers: headersMap,
      queryParams: queryParamsMap,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memCtrl.text,
    );

    // Call execution provider so it shows parsed output
    ref.read(executionProvider.notifier).executeCode("void main() { print('Hello from custom API'); }", "", tempPreset);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test started. Check Output console.')),
    );

    // Run independent check to show raw response dialog
    try {
        final uri = Uri.parse(_urlCtrl.text);
        final codeStr = jsonEncode("void main() { print('Hello from custom API'); }");
        final requestBody = _bodyCtrl.text.replaceAll('{code}', codeStr.substring(1, codeStr.length - 1)).replaceAll('{stdin}', '').replaceAll('{language}', 'dart');

        http.Response response;
        if (_method == 'POST') {
            response = await http.post(uri, headers: headersMap, body: requestBody);
        } else {
            response = await http.get(uri, headers: headersMap);
        }

        if (mounted) {
            showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                    title: const Text('Raw Response'),
                    content: SingleChildScrollView(
                        child: SelectableText(
                            response.body,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                    ),
                    actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                    ]
                )
            );
        }
    } catch(e) {
        if (mounted) {
             showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                    title: const Text('Raw Response Error'),
                    content: Text(e.toString()),
                    actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                    ]
                )
            );
        }
    }
  }

  Widget _buildMapEditor(String title, List<MapEntry<String, String>> mapList, Function(List<MapEntry<String, String>>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
              onPressed: () {
                setState(() {
                  mapList.add(const MapEntry('', ''));
                  onChanged(mapList);
                });
              },
            ),
          ],
        ),
        ...mapList.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> item = entry.value;
          return Row(
            key: ValueKey('${title}-${idx}'),
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.key,
                  decoration: const InputDecoration(hintText: 'Key'),
                  onChanged: (val) {
                    mapList[idx] = MapEntry(val, item.value);
                    onChanged(mapList);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.value,
                  decoration: const InputDecoration(hintText: 'Value'),
                  onChanged: (val) {
                    mapList[idx] = MapEntry(item.key, val);
                    onChanged(mapList);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: AppTheme.errorColor),
                onPressed: () {
                  setState(() {
                    mapList.removeAt(idx);
                    onChanged(mapList);
                  });
                },
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit ${widget.preset!.platformName}'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow, color: Colors.green), tooltip: 'Test Connection', onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save), tooltip: 'Save', onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL'))),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _method,
                    items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _method = val!),
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _authType,
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _authType = val!),
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMapEditor('Dynamic Headers', _headers, (v) => _headers = v),
            const SizedBox(height: 24),
            _buildMapEditor('Dynamic Query Params', _queryParams, (v) => _queryParams = v),
            const SizedBox(height: 24),
            const Text('Request Body Template JSON', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"code": "{code}"}'),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path', hintText: 'output.stdout')),
            TextField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path')),
            TextField(controller: _errorCtrl, decoration: const InputDecoration(labelText: 'error path')),
            TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'executionTime path')),
            TextField(controller: _memCtrl, decoration: const InputDecoration(labelText: 'memory path')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
