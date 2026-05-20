import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import '../providers/preset_provider.dart';
import '../models/models.dart';
import '../theme.dart';

import 'package:flutter/services.dart';
import '../services/compiler_service.dart';
import '../providers/execution_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Compiler Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAccent,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use Default OneCompiler'),
                subtitle: const Text('Fastest, requires no configuration.'),
                value: presetState.useDefaultOneCompiler,
                activeTrackColor: AppTheme.primaryAccent, activeThumbColor: AppTheme.primaryAccent,
                onChanged: (val) {
                  ref.read(presetProvider.notifier).setUseDefaultOneCompiler(val);
                },
              ),
              const Divider(),
              const SizedBox(height: 8),
              if (!presetState.useDefaultOneCompiler) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Custom Compiler Presets',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
                      onPressed: () => _showPresetDialog(context, null),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...presetState.presets.map((preset) => _buildPresetTile(preset)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetTile(PresetModel preset) {
    final presetState = ref.watch(presetProvider);
    final isActive = preset.id == presetState.activePresetId;

    return Card(
      color: AppTheme.darkGray,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isActive ? AppTheme.primaryAccent : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: () => _showPresetDialog(context, preset),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white70),
              onPressed: () {
                final newPreset = preset.copyWith(
                  id: const Uuid().v4(),
                  name: '${preset.name} (Copy)',
                );
                ref.read(presetProvider.notifier).addPreset(newPreset);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                ref.read(presetProvider.notifier).deletePreset(preset.id);
              },
            ),
          ],
        ),
        onTap: () {
          ref.read(presetProvider.notifier).setActivePreset(preset.id);
        },
      ),
    );
  }

  void _showPresetDialog(BuildContext context, PresetModel? existingPreset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorScreen(existingPreset: existingPreset),
      ),
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final PresetModel? existingPreset;
  const PresetEditorScreen({super.key, this.existingPreset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  String _method = 'POST';
  String _authType = 'None';
  late TextEditingController _authValueCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPreset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _endpointCtrl = TextEditingController(text: p?.endpoint ?? '');
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');

    _headers = p?.headers.entries.toList() ?? [];
    _queryParams = p?.queryParams.entries.toList() ?? [];

    _bodyTemplateCtrl = TextEditingController(text: p?.bodyTemplate ?? '{}');
    _stdoutPathCtrl = TextEditingController(text: p?.responseStdoutPath ?? '');
    _stderrPathCtrl = TextEditingController(text: p?.responseStderrPath ?? '');
    _errorPathCtrl = TextEditingController(text: p?.responseErrorPath ?? '');
    _timePathCtrl = TextEditingController(text: p?.responseTimePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.responseMemoryPath ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _endpointCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _timePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }


  Future<void> _testConnection() async {
    final testPreset = PresetModel(
      id: widget.existingPreset?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpoint: _endpointCtrl.text,
      method: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      bodyTemplate: _bodyTemplateCtrl.text,
      responseStdoutPath: _stdoutPathCtrl.text,
      responseStderrPath: _stderrPathCtrl.text,
      responseErrorPath: _errorPathCtrl.text,
      responseTimePath: _timePathCtrl.text,
      responseMemoryPath: _memoryPathCtrl.text,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text("Testing...")])),
    );

    final compilerService = CompilerService();
    await compilerService.runCustomCode("print('Hello from custom API');", "", testPreset, ref);

    // ignore: use_build_context_synchronously
    if (!mounted) return;
    Navigator.pop(context); // pop loading

    final execState = ref.read(executionProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Parsed Output:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Stdout: ${execState.stdout}', style: const TextStyle(color: Colors.green)),
              Text('Stderr: ${execState.stderr}', style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      )
    );
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      final newPreset = PresetModel(
        id: widget.existingPreset?.id ?? const Uuid().v4(),
        name: _nameCtrl.text,
        endpoint: _endpointCtrl.text,
        method: _method,
        authType: _authType,
        authValue: _authValueCtrl.text,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplateCtrl.text,
        responseStdoutPath: _stdoutPathCtrl.text,
        responseStderrPath: _stderrPathCtrl.text,
        responseErrorPath: _errorPathCtrl.text,
        responseTimePath: _timePathCtrl.text,
        responseMemoryPath: _memoryPathCtrl.text,
      );

      if (widget.existingPreset == null) {
        ref.read(presetProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(presetProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPreset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          TextButton(
            onPressed: _testConnection,
            child: const Text('Test Connection'),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreset,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointCtrl,
              decoration: InputDecoration(
                labelText: 'Endpoint URL',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _endpointCtrl.text));
                    Fluttertoast.showToast(msg: "Copied URL");
                  },
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _authValueCtrl,
                decoration: const InputDecoration(labelText: 'Auth Value'),
              ),
            ],
            const Divider(height: 32),
            _buildDynamicTable('Headers', _headers),
            const Divider(height: 32),
            _buildDynamicTable('Query Params', _queryParams),
            const Divider(height: 32),
            const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '{\n  "code": "{code}",\n  "stdin": "{stdin}"\n}',
              ),
            ),
            const Divider(height: 32),
            const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(controller: _stdoutPathCtrl, decoration: const InputDecoration(labelText: 'stdout path')),
            const SizedBox(height: 8),
            TextFormField(controller: _stderrPathCtrl, decoration: const InputDecoration(labelText: 'stderr path')),
            const SizedBox(height: 8),
            TextFormField(controller: _errorPathCtrl, decoration: const InputDecoration(labelText: 'error path')),
            const SizedBox(height: 8),
            TextFormField(controller: _timePathCtrl, decoration: const InputDecoration(labelText: 'executionTime path')),
            const SizedBox(height: 8),
            TextFormField(controller: _memoryPathCtrl, decoration: const InputDecoration(labelText: 'memory path')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
              onPressed: () {
                setState(() {
                  data.add(const MapEntry('', ''));
                });
              },
            ),
          ],
        ),
        ...data.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> item = entry.value;
          return Padding(
            key: ValueKey('${title}_$idx'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.key,
                    decoration: const InputDecoration(hintText: 'Key', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                    onChanged: (v) {
                      data[idx] = MapEntry(v, item.value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.value,
                    decoration: const InputDecoration(hintText: 'Value', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                    onChanged: (v) {
                      data[idx] = MapEntry(item.key, v);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      data.removeAt(idx);
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
