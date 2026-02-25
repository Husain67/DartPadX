import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../../providers/settings_provider.dart';
import '../../providers/execution_provider.dart';
import '../../models/compiler_preset.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPreset = ref.watch(settingsProvider);
    final allPresets = ref.watch(allPresetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compiler Presets')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allPresets.length,
        itemBuilder: (context, index) {
          final preset = allPresets[index];
          final isSelected = preset.id == currentPreset.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected ? const BorderSide(color: AppTheme.primaryAccent, width: 2) : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppTheme.primaryAccent),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(context, ref, preset);
                      } else if (value == 'delete') {
                        if (allPresets.length > 1) {
                          ref.read(settingsProvider.notifier).deletePreset(preset.id);
                        } else {
                          Fluttertoast.showToast(msg: "Cannot delete the last preset");
                        }
                      } else if (value == 'duplicate') {
                        final newPreset = CompilerPreset(
                          id: const Uuid().v4(),
                          name: '${preset.name} (Copy)',
                          url: preset.url,
                          method: preset.method,
                          headers: Map.from(preset.headers),
                          bodyTemplate: preset.bodyTemplate,
                          queryParams: Map.from(preset.queryParams),
                          responseMapping: Map.from(preset.responseMapping),
                          authType: preset.authType,
                          authKey: preset.authKey,
                          authValue: preset.authValue,
                        );
                        ref.read(settingsProvider.notifier).addPreset(newPreset);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                      if (!preset.isDefault)
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).selectPreset(preset.id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          final newPreset = CompilerPreset(
            id: const Uuid().v4(),
            name: 'New Preset',
            url: 'https://api.example.com/run',
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            bodyTemplate: '{"code": "{code}"}',
            queryParams: {},
            responseMapping: {'stdout': 'stdout', 'stderr': 'stderr'},
          );
          _showEditDialog(context, ref, newPreset, isNew: true);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, CompilerPreset preset, {bool isNew = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresetEditorScreen(preset: preset, isNew: isNew),
      ),
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  final bool isNew;

  const PresetEditorScreen({super.key, required this.preset, required this.isNew});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _authKeyController;
  late TextEditingController _authValueController;
  late TextEditingController _bodyTemplateController;

  // Mappings
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _execTimeController;

  String _authType = 'none';
  String _method = 'POST';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _urlController = TextEditingController(text: widget.preset.url);
    _method = widget.preset.method;
    _authType = widget.preset.authType;
    _authKeyController = TextEditingController(text: widget.preset.authKey);
    _authValueController = TextEditingController(text: widget.preset.authValue);
    _bodyTemplateController = TextEditingController(text: widget.preset.bodyTemplate);

    _stdoutController = TextEditingController(text: widget.preset.responseMapping['stdout'] ?? '');
    _stderrController = TextEditingController(text: widget.preset.responseMapping['stderr'] ?? '');
    _errorController = TextEditingController(text: widget.preset.responseMapping['error'] ?? '');
    _execTimeController = TextEditingController(text: widget.preset.responseMapping['executionTime'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _authKeyController.dispose();
    _authValueController.dispose();
    _bodyTemplateController.dispose();
    _stdoutController.dispose();
    _stderrController.dispose();
    _errorController.dispose();
    _execTimeController.dispose();
    super.dispose();
  }

  void _save() {
    final newPreset = CompilerPreset(
      id: widget.preset.id,
      name: _nameController.text,
      url: _urlController.text,
      method: _method,
      headers: widget.preset.headers, // TODO: Add headers editor
      bodyTemplate: _bodyTemplateController.text,
      queryParams: widget.preset.queryParams, // TODO: Add query params editor
      responseMapping: {
        'stdout': _stdoutController.text,
        'stderr': _stderrController.text,
        'error': _errorController.text,
        'executionTime': _execTimeController.text,
      },
      authType: _authType,
      authKey: _authKeyController.text,
      authValue: _authValueController.text,
      isDefault: widget.preset.isDefault,
    );

    if (widget.isNew) {
      ref.read(settingsProvider.notifier).addPreset(newPreset);
    } else {
      ref.read(settingsProvider.notifier).updatePreset(newPreset);
    }
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    final tempPreset = CompilerPreset(
      id: 'test',
      name: 'Test',
      url: _urlController.text,
      method: _method,
      headers: widget.preset.headers,
      bodyTemplate: _bodyTemplateController.text,
      queryParams: widget.preset.queryParams,
      responseMapping: {
        'stdout': _stdoutController.text,
        'stderr': _stderrController.text,
        'error': _errorController.text,
        'executionTime': _execTimeController.text,
      },
      authType: _authType,
      authKey: _authKeyController.text,
      authValue: _authValueController.text,
    );

    final service = ref.read(compilerServiceProvider);
    try {
      final result = await service.executeCode(
        tempPreset,
        "print('Hello from Test');",
        stdin: '',
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stdout: ${result['stdout']}'),
                Text('Stderr: ${result['stderr']}'),
                Text('Error: ${result['error']}'),
                Text('Time: ${result['executionTime']}ms'),
              ],
            ),
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Test Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow, color: Colors.green), onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General'),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'Endpoint URL')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),

            _buildSectionHeader('Authentication'),
            DropdownButtonFormField<String>(
              value: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['none', 'header', 'bearer', 'basic'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            if (_authType != 'none') ...[
              const SizedBox(height: 12),
              if (_authType != 'bearer')
                TextField(controller: _authKeyController, decoration: const InputDecoration(labelText: 'Key / Username')),
              const SizedBox(height: 12),
              TextField(controller: _authValueController, decoration: const InputDecoration(labelText: 'Value / Token / Password')),
            ],

            _buildSectionHeader('Request Body Template'),
            const Text('Use {code}, {stdin}, {language} as placeholders.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyTemplateController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),

            _buildSectionHeader('Response Mapping (JSON Path)'),
            TextField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'stdout path (e.g. output.stdout)')),
            const SizedBox(height: 8),
            TextField(controller: _stderrController, decoration: const InputDecoration(labelText: 'stderr path')),
            const SizedBox(height: 8),
            TextField(controller: _errorController, decoration: const InputDecoration(labelText: 'error path')),
            const SizedBox(height: 8),
            TextField(controller: _execTimeController, decoration: const InputDecoration(labelText: 'executionTime path')),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                child: const Text('Save Preset'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
