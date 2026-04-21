import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../providers/compiler_preset_provider.dart';
import '../utils/theme.dart';
import '../models/compiler_preset.dart';
import '../utils/file_actions.dart';

class PresetEditScreen extends ConsumerStatefulWidget {
  final String presetId;
  const PresetEditScreen({super.key, required this.presetId});

  @override
  ConsumerState<PresetEditScreen> createState() => _PresetEditScreenState();
}

class _PresetEditScreenState extends ConsumerState<PresetEditScreen> {
  late CompilerPreset _preset;
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _authValCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  final _outMapCtrl = TextEditingController();
  final _errMapCtrl = TextEditingController();
  final _err2MapCtrl = TextEditingController();
  final _timeMapCtrl = TextEditingController();
  final _memMapCtrl = TextEditingController();

  String _method = 'POST';
  String _authType = 'None';
  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _preset = ref.read(compilerPresetProvider).firstWhere((p) => p.id == widget.presetId);
    _nameCtrl.text = _preset.name;
    _urlCtrl.text = _preset.url;
    _authValCtrl.text = _preset.authValue;
    _bodyCtrl.text = _preset.bodyTemplate;
    _method = _preset.method;
    _authType = _preset.authType;
    _headers = List.from(_preset.headers);
    _queryParams = List.from(_preset.queryParams);

    _outMapCtrl.text = _preset.responseMappings['stdout'] ?? '';
    _errMapCtrl.text = _preset.responseMappings['stderr'] ?? '';
    _err2MapCtrl.text = _preset.responseMappings['error'] ?? '';
    _timeMapCtrl.text = _preset.responseMappings['executionTime'] ?? '';
    _memMapCtrl.text = _preset.responseMappings['memory'] ?? '';
  }

  void _save() {
    final updated = _preset.copyWith(
      name: _nameCtrl.text,
      url: _urlCtrl.text,
      method: _method,
      authType: _authType,
      authValue: _authValCtrl.text,
      bodyTemplate: _bodyCtrl.text,
      headers: _headers,
      queryParams: _queryParams,
      responseMappings: {
        'stdout': _outMapCtrl.text,
        'stderr': _errMapCtrl.text,
        'error': _err2MapCtrl.text,
        'executionTime': _timeMapCtrl.text,
        'memory': _memMapCtrl.text,
      },
    );
    ref.read(compilerPresetProvider.notifier).updatePreset(updated);
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.accentYellow)),
    );

    final uri = Uri.parse(_urlCtrl.text);
    final mapHeaders = <String, String>{};
    for (final h in _headers) {
      mapHeaders[h.key] = h.value;
    }

    try {
      final res = _method == 'POST'
        ? await http.post(uri, headers: mapHeaders, body: _bodyCtrl.text.replaceAll('{code}', '"print(\'Hello Test\');"').replaceAll('{language}', 'dart').replaceAll('{stdin}', ''))
        : await http.get(uri, headers: mapHeaders);

      if (!mounted) return;
      Navigator.pop(context); // close loader

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Test Response (${res.statusCode})'),
          content: SingleChildScrollView(child: Text(res.body, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: AppTheme.accentYellow), onPressed: _save),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.bgDarkStart, AppTheme.bgDarkEnd], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
            Row(
              children: [
                Expanded(child: TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white))),
                IconButton(icon: const Icon(Icons.copy, color: Colors.white54), onPressed: () => FileActions.copyToClipboard(_urlCtrl.text)),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: _method,
              dropdownColor: AppTheme.bgDarkEnd,
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setState(() => _method = v!),
              decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.white70)),
            ),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              dropdownColor: AppTheme.bgDarkEnd,
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
              decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.white70)),
            ),
            if (_authType != 'None')
              TextField(controller: _authValCtrl, decoration: const InputDecoration(labelText: 'Auth Value', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),

            const SizedBox(height: 16),
            const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentYellow)),
            ..._headers.asMap().entries.map((e) => Row(
              children: [
                Expanded(child: TextFormField(initialValue: e.value.key, onChanged: (v) => _headers[e.key] = MapEntry(v, _headers[e.key].value), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(initialValue: e.value.value, onChanged: (v) => _headers[e.key] = MapEntry(_headers[e.key].key, v), style: const TextStyle(color: Colors.white))),
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _headers.removeAt(e.key))),
              ],
            )),
            TextButton(onPressed: () => setState(() => _headers.add(const MapEntry('',''))), child: const Text('Add Header')),

            const SizedBox(height: 16),
            const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentYellow)),
            ..._queryParams.asMap().entries.map((e) => Row(
              children: [
                Expanded(child: TextFormField(initialValue: e.value.key, onChanged: (v) => _queryParams[e.key] = MapEntry(v, _queryParams[e.key].value), style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(initialValue: e.value.value, onChanged: (v) => _queryParams[e.key] = MapEntry(_queryParams[e.key].key, v), style: const TextStyle(color: Colors.white))),
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _queryParams.removeAt(e.key))),
              ],
            )),
            TextButton(onPressed: () => setState(() => _queryParams.add(const MapEntry('',''))), child: const Text('Add Query Param')),

            const SizedBox(height: 16),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentYellow)),
            TextField(controller: _bodyCtrl, maxLines: 5, decoration: const InputDecoration(hintText: '{ "code": {code} }', hintStyle: TextStyle(color: Colors.white30)), style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),

            const SizedBox(height: 16),
            const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentYellow)),
            TextField(controller: _outMapCtrl, decoration: const InputDecoration(labelText: 'stdout path', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
            TextField(controller: _errMapCtrl, decoration: const InputDecoration(labelText: 'stderr path', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
            TextField(controller: _err2MapCtrl, decoration: const InputDecoration(labelText: 'error path', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
            TextField(controller: _timeMapCtrl, decoration: const InputDecoration(labelText: 'executionTime path', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
            TextField(controller: _memMapCtrl, decoration: const InputDecoration(labelText: 'memory path', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testConnection,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.toolbarItemBg, foregroundColor: Colors.black),
              child: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
