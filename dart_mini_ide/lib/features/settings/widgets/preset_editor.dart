import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/core/models/compiler_preset.dart';
import 'package:dart_mini_ide/features/settings/providers/settings_provider.dart';
import 'package:dart_mini_ide/features/execution/providers/execution_provider.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  final bool isNew;

  const PresetEditorScreen({super.key, required this.preset, this.isNew = false});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _bodyController;
  late String _method;
  late String _authType;

  late Map<String, String> _headers;
  late Map<String, String> _mappings;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _urlController = TextEditingController(text: widget.preset.url);
    _bodyController = TextEditingController(text: widget.preset.requestBodyTemplate);
    _method = widget.preset.method;
    _authType = widget.preset.authType;
    _headers = Map.from(widget.preset.headers);
    _mappings = Map.from(widget.preset.responseMapping);
  }

  void _save() {
    final newPreset = widget.preset.copyWith(
      name: _nameController.text,
      url: _urlController.text,
      method: _method,
      authType: _authType,
      headers: _headers,
      requestBodyTemplate: _bodyController.text,
      responseMapping: _mappings,
    );

    if (widget.isNew) {
      ref.read(settingsProvider.notifier).addPreset(newPreset);
    } else {
      ref.read(settingsProvider.notifier).updatePreset(newPreset);
    }
    Navigator.pop(context);
  }

  void _testConnection() {
    final tempPreset = widget.preset.copyWith(
      name: _nameController.text,
      url: _urlController.text,
      method: _method,
      authType: _authType,
      headers: _headers,
      requestBodyTemplate: _bodyController.text,
      responseMapping: _mappings,
    );

    ref.read(executionProvider.notifier).runCode(
      "void main() { print('Hello from custom API'); }",
      preset: tempPreset
    );

    showDialog(
      context: context,
      builder: (c) => const TestResultDialog(),
    );
  }

  void _showEditDialog(BuildContext context, String key, String value, Function(String, String) onSave) {
    final kCtrl = TextEditingController(text: key);
    final vCtrl = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: kCtrl, decoration: const InputDecoration(labelText: 'Key')),
            TextField(controller: vCtrl, decoration: const InputDecoration(labelText: 'Value')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (kCtrl.text.isNotEmpty) {
                onSave(kCtrl.text, vCtrl.text);
                Navigator.pop(c);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapList(Map<String, String> map, Function(String) onDelete, Function(String, String, String) onEdit) {
    if (map.isEmpty) return const Text('No entries', style: TextStyle(color: Colors.grey));

    return Column(
      children: map.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.white10,
          child: ListTile(
            dense: true,
            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
              onPressed: () => onDelete(entry.key),
            ),
            onTap: () => _showEditDialog(context, entry.key, entry.value, (newK, newV) {
              onEdit(entry.key, newK, newV);
            }),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: AppColors.accent),
            tooltip: 'Test Connection',
            onPressed: _testConnection,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _method,
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
              decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType,
              items: ['None', 'Bearer', 'API-Key'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
              decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.accent),
                  onPressed: () => _showEditDialog(context, '', '', (k, v) {
                     setState(() => _headers[k] = v);
                  }),
                ),
              ],
            ),
            _buildMapList(_headers, (k) => setState(() => _headers.remove(k)), (oldK, newK, newV) {
              setState(() {
                _headers.remove(oldK);
                _headers[newK] = newV;
              });
            }),
            const SizedBox(height: 24),
            const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Use {code}, {language} as placeholders.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 8,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Response Mapping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                 IconButton(
                  icon: const Icon(Icons.add, color: AppColors.accent),
                  onPressed: () => _showEditDialog(context, '', '', (k, v) {
                     setState(() => _mappings[k] = v);
                  }),
                ),
              ],
            ),
            const Text('Map keys: stdout, stderr, executionTime to JSON paths (e.g. output.stdout)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            _buildMapList(_mappings, (k) => setState(() => _mappings.remove(k)), (oldK, newK, newV) {
               setState(() {
                _mappings.remove(oldK);
                _mappings[newK] = newV;
              });
            }),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class TestResultDialog extends ConsumerWidget {
  const TestResultDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionState = ref.watch(executionProvider);

    return AlertDialog(
      title: const Text('Test Result'),
      content: SizedBox(
        width: double.maxFinite,
        child: executionState.isLoading
           ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
           : SingleChildScrollView(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   if (executionState.error != null)
                     Text('Error:\n${executionState.error}', style: const TextStyle(color: Colors.red)),
                   if (executionState.stdout != null)
                     Text('Stdout:\n${executionState.stdout}', style: const TextStyle(color: Colors.green)),
                   if (executionState.stderr != null)
                     Text('Stderr:\n${executionState.stderr}', style: const TextStyle(color: Colors.orange)),
                   if (executionState.executionTime != null)
                     Text('Time: ${executionState.executionTime}ms'),
                   if (!executionState.isLoading && executionState.stdout == null && executionState.error == null)
                      const Text('No response data parsed. Check mappings.'),
                 ],
               ),
             ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
