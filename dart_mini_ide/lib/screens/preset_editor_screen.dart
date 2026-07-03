import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/theme/app_theme.dart';
import 'package:dart_mini_ide/providers/settings_provider.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/services/compiler_service.dart';

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
  late String _method;
  late String _authType;
  late TextEditingController _authKeyController;
  late TextEditingController _authValueController;
  late TextEditingController _bodyTemplateController;

  late TextEditingController _stdoutPathController;
  late TextEditingController _stderrPathController;
  late TextEditingController _errorPathController;
  late TextEditingController _timePathController;
  late TextEditingController _memoryPathController;

  Map<String, String> _headers = {};
  Map<String, String> _queryParams = {};

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _endpointController = TextEditingController(text: p?.endpoint ?? '');
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authKeyController = TextEditingController(text: p?.authKey ?? '');
    _authValueController = TextEditingController(text: p?.authValue ?? '');
    _bodyTemplateController = TextEditingController(text: p?.bodyTemplate ?? '{\n  "code": "{code}"\n}');

    _stdoutPathController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathController = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathController = TextEditingController(text: p?.errorPath ?? '');
    _timePathController = TextEditingController(text: p?.timePath ?? '');
    _memoryPathController = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _headers = Map.from(p.headers);
      _queryParams = Map.from(p.queryParams);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _authKeyController.dispose();
    _authValueController.dispose();
    _bodyTemplateController.dispose();
    _stdoutPathController.dispose();
    _stderrPathController.dispose();
    _errorPathController.dispose();
    _timePathController.dispose();
    _memoryPathController.dispose();
    super.dispose();
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      final preset = CompilerPreset(
        id: widget.preset?.id,
        name: _nameController.text,
        endpoint: _endpointController.text,
        method: _method,
        authType: _authType,
        authKey: _authKeyController.text,
        authValue: _authValueController.text,
        bodyTemplate: _bodyTemplateController.text,
        stdoutPath: _stdoutPathController.text,
        stderrPath: _stderrPathController.text,
        errorPath: _errorPathController.text,
        timePath: _timePathController.text,
        memoryPath: _memoryPathController.text,
        headers: _headers,
        queryParams: _queryParams,
      );

      if (widget.preset == null) {
        ref.read(settingsProvider.notifier).addPreset(preset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(preset);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final preset = CompilerPreset(
      name: 'Test',
      endpoint: _endpointController.text,
      method: _method,
      authType: _authType,
      authKey: _authKeyController.text,
      authValue: _authValueController.text,
      bodyTemplate: _bodyTemplateController.text,
      stdoutPath: _stdoutPathController.text,
      stderrPath: _stderrPathController.text,
      errorPath: _errorPathController.text,
      timePath: _timePathController.text,
      memoryPath: _memoryPathController.text,
      headers: _headers,
      queryParams: _queryParams,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final result = await CompilerService.executeCode("void main() { print('Hello from custom API'); }", "", preset);

    if (mounted) {
      Navigator.pop(context);
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Test Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stdout: ${result.stdout}', style: const TextStyle(color: Colors.green)),
                Text('Stderr: ${result.stderr}', style: const TextStyle(color: Colors.red)),
                Text('Error: ${result.error}', style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save), onPressed: _savePreset, tooltip: 'Save'),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Platform Name', filled: true, fillColor: Colors.black26),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _endpointController,
                decoration: const InputDecoration(labelText: 'Endpoint URL', filled: true, fillColor: Colors.black26),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _method,
                decoration: const InputDecoration(labelText: 'HTTP Method', filled: true, fillColor: Colors.black26),
                items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _method = val!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _authType,
                decoration: const InputDecoration(labelText: 'Auth Type', filled: true, fillColor: Colors.black26),
                items: ['None', 'Header', 'Bearer Token', 'Query Param'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _authType = val!),
              ),
              if (_authType == 'Header' || _authType == 'Query Param') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _authKeyController,
                  decoration: InputDecoration(labelText: 'Auth Key ($_authType name)', filled: true, fillColor: Colors.black26),
                ),
              ],
              if (_authType != 'None') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _authValueController,
                  decoration: const InputDecoration(labelText: 'Auth Value (Token/Key)', filled: true, fillColor: Colors.black26),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
              const Text('Use {code} and {stdin} as placeholders.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _bodyTemplateController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(filled: true, fillColor: Colors.black26, border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryYellow)),
              const SizedBox(height: 10),
              TextFormField(controller: _stdoutPathController, decoration: const InputDecoration(labelText: 'stdout path (e.g. data.output)', filled: true, fillColor: Colors.black26)),
              const SizedBox(height: 10),
              TextFormField(controller: _stderrPathController, decoration: const InputDecoration(labelText: 'stderr path', filled: true, fillColor: Colors.black26)),
              const SizedBox(height: 10),
              TextFormField(controller: _errorPathController, decoration: const InputDecoration(labelText: 'error path', filled: true, fillColor: Colors.black26)),
              const SizedBox(height: 10),
              TextFormField(controller: _timePathController, decoration: const InputDecoration(labelText: 'executionTime path', filled: true, fillColor: Colors.black26)),
              const SizedBox(height: 10),
              TextFormField(controller: _memoryPathController, decoration: const InputDecoration(labelText: 'memory path', filled: true, fillColor: Colors.black26)),
            ],
          ),
        ),
      ),
    );
  }
}
