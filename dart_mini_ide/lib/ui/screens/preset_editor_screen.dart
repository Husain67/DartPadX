import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/compiler_preset.dart';
import '../../providers/settings_provider.dart';
import '../../providers/execution_provider.dart';
import '../../core/theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class HeaderRow {
  final TextEditingController keyController;
  final TextEditingController valController;

  HeaderRow(String key, String val)
    : keyController = TextEditingController(text: key),
      valController = TextEditingController(text: val);
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _endpointUrl;
  late String _method;
  late String _authType;
  late String _requestBodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  final List<HeaderRow> _headerRows = [];
  final List<HeaderRow> _paramRows = [];

  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _name = p?.name ?? 'New Preset';
    _endpointUrl = p?.endpointUrl ?? 'https://';
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _requestBodyTemplate = p?.requestBodyTemplate ?? '{"code": "{code}", "language": "dart"}';
    _stdoutPath = p?.stdoutPath ?? 'stdout';
    _stderrPath = p?.stderrPath ?? 'stderr';
    _errorPath = p?.errorPath ?? 'error';
    _executionTimePath = p?.executionTimePath ?? 'executionTime';
    _memoryPath = p?.memoryPath ?? 'memory';

    (p?.headers ?? {}).forEach((k, v) {
      _headerRows.add(HeaderRow(k, v));
    });
    (p?.queryParams ?? {}).forEach((k, v) {
      _paramRows.add(HeaderRow(k, v));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'Add Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Info'),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Preset Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _name = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _endpointUrl,
                decoration: const InputDecoration(labelText: 'Endpoint URL'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _endpointUrl = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _method,
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['POST', 'GET', 'PUT']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _method = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: ['None', 'API-Key', 'Bearer', 'Basic']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _authType = v!),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Headers'),
              _buildDynamicRows(_headerRows, 'Header'),
              const SizedBox(height: 24),
              _buildSectionTitle('Query Params'),
              _buildDynamicRows(_paramRows, 'Param'),
              const SizedBox(height: 24),
              _buildSectionTitle('Request Body Template'),
              const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _requestBodyTemplate,
                maxLines: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'JSON Body Template',
                ),
                style: const TextStyle(fontFamily: 'monospace'),
                onSaved: (v) => _requestBodyTemplate = v!,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Response Mapping (JSON Paths)'),
              TextFormField(
                initialValue: _stdoutPath,
                decoration: const InputDecoration(labelText: 'stdout path (e.g. output.stdout)'),
                onSaved: (v) => _stdoutPath = v!,
              ),
              TextFormField(
                initialValue: _stderrPath,
                decoration: const InputDecoration(labelText: 'stderr path'),
                onSaved: (v) => _stderrPath = v!,
              ),
              TextFormField(
                initialValue: _errorPath,
                decoration: const InputDecoration(labelText: 'error path'),
                onSaved: (v) => _errorPath = v!,
              ),
               TextFormField(
                initialValue: _executionTimePath,
                decoration: const InputDecoration(labelText: 'execution time path'),
                onSaved: (v) => _executionTimePath = v!,
              ),
               TextFormField(
                initialValue: _memoryPath,
                decoration: const InputDecoration(labelText: 'memory path'),
                onSaved: (v) => _memoryPath = v!,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _testConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: Colors.black,
                ),
                child: _isTesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test Connection'),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  color: Colors.black,
                  child: Text(_testResult!, style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent)),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentYellow)),
    );
  }

  Widget _buildDynamicRows(List<HeaderRow> rows, String label) {
    return Column(
      children: [
        ...rows.map((row) => Row(
          children: [
             Expanded(child: TextField(controller: row.keyController, decoration: InputDecoration(labelText: '$label Key'))),
             const SizedBox(width: 8),
             Expanded(child: TextField(controller: row.valController, decoration: InputDecoration(labelText: '$label Value'))),
             IconButton(icon: const Icon(Icons.remove_circle, color: AppTheme.errorRed), onPressed: () => setState(() => rows.remove(row))),
          ],
        )),
        TextButton.icon(
          onPressed: () => setState(() => rows.add(HeaderRow('', ''))),
          icon: const Icon(Icons.add),
          label: Text('Add $label'),
        ),
      ],
    );
  }

  Map<String, String> _rowsToMap(List<HeaderRow> rows) {
    final map = <String, String>{};
    for (var row in rows) {
      if (row.keyController.text.isNotEmpty) {
        map[row.keyController.text] = row.valController.text;
      }
    }
    return map;
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: widget.preset?.id,
        name: _name,
        endpointUrl: _endpointUrl,
        method: _method,
        authType: _authType,
        headers: _rowsToMap(_headerRows),
        queryParams: _rowsToMap(_paramRows),
        requestBodyTemplate: _requestBodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );

      if (widget.preset == null) {
        ref.read(settingsProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    _formKey.currentState!.save();
    final tempPreset = CompilerPreset(
        id: 'temp',
        name: _name,
        endpointUrl: _endpointUrl,
        method: _method,
        authType: _authType,
        headers: _rowsToMap(_headerRows),
        queryParams: _rowsToMap(_paramRows),
        requestBodyTemplate: _requestBodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
    );

    final service = ref.read(executionServiceProvider);
    final result = await service.executeCustom(tempPreset, "void main() { print('Hello from Custom API'); }", "");

    setState(() {
      _isTesting = false;
      _testResult = "Success: ${result.isSuccess}\nStdout: ${result.stdout}\nStderr: ${result.stderr}\nError: ${result.error}";
    });
  }
}
