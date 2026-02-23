import 'package:dart_mini_ide/core/constants.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

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
  late TextEditingController _execTimePathController;
  late TextEditingController _memoryPathController;

  final Map<TextEditingController, TextEditingController> _headers = {};
  final Map<TextEditingController, TextEditingController> _queryParams = {};

  String _method = 'POST';
  String _authType = 'None';

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _endpointController = TextEditingController(text: p?.endpoint ?? '');
    _bodyTemplateController = TextEditingController(text: p?.requestBodyTemplate ?? '{}');

    _stdoutPathController = TextEditingController(text: p?.stdoutPath ?? 'stdout');
    _stderrPathController = TextEditingController(text: p?.stderrPath ?? 'stderr');
    _errorPathController = TextEditingController(text: p?.errorPath ?? 'error');
    _execTimePathController = TextEditingController(text: p?.executionTimePath ?? 'executionTime');
    _memoryPathController = TextEditingController(text: p?.memoryPath ?? 'memory');

    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';

    if (p != null) {
      p.headers.forEach((k, v) {
        _headers[TextEditingController(text: k)] = TextEditingController(text: v);
      });
      p.queryParams.forEach((k, v) {
        _queryParams[TextEditingController(text: k)] = TextEditingController(text: v);
      });
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
    _execTimePathController.dispose();
    _memoryPathController.dispose();

    _headers.forEach((k, v) { k.dispose(); v.dispose(); });
    _queryParams.forEach((k, v) { k.dispose(); v.dispose(); });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_nameController, 'Platform Name'),
            const SizedBox(height: 16),
            _buildTextField(_endpointController, 'Endpoint URL'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _method,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _method = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _authType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDynamicTable('Headers', _headers),
            const SizedBox(height: 24),
            _buildDynamicTable('Query Params', _queryParams),
            const SizedBox(height: 24),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'Use {code}, {language}, {stdin} placeholders',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
            const SizedBox(height: 8),
            _buildTextField(_stdoutPathController, 'stdout Path'),
            const SizedBox(height: 8),
            _buildTextField(_stderrPathController, 'stderr Path'),
            const SizedBox(height: 8),
            _buildTextField(_errorPathController, 'error Path'),
            const SizedBox(height: 8),
            _buildTextField(_execTimePathController, 'executionTime Path'),
            const SizedBox(height: 8),
            _buildTextField(_memoryPathController, 'memory Path'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testConnection, // Implement test connection
              child: const Text('Test Connection (Check Console)'), // Simple for now
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
    );
  }

  Widget _buildDynamicTable(String title, Map<TextEditingController, TextEditingController> map) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.accent),
              onPressed: () => setState(() {
                map[TextEditingController()] = TextEditingController();
              }),
            ),
          ],
        ),
        if (map.isEmpty) const Text('No entries', style: TextStyle(color: Colors.grey)),
        ...map.entries.map((entry) {
          return Row(
            children: [
              Expanded(child: TextFormField(controller: entry.key, decoration: const InputDecoration(hintText: 'Key'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: entry.value, decoration: const InputDecoration(hintText: 'Value'))),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => setState(() {
                  entry.key.dispose();
                  entry.value.dispose();
                  map.remove(entry.key);
                }),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final headers = <String, String>{};
      _headers.forEach((k, v) => headers[k.text] = v.text);

      final queryParams = <String, String>{};
      _queryParams.forEach((k, v) => queryParams[k.text] = v.text);

      final newPreset = CompilerPreset(
        id: widget.preset?.id, // Keep ID if editing
        name: _nameController.text,
        endpoint: _endpointController.text,
        method: _method,
        authType: _authType,
        headers: headers,
        queryParams: queryParams,
        requestBodyTemplate: _bodyTemplateController.text,
        stdoutPath: _stdoutPathController.text,
        stderrPath: _stderrPathController.text,
        errorPath: _errorPathController.text,
        executionTimePath: _execTimePathController.text,
        memoryPath: _memoryPathController.text,
      );

      if (widget.preset == null) {
        ref.read(settingsProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(newPreset);
      }

      Navigator.pop(context);
    }
  }

  void _testConnection() {
      // TODO: Implement actual test
      // For now show dialog saying "Save and use Run button to test"
      showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text("Test Connection"),
          content: const Text("Please save the preset and try running a file using 'Run' button with 'Use Custom Preset' enabled."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ));
  }
}
