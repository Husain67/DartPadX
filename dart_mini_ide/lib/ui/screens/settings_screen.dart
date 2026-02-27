import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/compiler_preset.dart';
import '../../logic/providers/execution_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(compilerPresetsProvider);
    final selectedPreset = ref.watch(selectedPresetProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Compiler Presets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
            ),
          ),
          ...presets.map((preset) => ListTile(
                title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedPreset.id == preset.id)
                      const Icon(Icons.check_circle, color: AppTheme.primaryAccent),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PresetEditorScreen(preset: preset)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        if (presets.length <= 1) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete the last preset')));
                          return;
                        }
                        ref.read(compilerPresetsProvider.notifier).deletePreset(preset.id);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(selectedPresetProvider.notifier).state = preset;
                },
              )),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Preset'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PresetEditorScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _methodController;
  late TextEditingController _authTypeController; // Simplified as text for now
  late TextEditingController _bodyTemplateController;

  // Response Mapping
  late TextEditingController _stdoutPathController;
  late TextEditingController _stderrPathController;
  late TextEditingController _errorPathController;
  late TextEditingController _timePathController;
  late TextEditingController _memoryPathController;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? 'New Preset');
    _urlController = TextEditingController(text: p?.endpointUrl ?? 'https://api.example.com/run');
    _methodController = TextEditingController(text: p?.httpMethod ?? 'POST');
    _authTypeController = TextEditingController(text: p?.authType ?? 'None');
    _bodyTemplateController = TextEditingController(text: p?.requestBodyTemplate ?? '{"code": "{code}"}');

    _stdoutPathController = TextEditingController(text: p?.responseStdoutPath ?? 'stdout');
    _stderrPathController = TextEditingController(text: p?.responseStderrPath ?? 'stderr');
    _errorPathController = TextEditingController(text: p?.responseErrorPath ?? 'error');
    _timePathController = TextEditingController(text: p?.responseExecutionTimePath ?? 'time');
    _memoryPathController = TextEditingController(text: p?.responseMemoryPath ?? 'memory');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _methodController.dispose();
    _authTypeController.dispose();
    _bodyTemplateController.dispose();
    _stdoutPathController.dispose();
    _stderrPathController.dispose();
    _errorPathController.dispose();
    _timePathController.dispose();
    _memoryPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'Add Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreset,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_nameController, 'Preset Name'),
            _buildTextField(_urlController, 'Endpoint URL'),
            _buildTextField(_methodController, 'HTTP Method (POST/GET/PUT)'),
            _buildTextField(_authTypeController, 'Auth Type'),
            const SizedBox(height: 16),
            const Text('Request Body Template', style: TextStyle(color: AppTheme.primaryAccent)),
            const Text('Use {code}, {stdin}, {language} as placeholders', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(color: AppTheme.primaryAccent)),
            _buildTextField(_stdoutPathController, 'Stdout Path'),
            _buildTextField(_stderrPathController, 'Stderr Path'),
            _buildTextField(_errorPathController, 'Error Path'),
            _buildTextField(_timePathController, 'Execution Time Path'),
            _buildTextField(_memoryPathController, 'Memory Usage Path'),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Test Connection (mock or real run with print hello)
                // For now, just a toast
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test feature to be implemented')));
              },
              child: const Text('Test Connection')
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameController.text,
        endpointUrl: _urlController.text,
        httpMethod: _methodController.text,
        authType: _authTypeController.text,
        headers: widget.preset?.headers ?? {'content-type': 'application/json'}, // Keep existing or default
        queryParams: widget.preset?.queryParams ?? {},
        requestBodyTemplate: _bodyTemplateController.text,
        responseStdoutPath: _stdoutPathController.text,
        responseStderrPath: _stderrPathController.text,
        responseErrorPath: _errorPathController.text,
        responseExecutionTimePath: _timePathController.text,
        responseMemoryPath: _memoryPathController.text,
      );

      if (widget.preset == null) {
        ref.read(compilerPresetsProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(compilerPresetsProvider.notifier).updatePreset(newPreset);
      }

      Navigator.pop(context);
    }
  }
}
