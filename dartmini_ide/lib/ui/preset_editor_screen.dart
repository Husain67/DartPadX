import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../services/execution_service.dart';
import '../core/theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset; // Null for new preset

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _endpointController;
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

  final List<String> _methods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _endpointController = TextEditingController(text: p?.endpointUrl ?? '');
    _bodyTemplateController = TextEditingController(text: p?.requestBodyTemplate ?? '{}');
    _stdoutPathController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathController = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathController = TextEditingController(text: p?.errorPath ?? '');
    _timePathController = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathController = TextEditingController(text: p?.memoryPath ?? '');

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
    _endpointController.dispose();
    _bodyTemplateController.dispose();
    _stdoutPathController.dispose();
    _stderrPathController.dispose();
    _errorPathController.dispose();
    _timePathController.dispose();
    _memoryPathController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final preset = CompilerPreset(
        id: widget.preset?.id,
        name: _nameController.text.trim(),
        endpointUrl: _endpointController.text.trim(),
        httpMethod: _httpMethod,
        authType: _authType,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _bodyTemplateController.text,
        stdoutPath: _stdoutPathController.text.trim(),
        stderrPath: _stderrPathController.text.trim(),
        errorPath: _errorPathController.text.trim(),
        executionTimePath: _timePathController.text.trim(),
        memoryPath: _memoryPathController.text.trim(),
        isBuiltIn: widget.preset?.isBuiltIn ?? false,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(preset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(preset);
      }

      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Preset Saved');
    }
  }

  Future<void> _testConnection() async {
    final tempPreset = CompilerPreset(
        name: 'Test',
        endpointUrl: _endpointController.text.trim(),
        httpMethod: _httpMethod,
        authType: _authType,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _bodyTemplateController.text,
        stdoutPath: _stdoutPathController.text.trim(),
        stderrPath: _stderrPathController.text.trim(),
        errorPath: _errorPathController.text.trim(),
        executionTimePath: _timePathController.text.trim(),
        memoryPath: _memoryPathController.text.trim(),
    );

    Fluttertoast.showToast(msg: 'Testing connection...');

    const code = "void main() { print('Hello from custom API'); }";
    final result = await ExecutionService.executeCode(
      code: code,
      stdin: '',
      preset: tempPreset,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Test Result', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Output:', style: TextStyle(color: Colors.greenAccent)),
              Text(result.output, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
              const SizedBox(height: 8),
              const Text('Error/Exception:', style: TextStyle(color: Colors.redAccent)),
              Text(result.error, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> items, void Function(List<MapEntry<String, String>>) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('new_key', 'value'));
                  onUpdate(items);
                });
              },
            )
          ],
        ),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> kv = entry.value;
          return Padding(
            key: ValueKey('\$title-\$idx-\${kv.key}'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: kv.key,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Key', isDense: true),
                    onChanged: (val) {
                      items[idx] = MapEntry(val, kv.value);
                      onUpdate(items);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: kv.value,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Value', isDense: true),
                    onChanged: (val) {
                      items[idx] = MapEntry(kv.key, val);
                      onUpdate(items);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      items.removeAt(idx);
                      onUpdate(items);
                    });
                  },
                )
              ],
            ),
          );
        }),
        const Divider(color: Colors.grey),
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
            icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryAccent),
            onPressed: _testConnection,
            tooltip: 'Test Connection',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      backgroundColor: AppTheme.backgroundStart,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Platform Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _httpMethod,
                    dropdownColor: AppTheme.surfaceColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _httpMethod = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _authType,
                    dropdownColor: AppTheme.surfaceColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    items: _authTypes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDynamicTable('Headers', _headers, (updated) => _headers = updated),
            _buildDynamicTable('Query Params', _queryParams, (updated) => _queryParams = updated),
            const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Use {code}, {stdin}, {language} placeholders.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(hintText: '{"code": "{code}"}'),
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stdoutPathController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'stdout path (e.g. run.stdout)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stderrPathController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'stderr path'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _errorPathController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'error path (exception messages)'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _timePathController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'executionTime path'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoryPathController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'memory path'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
