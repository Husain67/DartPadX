import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../services/compiler_service.dart';
import 'theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset; // Null means new preset

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late TextEditingController _bodyTemplateCtrl;

  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _execTimePathCtrl;
  late TextEditingController _memoryPathCtrl;

  String _httpMethod = 'POST';
  String _authType = 'None';

  // Tables
  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _endpointCtrl = TextEditingController(text: p?.endpoint ?? '');
    _bodyTemplateCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{\n  "code": "{code}",\n  "language": "{language}"\n}');

    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? '');
    _execTimePathCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _httpMethod = p.httpMethod;
      _authType = p.authType;
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _endpointCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _execTimePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newPreset = CompilerPreset(
      id: widget.preset?.id ?? '', // Provider will assign new ID if empty
      name: _nameCtrl.text,
      endpoint: _endpointCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      requestBodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _execTimePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    if (widget.preset == null) {
      ref.read(compilerProvider.notifier).addPreset(newPreset);
      Fluttertoast.showToast(msg: "Preset created");
    } else {
      ref.read(compilerProvider.notifier).updatePreset(newPreset);
      Fluttertoast.showToast(msg: "Preset updated");
    }
    Navigator.pop(context);
  }

  void _testConnection() async {
    final testPreset = CompilerPreset(
      id: 'test',
      name: 'test',
      endpoint: _endpointCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      requestBodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _execTimePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    Fluttertoast.showToast(msg: "Testing connection...");
    final svc = CompilerService();
    final res = await svc.executeCode("void main() { print('Hello from Custom API'); }", testPreset);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.backgroundEnd,
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stdout: ${res.stdout}', style: const TextStyle(color: Colors.greenAccent)),
              Text('Stderr: ${res.stderr}', style: const TextStyle(color: Colors.redAccent)),
              Text('Time: ${res.executionTime}'),
              Text('Memory: ${res.memory}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _addKeyValue(List<MapEntry<String, String>> list, String title) {
    String k = '';
    String v = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundEnd,
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
          TextButton(
            onPressed: () {
              if (k.isNotEmpty) {
                setState(() => list.add(MapEntry(k, v)));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<MapEntry<String, String>> list, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent), onPressed: () => _addKeyValue(list, title)),
          ],
        ),
        if (list.isEmpty)
          const Text('None', style: TextStyle(color: Colors.white54, fontSize: 12))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${item.key}: ${item.value}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => setState(() => list.removeAt(index)),
                ),
              );
            },
          ),
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
          IconButton(
            icon: const Icon(Icons.bug_report, color: AppTheme.primaryAccent),
            tooltip: 'Test Connection',
            onPressed: _testConnection,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Preset Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointCtrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _httpMethod,
                    decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                    items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _httpMethod = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            _buildTable(_headers, 'Headers'),
            const Divider(color: Colors.white24),
            _buildTable(_queryParams, 'Query Parameters'),
            const Divider(color: Colors.white24),
            const Text('Request Body (JSON Template)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Placeholders: {code}, {language}, {stdin}', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateCtrl,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const Divider(color: Colors.white24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('e.g., data.output.stdout', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            TextFormField(controller: _stdoutPathCtrl, decoration: const InputDecoration(labelText: 'Stdout Path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _stderrPathCtrl, decoration: const InputDecoration(labelText: 'Stderr Path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _errorPathCtrl, decoration: const InputDecoration(labelText: 'Error Path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _execTimePathCtrl, decoration: const InputDecoration(labelText: 'Execution Time Path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _memoryPathCtrl, decoration: const InputDecoration(labelText: 'Memory Path', border: OutlineInputBorder())),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
