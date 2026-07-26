import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/compiler_preset.dart';
import '../../data/providers/compiler_provider.dart';
import '../../services/execution_service.dart';

class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditor({super.key, this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  final _formKey = GlobalKey<FormState>();

  late String _id;
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  String _method = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final List<String> _methods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = [
    'None',
    'API-Key Header',
    'Bearer Token',
    'Basic Auth',
    'Query Param'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _id = p?.id ?? const Uuid().v4();
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _endpointCtrl = TextEditingController(text: p?.endpoint ?? '');
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyCtrl = TextEditingController(
        text: p?.bodyTemplate ?? '{\n  "code": "{code}",\n  "stdin": "{stdin}"\n}');
    _stdoutCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _timeCtrl = TextEditingController(text: p?.timePath ?? '');
    _memoryCtrl = TextEditingController(text: p?.memoryPath ?? '');

    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';

    _headers = p?.headers.entries.toList() ?? [];
    _queryParams = p?.queryParams.entries.toList() ?? [];
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final preset = _buildPresetFromForm();
      ref.read(compilerProvider.notifier).savePreset(preset);
      Navigator.pop(context);
    }
  }

  CompilerPreset _buildPresetFromForm() {
    return CompilerPreset(
      id: _id,
      name: _nameCtrl.text,
      endpoint: _endpointCtrl.text,
      method: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      timePath: _timeCtrl.text,
      memoryPath: _memoryCtrl.text,
    );
  }

  void _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    final tempPreset = _buildPresetFromForm();

    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

    final result = await ExecutionService.runCode(
        code: "void main() { print('Hello from custom API'); }",
        useDefault: false,
        customPreset: tempPreset);

    // ignore: use_build_context_synchronously
    if (!mounted) return;
    Navigator.pop(context); // pop loading

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stdout: \${result.stdout}', style: const TextStyle(color: Colors.green)),
              const Divider(),
              Text('Stderr/Raw: \${result.stderr}', style: const TextStyle(color: Colors.red)),
              const Divider(),
              Text('Time: \${result.time}'),
              Text('Memory: \${result.memory}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      )
    );
  }

  Widget _buildMapEditor(String title, List<MapEntry<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
             IconButton(
               icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryAccent),
               onPressed: () => setState(() => items.add(const MapEntry('', '')))
             )
          ],
        ),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> kv = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: kv.key,
                    decoration: const InputDecoration(hintText: 'Key', isDense: true),
                    onChanged: (v) => items[idx] = MapEntry(v, kv.value),
                  )
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: kv.value,
                    decoration: const InputDecoration(hintText: 'Value', isDense: true),
                    onChanged: (v) => items[idx] = MapEntry(kv.key, v),
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => setState(() => items.removeAt(idx))
                )
              ],
            ),
          );
        })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          TextButton.icon(
             icon: const Icon(Icons.play_arrow, color: Colors.green),
             label: const Text('Test', style: TextStyle(color: Colors.green)),
             onPressed: _testConnection,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryAccent),
            onPressed: _save,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Preset Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointCtrl,
              decoration: const InputDecoration(
                  labelText: 'Endpoint URL', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _method,
                    decoration: const InputDecoration(
                        labelText: 'Method', border: OutlineInputBorder()),
                    items: _methods
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _authType,
                    decoration: const InputDecoration(
                        labelText: 'Auth Type', border: OutlineInputBorder()),
                    items: _authTypes
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _authValueCtrl,
                decoration: InputDecoration(
                  labelText: _authType == 'API-Key Header'
                      ? 'HeaderName:KeyValue'
                      : 'Auth Value',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildMapEditor('Dynamic Headers', _headers),
            const SizedBox(height: 16),
            _buildMapEditor('Dynamic Query Params', _queryParams),
            const SizedBox(height: 24),
            const Text('Request Body Template (JSON)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language}',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
                controller: _stdoutCtrl,
                decoration: const InputDecoration(
                    labelText: 'Stdout Path', isDense: true)),
            TextFormField(
                controller: _stderrCtrl,
                decoration: const InputDecoration(
                    labelText: 'Stderr Path', isDense: true)),
            TextFormField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Time Path', isDense: true)),
            TextFormField(
                controller: _memoryCtrl,
                decoration: const InputDecoration(
                    labelText: 'Memory Path', isDense: true)),
          ],
        ),
      ),
    );
  }
}
