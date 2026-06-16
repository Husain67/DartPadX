import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../services/compiler_service.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  String _httpMethod = 'POST';
  String _authType = 'None';
  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final List<String> _methods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _endpointCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _bodyTemplateCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{"language": "dart", "stdin": "{stdin}", "files": [{"name": "main.dart", "content": "{code}"}]}');
    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timePathCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _httpMethod = p.httpMethod;
      _authType = p.authType;
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  void _save() {
    if (_nameCtrl.text.isEmpty || _endpointCtrl.text.isEmpty) {
      Fluttertoast.showToast(msg: "Name and Endpoint are required");
      return;
    }

    final newPreset = CompilerPreset(
      id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      endpointUrl: _endpointCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      requestBodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    ref.read(compilerProvider.notifier).addOrUpdatePreset(newPreset);
    Navigator.pop(context);
  }

  void _testConnection() async {
    final tempPreset = CompilerPreset(
      id: 'test',
      name: 'test',
      endpointUrl: _endpointCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      requestBodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    Fluttertoast.showToast(msg: "Testing connection...");

    final result = await CompilerService.executeCode(
      code: "void main() { print('Hello from custom API'); }",
      stdin: "",
      useDefault: false,
      preset: tempPreset,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Test Result', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Parsed Output:', style: TextStyle(color: Color(0xFFFACC15))),
              Text('Stdout: ${result["stdout"]}', style: const TextStyle(color: Colors.white)),
              Text('Stderr: ${result["stderr"]}', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              const Text('Raw Response:', style: TextStyle(color: Color(0xFFFACC15))),
              Text(result['raw'] is String ? result['raw'] : jsonEncode(result['raw']), style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Color(0xFFFACC15))))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow, color: Color(0xFFFACC15)), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save, color: Color(0xFFFACC15)), onPressed: _save, tooltip: 'Save'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTextField(_nameCtrl, 'Platform Name'),
          const SizedBox(height: 12),
          _buildTextField(_endpointCtrl, 'Endpoint URL', maxLines: 2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _httpMethod,
                  dropdownColor: const Color(0xFF1a1a1a),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.white54)),
                  items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _httpMethod = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _authType,
                  dropdownColor: const Color(0xFF1a1a1a),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.white54)),
                  items: _authTypes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _authType = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Headers', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
          ..._headers.asMap().entries.map((e) => _buildKVPair(e.key, e.value, _headers)),
          TextButton.icon(onPressed: () => setState(() => _headers.add(const MapEntry('', ''))), icon: const Icon(Icons.add), label: const Text('Add Header')),

          const SizedBox(height: 24),
          const Text('Query Params', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
          ..._queryParams.asMap().entries.map((e) => _buildKVPair(e.key, e.value, _queryParams)),
          TextButton.icon(onPressed: () => setState(() => _queryParams.add(const MapEntry('', ''))), icon: const Icon(Icons.add), label: const Text('Add Param')),

          const SizedBox(height: 24),
          const Text('Request Body Template', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
          const Text('Use placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
          _buildTextField(_bodyTemplateCtrl, '', maxLines: 6, isCode: true),

          const SizedBox(height: 24),
          const Text('Response Mapping (dot notation)', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
          _buildTextField(_stdoutPathCtrl, 'stdout path (e.g., output.stdout)'),
          _buildTextField(_stderrPathCtrl, 'stderr path'),
          _buildTextField(_errorPathCtrl, 'error path'),
          _buildTextField(_timePathCtrl, 'executionTime path'),
          _buildTextField(_memoryPathCtrl, 'memory path'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {int maxLines = 1, bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white, fontFamily: isCode ? 'monospace' : null),
        decoration: InputDecoration(
          labelText: label.isNotEmpty ? label : null,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildKVPair(int index, MapEntry<String, String> entry, List<MapEntry<String, String>> list) {
    return Row(
      key: ValueKey('kv_\${list.hashCode}_\$index'),
      children: [
        Expanded(
          child: TextFormField(
            initialValue: entry.key,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.white30)),
            onChanged: (v) => list[index] = MapEntry(v, list[index].value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: entry.value,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.white30)),
            onChanged: (v) => list[index] = MapEntry(list[index].key, v),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => setState(() => list.removeAt(index)),
        ),
      ],
    );
  }
}
