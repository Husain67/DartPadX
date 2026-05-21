import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset_model.dart';
import '../providers/preset_provider.dart';
import '../theme/app_theme.dart';
import '../utils/ui_utils.dart';
import 'package:http/http.dart' as http;

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPresetModel? preset;
  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _urlCtrl, _bodyCtrl;
  late TextEditingController _outMapCtrl, _errMapCtrl, _timeMapCtrl, _memMapCtrl;

  String _method = 'POST';
  String _authType = 'None';
  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _urlCtrl = TextEditingController(text: p?.url ?? '');
    _bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{"code": "{code}"}');
    _outMapCtrl = TextEditingController(text: p?.outputMappingPath ?? '');
    _errMapCtrl = TextEditingController(text: p?.errorMappingPath ?? '');
    _timeMapCtrl = TextEditingController(text: p?.executionTimeMappingPath ?? '');
    _memMapCtrl = TextEditingController(text: p?.memoryMappingPath ?? '');

    if (p != null) {
      _method = p.method;
      _authType = p.authType;
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _urlCtrl.dispose(); _bodyCtrl.dispose();
    _outMapCtrl.dispose(); _errMapCtrl.dispose(); _timeMapCtrl.dispose(); _memMapCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPresetModel(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameCtrl.text,
        url: _urlCtrl.text,
        method: _method,
        authType: _authType,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _bodyCtrl.text,
        outputMappingPath: _outMapCtrl.text,
        errorMappingPath: _errMapCtrl.text,
        executionTimeMappingPath: _timeMapCtrl.text,
        memoryMappingPath: _memMapCtrl.text,
      );

      if (widget.preset == null) {
        ref.read(presetProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(presetProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    // Simulate what ExecutionProvider does for a basic test
    var urlString = _urlCtrl.text;
    if (_queryParams.isNotEmpty) {
       final uri = Uri.tryParse(urlString);
       if (uri != null) {
          urlString = uri.replace(queryParameters: Map.fromEntries(_queryParams)).toString();
       }
    }

    final headers = Map.fromEntries(_headers);
    String bodyString = _bodyCtrl.text;
    String safeCode = jsonEncode("print('Hello from Custom API');");
    safeCode = safeCode.substring(1, safeCode.length - 1);
    bodyString = bodyString.replaceAll('{code}', safeCode).replaceAll('{stdin}', '').replaceAll('{language}', 'dart');

    try {
      http.Response response;
      if (_method == 'GET') {
        response = await http.get(Uri.parse(urlString), headers: headers);
      } else {
        response = await http.post(Uri.parse(urlString), headers: headers, body: bodyString);
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Test Result (\${response.statusCode})'),
          content: SingleChildScrollView(child: Text(response.body)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        )
      );
    } catch (e) {
      UiUtils.showToast('Test failed: \$e', isError: true);
    } finally {
      if (mounted) setState(() => _isTesting = false);
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
        decoration: AppTheme.backgroundGradient,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
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
                      items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _method = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _authType,
                      decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                      items: ['None', 'Header API Key', 'Bearer Token', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _authType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDynamicTable('Headers', _headers),
              _buildDynamicTable('Query Params', _queryParams),
              const SizedBox(height: 16),
              const Text('Request Body JSON Template (use {code}, {stdin})', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 5,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"source": "{code}"}'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text('Response JSON Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildMappingField('Stdout Path (e.g., result.output)', _outMapCtrl),
              _buildMappingField('Stderr/Error Path', _errMapCtrl),
              _buildMappingField('Execution Time Path', _timeMapCtrl),
              _buildMappingField('Memory Usage Path', _memMapCtrl),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.network_check),
                label: const Text('Test Connection'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMappingField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              onPressed: () => setState(() => list.add(const MapEntry('', ''))),
            )
          ],
        ),
        if (list.isEmpty) const Text('None', style: TextStyle(color: Colors.white38)),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> kv = entry.value;
          return Padding(
            key: ValueKey('\$title-\$idx'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: kv.key,
                    decoration: const InputDecoration(labelText: 'Key', isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => list[idx] = MapEntry(v, list[idx].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: kv.value,
                    decoration: const InputDecoration(labelText: 'Value', isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => list[idx] = MapEntry(list[idx].key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => setState(() => list.removeAt(idx)),
                )
              ],
            ),
          );
        }),
      ],
    );
  }
}
