import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../theme.dart';
import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../services/api_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler API'),
            value: settings.useDefaultOneCompiler,
            activeTrackColor: AppTheme.primaryYellow,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleDefaultCompiler(val);
            },
          ),
          if (!settings.useDefaultOneCompiler) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custom Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.primaryYellow),
                  onPressed: () => _editPreset(context, ref, null),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...settings.presets.map((preset) => Card(
              color: settings.activePresetId == preset.id ? AppTheme.primaryYellow.withValues(alpha: 0.2) : Colors.grey[900],
              child: ListTile(
                title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editPreset(context, ref, preset)),
                    IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () => ref.read(settingsProvider.notifier).duplicatePreset(preset)),
                    IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset.id)),
                  ],
                ),
                onTap: () => ref.read(settingsProvider.notifier).setActivePreset(preset.id),
              ),
            )),
          ]
        ],
      ),
    );
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditPresetScreen(preset: preset)));
  }
}

class EditPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const EditPresetScreen({super.key, this.preset});

  @override
  ConsumerState<EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<EditPresetScreen> {
  final _uuid = const Uuid();
  late TextEditingController _nameCtrl, _urlCtrl, _authValCtrl, _bodyCtrl;
  late TextEditingController _stdoutCtrl, _stderrCtrl, _errCtrl, _timeCtrl, _memCtrl;
  String _method = 'POST';
  String _authType = 'None';
  Map<String, String> _headers = {};
  Map<String, String> _queryParams = {};

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _urlCtrl = TextEditingController(text: p?.url ?? '');
    _authValCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyCtrl = TextEditingController(text: p?.bodyTemplate ?? '{}');
    _stdoutCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timeCtrl = TextEditingController(text: p?.timePath ?? '');
    _memCtrl = TextEditingController(text: p?.memoryPath ?? '');
    if (p != null) {
      _method = p.method;
      _authType = p.authType;
      _headers = Map.from(p.headers);
      _queryParams = Map.from(p.queryParams);
    }
  }

  void _save() {
    final newPreset = CompilerPreset(
      id: widget.preset?.id ?? _uuid.v4(),
      name: _nameCtrl.text,
      url: _urlCtrl.text,
      method: _method,
      authType: _authType,
      authValue: _authValCtrl.text,
      headers: _headers,
      queryParams: _queryParams,
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errCtrl.text,
      timePath: _timeCtrl.text,
      memoryPath: _memCtrl.text,
    );
    ref.read(settingsProvider.notifier).savePreset(newPreset);
    Navigator.pop(context);
  }

  void _testConnection() async {
    final tempPreset = CompilerPreset(
      id: '', name: '', url: _urlCtrl.text, method: _method,
      authType: _authType, authValue: _authValCtrl.text,
      headers: _headers, queryParams: _queryParams,
      bodyTemplate: _bodyCtrl.text, stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text, errorPath: _errCtrl.text,
      timePath: _timeCtrl.text, memoryPath: _memCtrl.text,
    );
    final result = await ApiService.executeCode(code: "print('Hello from custom API');", useDefault: false, preset: tempPreset);
    if (mounted) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(child: Text(jsonEncode(result))),
        actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('OK'))],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.bug_report), onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL')),
          DropdownButton<String>(
            value: _method,
            items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _method = v!),
          ),
          DropdownButton<String>(
            value: _authType,
            items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (v) => setState(() => _authType = v!),
          ),
          if (_authType != 'None')
            TextField(controller: _authValCtrl, decoration: const InputDecoration(labelText: 'Auth Value')),
          const SizedBox(height: 16),
          const Text('Body Template (JSON) - Use {code}, {language}, {stdin}', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _bodyCtrl, maxLines: 5, decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 16),
          const Text('Headers (JSON format)', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: TextEditingController(text: jsonEncode(_headers)),
            maxLines: 2,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"Content-Type": "application/json"}'),
            onChanged: (v) {
              try { _headers = Map<String, String>.from(jsonDecode(v)); } catch(_) {}
            },
          ),
          const SizedBox(height: 16),
          const Text('Query Params (JSON format)', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: TextEditingController(text: jsonEncode(_queryParams)),
            maxLines: 2,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"key": "value"}'),
            onChanged: (v) {
              try { _queryParams = Map<String, String>.from(jsonDecode(v)); } catch(_) {}
            },
          ),
          const SizedBox(height: 16),
          const Text('Response Mapping Paths (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path')),
          TextField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path')),
          TextField(controller: _errCtrl, decoration: const InputDecoration(labelText: 'error path')),
          TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'execution time path')),
          TextField(controller: _memCtrl, decoration: const InputDecoration(labelText: 'memory path')),
        ],
      ),
    );
  }
}
