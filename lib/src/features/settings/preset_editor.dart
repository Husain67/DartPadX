import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../models/compiler_preset.dart';
import '../../providers/compiler_provider.dart';
import '../../theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditor({super.key, this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late String _method;
  late String _authType;
  late TextEditingController _authValueController;
  late TextEditingController _bodyController;

  late TextEditingController _mapStdoutController;
  late TextEditingController _mapStderrController;
  late TextEditingController _mapErrorController;
  late TextEditingController _mapTimeController;
  late TextEditingController _mapMemoryController;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset ?? CompilerPreset(name: '', url: '');

    _nameController = TextEditingController(text: p.name);
    _urlController = TextEditingController(text: p.url);
    _method = p.method;
    _authType = p.authType;
    _authValueController = TextEditingController(text: p.authValue);
    _bodyController = TextEditingController(text: p.bodyTemplate);

    _mapStdoutController = TextEditingController(text: p.mappings['stdout'] ?? '');
    _mapStderrController = TextEditingController(text: p.mappings['stderr'] ?? '');
    _mapErrorController = TextEditingController(text: p.mappings['error'] ?? '');
    _mapTimeController = TextEditingController(text: p.mappings['executionTime'] ?? '');
    _mapMemoryController = TextEditingController(text: p.mappings['memory'] ?? '');

    _headers = p.headers.entries.toList();
    _queryParams = p.queryParams.entries.toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _authValueController.dispose();
    _bodyController.dispose();
    _mapStdoutController.dispose();
    _mapStderrController.dispose();
    _mapErrorController.dispose();
    _mapTimeController.dispose();
    _mapMemoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final preset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameController.text,
        url: _urlController.text,
        method: _method,
        authType: _authType,
        authValue: _authValueController.text,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyController.text,
        mappings: {
          'stdout': _mapStdoutController.text,
          'stderr': _mapStderrController.text,
          'error': _mapErrorController.text,
          'executionTime': _mapTimeController.text,
          'memory': _mapMemoryController.text,
        },
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(preset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(preset);
      }
      Navigator.pop(context);
    }
  }

  Widget _buildDynamicList(String title, List<MapEntry<String, String>> items, void Function() onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add, color: AppTheme.accentYellow), onPressed: onAdd),
          ],
        ),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          var kv = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: kv.key,
                    decoration: const InputDecoration(labelText: 'Key', isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      setState(() { items[idx] = MapEntry(val, kv.value); });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: kv.value,
                    decoration: const InputDecoration(labelText: 'Value', isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      setState(() { items[idx] = MapEntry(kv.key, val); });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () { setState(() { items.removeAt(idx); }); },
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          if (widget.preset != null)
             IconButton(
               icon: const Icon(Icons.copy),
               tooltip: 'Duplicate',
               onPressed: () {
                  final duplicate = widget.preset!.copyWith(id: const Uuid().v4(), name: '\${widget.preset!.name} (Copy)');
                  ref.read(compilerProvider.notifier).addPreset(duplicate);
                  Navigator.pop(context);
               },
             ),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Endpoint URL',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _urlController.text));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied')));
                    },
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _method,
                      decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder()),
                      items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _method = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _authType,
                      decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                      items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _authType = v!),
                    ),
                  ),
                ],
              ),
              if (_authType != 'None') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _authValueController,
                  decoration: const InputDecoration(labelText: 'Auth Value (e.g. key, token, user:pass)', border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 24),
              _buildDynamicList('Headers', _headers, () => setState(() => _headers.add(const MapEntry('', '')))),
              const Divider(),
              _buildDynamicList('Query Params', _queryParams, () => setState(() => _queryParams.add(const MapEntry('', '')))),
              const SizedBox(height: 24),
              const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Available placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(controller: _mapStdoutController, decoration: const InputDecoration(labelText: 'stdout path', isDense: true)),
              TextFormField(controller: _mapStderrController, decoration: const InputDecoration(labelText: 'stderr path', isDense: true)),
              TextFormField(controller: _mapErrorController, decoration: const InputDecoration(labelText: 'error path', isDense: true)),
              TextFormField(controller: _mapTimeController, decoration: const InputDecoration(labelText: 'executionTime path', isDense: true)),
              TextFormField(controller: _mapMemoryController, decoration: const InputDecoration(labelText: 'memory path', isDense: true)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
