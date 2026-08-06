import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../services/execution_service.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Settings / Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Import Presets JSON',
            onPressed: () => _importPresets(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Export Presets JSON',
            onPressed: () => _exportPresets(context, ref),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: settingsState.presets.length,
        itemBuilder: (context, index) {
          final preset = settingsState.presets[index];
          final isActive = preset.id == settingsState.activePresetId;

          return Card(
            color: Colors.white10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActive ? AppTheme.primaryAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: ListTile(
              title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!preset.isDefault)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () => _editPreset(context, ref, preset),
                    ),
                  if (isActive)
                    const Icon(Icons.check_circle, color: AppTheme.primaryAccent)
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                      onPressed: () => ref.read(settingsProvider.notifier).setActivePreset(preset.id),
                      child: const Text('Set Active', style: TextStyle(color: Colors.black)),
                    ),
                ],
              ),
              onTap: () => _editPreset(context, ref, preset),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryAccent,
        onPressed: () => _createPreset(context, ref),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void _createPreset(BuildContext context, WidgetRef ref) {
    final newPreset = CompilerPreset(
      id: const Uuid().v4(),
      name: 'New Custom API',
      endpointUrl: 'https://api.yourservice.com/execute',
      httpMethod: 'POST',
      authType: 'None',
      authValue: '',
      headers: {'content-type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{\n  "code": "{code}"\n}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'error',
      timePath: 'time',
      memoryPath: 'memory',
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: newPreset, isNew: true)),
    );
  }

  void _exportPresets(BuildContext context, WidgetRef ref) {
    final jsonStr = ref.read(settingsProvider.notifier).exportPresetsJson();
    Clipboard.setData(ClipboardData(text: jsonStr));
    Fluttertoast.showToast(msg: "Presets exported to clipboard");
  }

  void _importPresets(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      await ref.read(settingsProvider.notifier).importPresetsJson(data.text!);
    } else {
      Fluttertoast.showToast(msg: "Clipboard is empty");
    }
  }

  void _duplicatePreset(BuildContext context, WidgetRef ref, CompilerPreset preset) {
    final duplicated = preset.copyWith(
      id: const Uuid().v4(),
      name: "${preset.name} (Copy)",
      isDefault: false,
    );
    ref.read(settingsProvider.notifier).savePreset(duplicated);
    Fluttertoast.showToast(msg: "Preset duplicated");
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset preset) {
    if (preset.isDefault) {
      _duplicatePreset(context, ref, preset);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset, isNew: false)),
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
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;

  String _method = 'POST';
  String _authType = 'None';
  final List<String> _methods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _authValueCtrl = TextEditingController(text: widget.preset.authValue);
    _bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    _stdoutPathCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrPathCtrl = TextEditingController(text: widget.preset.stderrPath);
    _method = widget.preset.httpMethod;
    _authType = widget.preset.authType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
    );
    ref.read(settingsProvider.notifier).savePreset(updated);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset saved");
  }

  Future<void> _testConnection() async {
    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
    );

    final result = await ExecutionService.execute(code: "print('Test Connection');", preset: updated);

    if (!mounted) return;
    Navigator.pop(context); // close loading
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Text(const JsonEncoder.withIndent('  ').convert(result)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save), onPressed: _save, tooltip: 'Save'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL')),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                  Fluttertoast.showToast(msg: "URL copied");
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _method,
            items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _method = v!),
            decoration: const InputDecoration(labelText: 'HTTP Method'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _authType,
            items: _authTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
            onChanged: (v) => setState(() => _authType = v!),
            decoration: const InputDecoration(labelText: 'Auth Type'),
          ),
          const SizedBox(height: 16),
          if (_authType != 'None')
            TextField(controller: _authValueCtrl, decoration: const InputDecoration(labelText: 'Auth Token/Key Value')),
          const SizedBox(height: 16),
          const Text('Request Body Template (JSON) - Use {code}, {stdin}'),
          TextField(
            controller: _bodyCtrl,
            maxLines: 6,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(controller: _stdoutPathCtrl, decoration: const InputDecoration(labelText: 'Stdout Mapping Path (e.g. data.output)')),
          const SizedBox(height: 16),
          TextField(controller: _stderrPathCtrl, decoration: const InputDecoration(labelText: 'Stderr Mapping Path')),
          const SizedBox(height: 32),
          if (!widget.isNew)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(settingsProvider.notifier).deletePreset(widget.preset.id);
                Navigator.pop(context);
              },
              child: const Text('Delete Preset', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
