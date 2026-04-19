import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset; // if null, creating new

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
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  bool get _isBuiltIn => widget.preset?.isBuiltIn ?? false;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? 'New Compiler API');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _method = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyCtrl = TextEditingController(text: p?.bodyTemplate ?? '{\n  "code": {code},\n  "language": "dart"\n}');

    _headers = p != null ? List.from(p.headers) : [];
    _queryParams = p != null ? List.from(p.queryParams) : [];

    _stdoutCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timeCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memCtrl = TextEditingController(text: p?.memoryPath ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutCtrl.dispose();
    _stderrCtrl.dispose();
    _errorCtrl.dispose();
    _timeCtrl.dispose();
    _memCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_isBuiltIn) return; // Cannot edit built-in
    if (!_formKey.currentState!.validate()) return;

    final preset = CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: _headers,
      queryParams: _queryParams,
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memCtrl.text,
    );

    ref.read(settingsProvider.notifier).savePreset(preset);
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    // A simplified test mechanism that mimics executionProvider logic to verify the current setup.
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

      final headers = <String, String>{};
      for (var h in _headers) { if (h.key.isNotEmpty) headers[h.key] = h.value; }

      if (_authType == 'API-Key Header') {
        headers['X-RapidAPI-Key'] = _authValueCtrl.text;
      } else if (_authType == 'Bearer Token') {
        headers['Authorization'] = 'Bearer ${_authValueCtrl.text}';
      } else if (_authType == 'Basic Auth') {
        final b64 = base64.encode(utf8.encode(_authValueCtrl.text));
        headers['Authorization'] = 'Basic $b64';
      }

      final uri = Uri.parse(_urlCtrl.text).replace(
        queryParameters: _queryParams.isEmpty ? null : { for (var q in _queryParams) if(q.key.isNotEmpty) q.key: q.value }
      );

      final safeCode = jsonEncode("print('Hello from custom API');").replaceAll(RegExp(r'^"|"$'), '');
      String body = _bodyCtrl.text.replaceAll('{code}', '"$safeCode"').replaceAll('{stdin}', '""');

      late http.Response response;
      if (_method == 'POST') {
        response = await http.post(uri, headers: headers, body: body);
      } else {
        response = await http.get(uri, headers: headers);
      }

      if (!mounted) return;
      Navigator.pop(context); // pop loading

      _showTestResultDialog("Status: ${response.statusCode}\n\nBody:\n${response.body}");

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showTestResultDialog("Error:\n$e");
    }
  }

  void _showTestResultDialog(String text) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Test Result'),
      content: SingleChildScrollView(child: SelectableText(text)),
      actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          if (!_isBuiltIn && widget.preset != null)
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorRed),
              onPressed: () {
                ref.read(settingsProvider.notifier).deletePreset(widget.preset!.id);
                Navigator.pop(context);
              },
            ),
          if (!_isBuiltIn)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isBuiltIn)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white10,
                child: const Text('This is a built-in preset and cannot be modified. Duplicate it to make changes.', style: TextStyle(color: Colors.orange)),
              ),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Platform / Preset Name', border: OutlineInputBorder()),
              readOnly: _isBuiltIn,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
                    readOnly: _isBuiltIn,
                    maxLines: null,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                    items: ['POST', 'GET'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: _isBuiltIn ? null : (v) => setState(() => _method = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: _isBuiltIn ? null : (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _authValueCtrl,
                decoration: const InputDecoration(labelText: 'Auth Value (Key/Token/user:pass)', border: OutlineInputBorder()),
                readOnly: _isBuiltIn,
              ),
            ],
            const SizedBox(height: 24),
            _buildDynamicTable('Headers', _headers),
            _buildDynamicTable('Query Params', _queryParams),
            const SizedBox(height: 24),
            const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Use {code} for source and {stdin} for input.', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'JSON template'),
              maxLines: 8,
              readOnly: _isBuiltIn,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('e.g., data.run.stdout', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            _buildMappingField('Stdout Path', _stdoutCtrl),
            _buildMappingField('Stderr Path', _stderrCtrl),
            _buildMappingField('Error Path', _errorCtrl),
            _buildMappingField('Exec Time Path', _timeCtrl),
            _buildMappingField('Memory Path', _memCtrl),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Connection'),
            ),
            const SizedBox(height: 40),
          ],
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
        readOnly: _isBuiltIn,
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (!_isBuiltIn)
              TextButton(
                onPressed: () => setState(() => items.add(const MapEntry('', ''))),
                child: const Text('Add Row'),
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
                    initialValue: items[i].key,
                    decoration: const InputDecoration(hintText: 'Key', isDense: true, border: OutlineInputBorder()),
                    readOnly: _isBuiltIn,
                    onChanged: (v) => items[i] = MapEntry(v, items[i].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: items[i].value,
                    decoration: const InputDecoration(hintText: 'Value', isDense: true, border: OutlineInputBorder()),
                    readOnly: _isBuiltIn,
                    onChanged: (v) => items[i] = MapEntry(items[i].key, v),
                  ),
                ),
                if (!_isBuiltIn)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: AppTheme.errorRed),
                    onPressed: () => setState(() => items.removeAt(i)),
                  )
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
