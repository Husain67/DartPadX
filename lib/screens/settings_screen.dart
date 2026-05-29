import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset_model.dart';
import '../providers/compiler_provider.dart';
import '../utils/app_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Settings'),
      ),
      body: Row(
        children: [
          // Sidebar presets list
          SizedBox(
            width: 200,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use Default OneCompiler', style: TextStyle(fontSize: 12)),
                  value: compilerState.useDefaultOneCompiler,
                  onChanged: (val) {
                    ref.read(compilerProvider.notifier).setUseDefaultOneCompiler(val);
                  },
                  activeTrackColor: AppTheme.primaryAccent,
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: compilerState.presets.length,
                    itemBuilder: (context, index) {
                      final preset = compilerState.presets[index];
                      final isActive = preset.id == compilerState.activePresetId;
                      return ListTile(
                        title: Text(preset.name),
                        selected: isActive,
                        selectedTileColor: AppTheme.primaryAccent.withValues(alpha: 0.2),
                        onTap: () {
                          ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final newPreset = CompilerPresetModel(
                        name: 'New Preset',
                        endpointUrl: '',
                      );
                      ref.read(compilerProvider.notifier).addPreset(newPreset);
                      ref.read(compilerProvider.notifier).setActivePreset(newPreset.id);
                    },
                    child: const Text('Add Preset'),
                  ),
                )
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Editor
          Expanded(
            child: compilerState.activePresetId == null
                ? const Center(child: Text('Select a preset to edit'))
                : PresetEditor(preset: compilerState.presets.firstWhere((p) => p.id == compilerState.activePresetId!)),
          ),
        ],
      ),
    );
  }
}

class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPresetModel preset;
  const PresetEditor({super.key, required this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  List<Map<String, String>> _headers = [];
  List<Map<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(PresetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset.id != widget.preset.id) {
      _initControllers();
    }
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _method = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _authValueCtrl = TextEditingController(text: widget.preset.authValue ?? '');
    _bodyCtrl = TextEditingController(text: widget.preset.bodyTemplate);
    _stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorCtrl = TextEditingController(text: widget.preset.errorPath);
    _timeCtrl = TextEditingController(text: widget.preset.timePath);
    _memoryCtrl = TextEditingController(text: widget.preset.memoryPath);

    _headers = List<Map<String, String>>.from(widget.preset.headers.map((m) => Map<String, String>.from(m)));
    _queryParams = List<Map<String, String>>.from(widget.preset.queryParams.map((m) => Map<String, String>.from(m)));
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text.isEmpty ? null : _authValueCtrl.text,
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      timePath: _timeCtrl.text,
      memoryPath: _memoryCtrl.text,
      headers: _headers,
      queryParams: _queryParams,
    );
    ref.read(compilerProvider.notifier).updatePreset(updated);
    Fluttertoast.showToast(msg: 'Saved');
  }

  Future<void> _testConnection() async {
    _save(); // ensure saved
    Fluttertoast.showToast(msg: 'Testing connection...');

    // Quick test runner logic
    final p = widget.preset;
    try {
      final res = await http.post(
        Uri.parse(p.endpointUrl),
        headers: {for (var h in p.headers) if (h['key'] != null && h['value'] != null) h['key']!: h['value']!},
        body: p.bodyTemplate.replaceAll('{code}', '"print(\'Test\');"').replaceAll('{stdin}', '""').replaceAll('{language}', '"dart"'),
      );
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text('Status ${res.statusCode}'),
        content: SingleChildScrollView(child: Text(res.body)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ));
    } catch (e) {
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(e.toString()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Edit Preset', style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  ElevatedButton(onPressed: _testConnection, child: const Text('Test')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _save, child: const Text('Save')),
                  const SizedBox(width: 8),
                  if (!widget.preset.isBuiltIn)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref.read(compilerProvider.notifier).deletePreset(widget.preset.id);
                      },
                    )
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Preset Name', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _method,
            items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _method = val!),
            decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _authType,
            items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _authType = val!),
            decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
          ),
          if (_authType != 'None') ...[
            const SizedBox(height: 16),
            TextField(controller: _authValueCtrl, decoration: const InputDecoration(labelText: 'Auth Value / Key', border: OutlineInputBorder())),
          ],
          const SizedBox(height: 16),
          const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._headers.asMap().entries.map((entry) {
            int idx = entry.key;
            var h = entry.value;
            return Row(
              key: ValueKey('header_${widget.preset.id}_$idx'),
              children: [
                Expanded(child: TextFormField(initialValue: h['key'], onChanged: (v) => _headers[idx]['key'] = v, decoration: const InputDecoration(hintText: 'Key'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(initialValue: h['value'], onChanged: (v) => _headers[idx]['value'] = v, decoration: const InputDecoration(hintText: 'Value'))),
                IconButton(icon: const Icon(Icons.remove_circle), onPressed: () => setState(() => _headers.removeAt(idx))),
              ],
            );
          }),
          TextButton(onPressed: () => setState(() => _headers.add({'key': '', 'value': ''})), child: const Text('Add Header')),
          const SizedBox(height: 16),
          const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._queryParams.asMap().entries.map((entry) {
            int idx = entry.key;
            var q = entry.value;
            return Row(
              key: ValueKey('query_${widget.preset.id}_$idx'),
              children: [
                Expanded(child: TextFormField(initialValue: q['key'], onChanged: (v) => _queryParams[idx]['key'] = v, decoration: const InputDecoration(hintText: 'Key'))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(initialValue: q['value'], onChanged: (v) => _queryParams[idx]['value'] = v, decoration: const InputDecoration(hintText: 'Value'))),
                IconButton(icon: const Icon(Icons.remove_circle), onPressed: () => setState(() => _queryParams.removeAt(idx))),
              ],
            );
          }),
          TextButton(onPressed: () => setState(() => _queryParams.add({'key': '', 'value': ''})), child: const Text('Add Query Param')),
          const SizedBox(height: 16),
          const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          TextField(controller: _bodyCtrl, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _errorCtrl, decoration: const InputDecoration(labelText: 'error path', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'time path', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _memoryCtrl, decoration: const InputDecoration(labelText: 'memory path', border: OutlineInputBorder())),
          const SizedBox(height: 100), // Padding for scroll
        ],
      );
    });
  }
}
