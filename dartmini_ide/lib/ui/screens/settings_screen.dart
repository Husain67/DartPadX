import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/compiler_preset.dart';
import '../../data/providers/compiler_provider.dart';
import '../../data/services/api_service.dart';

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
        title: const Text('Settings & Compilers'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Fastest, requires no setup. Turn off to use Custom Presets.'),
            value: compilerState.useDefaultOneCompiler,
            activeTrackColor: AppTheme.primary,
            activeThumbColor: Colors.black,
            onChanged: (val) {
              ref.read(compilerProvider.notifier).toggleUseDefault(val);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Custom Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
          ...compilerState.presets.map((preset) {
            final isActive = preset.id == compilerState.activePresetId && !compilerState.useDefaultOneCompiler;
            return Card(
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isActive ? AppTheme.primary : Colors.transparent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(preset.name),
                subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!preset.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPreset(preset),
                      ),
                    if (!preset.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                      ),
                  ],
                ),
                onTap: () {
                  ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  if (compilerState.useDefaultOneCompiler) {
                    ref.read(compilerProvider.notifier).toggleUseDefault(false);
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Custom Preset'),
            onPressed: () => _editPreset(CompilerPreset(name: 'New Preset', endpoint: '')),
          ),
        ],
      ),
    );
  }

  void _editPreset(CompilerPreset preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _outCtrl;
  late TextEditingController _errCtrl;
  late TextEditingController _errPathCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _endpointCtrl = TextEditingController(text: widget.preset.endpoint);
    _method = widget.preset.method;
    _authType = widget.preset.authType;
    _authValueCtrl = TextEditingController(text: widget.preset.authValue);
    _bodyCtrl = TextEditingController(text: widget.preset.bodyTemplate);
    _outCtrl = TextEditingController(text: widget.preset.responseStdoutPath);
    _errCtrl = TextEditingController(text: widget.preset.responseStderrPath);
    _errPathCtrl = TextEditingController(text: widget.preset.responseErrorPath);
    _timeCtrl = TextEditingController(text: widget.preset.responseTimePath);
    _memCtrl = TextEditingController(text: widget.preset.responseMemoryPath);
    _headers = widget.preset.headers.entries.toList();
    _queryParams = widget.preset.queryParams.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow, color: AppTheme.primary), onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _endpointCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL'))),
                IconButton(icon: const Icon(Icons.copy), onPressed: () => Clipboard.setData(ClipboardData(text: _endpointCtrl.text))),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'Header', 'Bearer', 'Basic', 'Query'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextField(controller: _authValueCtrl, decoration: const InputDecoration(labelText: 'Auth Value (e.g. Header-Name: Value or Token)')),
            ],
            const SizedBox(height: 24),
            _buildDynamicTable('Headers', _headers),
            const SizedBox(height: 24),
            _buildDynamicTable('Query Params', _queryParams),
            const SizedBox(height: 24),
            const Text('Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(controller: _bodyCtrl, maxLines: 6, decoration: const InputDecoration(hintText: '{"script": "{code}"}')),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _outCtrl, decoration: const InputDecoration(labelText: 'Stdout Path (e.g. data.output)')),
            const SizedBox(height: 8),
            TextField(controller: _errCtrl, decoration: const InputDecoration(labelText: 'Stderr Path')),
            const SizedBox(height: 8),
            TextField(controller: _errPathCtrl, decoration: const InputDecoration(labelText: 'Error Path')),
            const SizedBox(height: 8),
            TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'Execution Time Path')),
            const SizedBox(height: 8),
            TextField(controller: _memCtrl, decoration: const InputDecoration(labelText: 'Memory Path')),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primary),
              onPressed: () => setState(() => list.add(const MapEntry('', ''))),
            )
          ],
        ),
        ...list.asMap().entries.map((e) {
          int idx = e.key;
          return Padding(
            key: ValueKey('${title}_$idx'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: e.value.key,
                    decoration: const InputDecoration(hintText: 'Key'),
                    onChanged: (val) => list[idx] = MapEntry(val, list[idx].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: e.value.value,
                    decoration: const InputDecoration(hintText: 'Value'),
                    onChanged: (val) => list[idx] = MapEntry(list[idx].key, val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => setState(() => list.removeAt(idx)),
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  void _save() {
    final newPreset = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpoint: _endpointCtrl.text,
      method: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      bodyTemplate: _bodyCtrl.text,
      responseStdoutPath: _outCtrl.text,
      responseStderrPath: _errCtrl.text,
      responseErrorPath: _errPathCtrl.text,
      responseTimePath: _timeCtrl.text,
      responseMemoryPath: _memCtrl.text,
      headers: Map.fromEntries(_headers.where((e) => e.key.isNotEmpty)),
      queryParams: Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty)),
    );
    ref.read(compilerProvider.notifier).savePreset(newPreset);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: 'Preset Saved');
  }

  void _testConnection() async {
    final tempPreset = widget.preset.copyWith(
      endpoint: _endpointCtrl.text,
      method: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      bodyTemplate: _bodyCtrl.text,
      headers: Map.fromEntries(_headers.where((e) => e.key.isNotEmpty)),
      responseStdoutPath: _outCtrl.text,
    );

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    final result = await ApiService.executeCode(code: "print('Hello from custom API');", stdin: "", preset: tempPreset);

    if (!mounted) return;
    Navigator.pop(context); // pop loading

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Parsed Stdout:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              Text(result.stdout.isNotEmpty ? result.stdout : 'None'),
              const Divider(),
              const Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              Text(jsonEncode(result.rawResponse)),
              if (result.error.isNotEmpty) ...[
                const Divider(),
                const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text(result.error),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
