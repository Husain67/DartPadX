import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../../models/compiler_preset.dart';
import '../../providers/settings_provider.dart';
import '../../services/compiler_service.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _method;
  late AuthType _authType;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _method = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    _stdoutPathCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrPathCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorPathCtrl = TextEditingController(text: widget.preset.errorPath);
    _timePathCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memoryPathCtrl = TextEditingController(text: widget.preset.memoryPath);
    _headers = widget.preset.headers.entries.toList();
    _queryParams = widget.preset.queryParams.entries.toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _timePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  CompilerPreset _getCurrentPresetState() {
     return widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
    );
  }

  void _savePreset() {
    ref.read(settingsProvider.notifier).updatePreset(_getCurrentPresetState());
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    final tempPreset = _getCurrentPresetState();
    final result = await CompilerService.executeCode("void main() { print('Hello from custom API'); }", false, tempPreset);

    setState(() => _isTesting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Test Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Parsed Output:', style: TextStyle(color: AppTheme.accentYellow)),
                Text(result.stdout.isNotEmpty ? result.stdout : result.stderr, style: const TextStyle(fontFamily: 'monospace')),
                const SizedBox(height: 16),
                const Text('Execution Time:', style: TextStyle(color: AppTheme.accentYellow)),
                Text(result.executionTime),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Compiler Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreset,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Form(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Basic Settings'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Platform Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(labelText: 'Endpoint URL'),
                maxLines: null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _method = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AuthType>(
                value: _authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: AuthType.values.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                onChanged: (v) => setState(() => _authType = v!),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Headers'),
              _buildKeyValueEditor(_headers),
              const SizedBox(height: 24),
              _buildSectionTitle('Query Params'),
              _buildKeyValueEditor(_queryParams),
              const SizedBox(height: 24),
              _buildSectionTitle('Request Body Template (JSON)'),
              const Text('Use placeholders: {code}, {language}, {stdin}', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. {"script": "{code}", "language": "dart"}',
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Response Mapping (Dot Notation)'),
              TextFormField(controller: _stdoutPathCtrl, decoration: const InputDecoration(labelText: 'stdout path')),
              TextFormField(controller: _stderrPathCtrl, decoration: const InputDecoration(labelText: 'stderr path')),
              TextFormField(controller: _errorPathCtrl, decoration: const InputDecoration(labelText: 'error path')),
              TextFormField(controller: _timePathCtrl, decoration: const InputDecoration(labelText: 'executionTime path')),
              TextFormField(controller: _memoryPathCtrl, decoration: const InputDecoration(labelText: 'memory path')),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Icon(Icons.bug_report, color: Colors.black),
                label: const Text('Test Connection', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(color: AppTheme.accentYellow, fontWeight: bold, fontSize: 16),
      ),
    );
  }

  Widget _buildKeyValueEditor(List<MapEntry<String, String>> list) {
    return Column(
      children: [
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.key,
                  decoration: const InputDecoration(hintText: 'Key'),
                  onChanged: (v) => list[idx] = MapEntry(v, item.value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: item.value,
                  decoration: const InputDecoration(hintText: 'Value'),
                  onChanged: (v) => list[idx] = MapEntry(item.key, v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                onPressed: () => setState(() => list.removeAt(idx)),
              )
            ],
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Row'),
          onPressed: () => setState(() => list.add(const MapEntry('', ''))),
        ),
      ],
    );
  }
}

const bold = FontWeight.bold;
