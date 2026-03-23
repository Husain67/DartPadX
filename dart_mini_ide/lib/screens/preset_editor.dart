import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  String _httpMethod = 'POST';
  String _authType = 'None';
  late TextEditingController _authValueCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }

    _bodyCtrl = TextEditingController(text: p?.bodyTemplate ?? '{"code": "{code}"}');
    _stdoutCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timeCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryCtrl = TextEditingController(text: p?.memoryPath ?? '');
  }

  CompilerPreset _buildPreset() {
    return CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memoryCtrl.text,
    );
  }

  void _save() {
    final p = _buildPreset();
    if (widget.preset == null) {
      ref.read(compilerProvider.notifier).addPreset(p);
    } else {
      ref.read(compilerProvider.notifier).updatePreset(p);
    }
    Navigator.pop(context);
  }

  void _testConnection() async {
    final p = _buildPreset();
    final apiService = ApiService(ref);
    try {
      Fluttertoast.showToast(msg: "Testing connection...", backgroundColor: AppTheme.accentYellow, textColor: Colors.black);
      final result = await apiService.executeCustomPreset("print('Hello from custom API');", p);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.backgroundEnd,
          title: const Text('Test Result', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Text(
              "stdout: ${result['stdout']}\n\nstderr: ${result['stderr']}\n\ntime: ${result['executionTime']}",
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        )
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Test Failed: $e", backgroundColor: Colors.red);
    }
  }

  Widget _buildDynamicList(String title, List<MapEntry<String, String>> list, Function(List<MapEntry<String, String>>) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.accentYellow),
              onPressed: () {
                setState(() {
                  list.add(const MapEntry('', ''));
                });
              },
            )
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.key,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.grey)),
                    onChanged: (v) => list[idx] = MapEntry(v, item.value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.value,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.grey)),
                    onChanged: (v) => list[idx] = MapEntry(item.key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => list.removeAt(idx)),
                )
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow, color: AppTheme.accentYellow), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Platform Name', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 16),
            TextField(controller: _urlCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Endpoint URL', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _httpMethod,
              dropdownColor: AppTheme.backgroundEnd,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.grey)),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _httpMethod = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType,
              dropdownColor: AppTheme.backgroundEnd,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.grey)),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextField(controller: _authValueCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Auth Value', labelStyle: TextStyle(color: Colors.grey))),
            ],
            const SizedBox(height: 24),
            _buildDynamicList('Headers', _headers, (l) => setState(() => _headers = l)),
            const SizedBox(height: 24),
            _buildDynamicList('Query Params', _queryParams, (l) => setState(() => _queryParams = l)),
            const SizedBox(height: 24),
            const Text('Request Body Template (JSON)', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold)),
            const Text('Use {code}, {language}, {stdin}', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(controller: _bodyCtrl, maxLines: 5, style: const TextStyle(color: Colors.white, fontFamily: 'monospace'), decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 24),
            const Text('Response Mapping (dot notation)', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold)),
            TextField(controller: _stdoutCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'stdout path', labelStyle: TextStyle(color: Colors.grey))),
            TextField(controller: _stderrCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'stderr path', labelStyle: TextStyle(color: Colors.grey))),
            TextField(controller: _errorCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'error path', labelStyle: TextStyle(color: Colors.grey))),
            TextField(controller: _timeCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'executionTime path', labelStyle: TextStyle(color: Colors.grey))),
            TextField(controller: _memoryCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'memory path', labelStyle: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}
