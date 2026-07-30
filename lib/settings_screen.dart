import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: const DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                indicatorColor: AppTheme.primaryAccent,
                labelColor: AppTheme.primaryAccent,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'General'),
                  Tab(text: 'Compiler Presets'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    GeneralSettingsTab(),
                    CompilerPresetsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GeneralSettingsTab extends ConsumerWidget {
  const GeneralSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Toggle between built-in API and custom preset.'),
          value: settings.useOneCompiler,
          activeColor: AppTheme.primaryAccent,
          onChanged: (val) => ref.read(settingsProvider.notifier).setUseOneCompiler(val),
        ),
      ],
    );
  }
}

class CompilerPresetsTab extends ConsumerWidget {
  const CompilerPresetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeId = settings.activePresetId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom APIs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.file_upload, size: 20, color: Colors.white),
                    tooltip: 'Export',
                    onPressed: () {
                      final jsonStr = ref.read(settingsProvider.notifier).exportPresets();
                      Clipboard.setData(ClipboardData(text: jsonStr));
                      Fluttertoast.showToast(msg: 'Exported JSON to Clipboard');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_download, size: 20, color: Colors.white),
                    tooltip: 'Import',
                    onPressed: () => _importPresets(context, ref),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    onPressed: () => _editPreset(context, ref, null),
                  ),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: settings.presets.length,
            itemBuilder: (context, index) {
              final preset = settings.presets[index];
              final isActive = preset.id == activeId && !settings.useOneCompiler;
              return ListTile(
                title: Text(preset.name, style: TextStyle(color: isActive ? AppTheme.primaryAccent : Colors.white)),
                subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (preset.id == activeId)
                      const Icon(Icons.check_circle, color: AppTheme.primaryAccent, size: 20),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.grey),
                      tooltip: 'Duplicate',
                      onPressed: () => ref.read(settingsProvider.notifier).duplicatePreset(preset),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey),
                      onPressed: () => _editPreset(context, ref, preset),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        if (settings.presets.length > 1) {
                           ref.read(settingsProvider.notifier).deletePreset(preset.id);
                        } else {
                           Fluttertoast.showToast(msg: 'Cannot delete last preset');
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {
                   ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                   ref.read(settingsProvider.notifier).setUseOneCompiler(false);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorScreen(preset: preset),
      ),
    );
  }

  void _importPresets(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data.text!);
        final presets = jsonList.map((e) => CompilerPreset.fromJson(e)).toList();
        ref.read(settingsProvider.notifier).importPresets(presets);
        Fluttertoast.showToast(msg: 'Imported \${presets.length} presets');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Invalid JSON clipboard data');
      }
    }
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutMapCtrl;
  late TextEditingController _stderrMapCtrl;
  late TextEditingController _timeMapCtrl;

  String _method = 'POST';
  String _authType = 'None';

  // Dynamic headers and params
  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? 'New Preset');
    _urlCtrl = TextEditingController(text: p?.endpoint ?? '');
    _bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{\n  "code": "{code}",\n  "language": "{language}"\n}');
    _stdoutMapCtrl = TextEditingController(text: p?.responseMapping['stdout'] ?? 'stdout');
    _stderrMapCtrl = TextEditingController(text: p?.responseMapping['stderr'] ?? 'stderr');
    _timeMapCtrl = TextEditingController(text: p?.responseMapping['time'] ?? 'time');

    if (p != null) {
      _method = p.method;
      _authType = p.authType;
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutMapCtrl.dispose();
    _stderrMapCtrl.dispose();
    _timeMapCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final Map<String, String> headerMap = {};
    for (var e in _headers) { if (e.key.isNotEmpty) headerMap[e.key] = e.value; }

    final Map<String, String> queryMap = {};
    for (var e in _queryParams) { if (e.key.isNotEmpty) queryMap[e.key] = e.value; }

    final p = CompilerPreset(
      id: widget.preset?.id,
      name: _nameCtrl.text,
      endpoint: _urlCtrl.text,
      method: _method,
      authType: _authType,
      headers: headerMap,
      queryParams: queryMap,
      requestBodyTemplate: _bodyCtrl.text,
      responseMapping: {
        'stdout': _stdoutMapCtrl.text,
        'stderr': _stderrMapCtrl.text,
        'time': _timeMapCtrl.text,
      },
    );

    if (widget.preset == null) {
      ref.read(settingsProvider.notifier).addPreset(p);
    } else {
      ref.read(settingsProvider.notifier).updatePreset(p);
    }
    Navigator.pop(context);
  }

  void _testConnection() async {
    final Map<String, String> headerMap = {};
    for (var e in _headers) { if (e.key.isNotEmpty) headerMap[e.key] = e.value; }

    final Map<String, String> queryMap = {};
    for (var e in _queryParams) { if (e.key.isNotEmpty) queryMap[e.key] = e.value; }

    final testPreset = CompilerPreset(
      name: 'Test',
      endpoint: _urlCtrl.text,
      method: _method,
      authType: _authType,
      headers: headerMap,
      queryParams: queryMap,
      requestBodyTemplate: _bodyCtrl.text,
      responseMapping: {
        'stdout': _stdoutMapCtrl.text,
        'stderr': _stderrMapCtrl.text,
        'time': _timeMapCtrl.text,
      },
    );

    const testCode = "print('Hello from custom API');";

    Fluttertoast.showToast(msg: 'Testing Connection...');
    await ref.read(executionProvider.notifier).executeCode(
      code: testCode,
      useOneCompiler: false,
      customPreset: testPreset,
    );

    final execState = ref.read(executionProvider);
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Test Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stdout:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(execState.stdout.isEmpty ? 'None' : execState.stdout),
                const SizedBox(height: 8),
                const Text('Stderr:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(execState.stderr.isEmpty ? 'None' : execState.stderr, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        ),
      );
    }
  }

  Widget _buildKeyValueTable(String title, List<MapEntry<String, String>> list, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent), onPressed: onAdd),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: list[index].key,
                      decoration: const InputDecoration(hintText: 'Key', border: OutlineInputBorder()),
                      onChanged: (val) => list[index] = MapEntry(val, list[index].value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: list[index].value,
                      decoration: const InputDecoration(hintText: 'Value', border: OutlineInputBorder()),
                      onChanged: (val) => list[index] = MapEntry(list[index].key, val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() => list.removeAt(index)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL'))),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                    Fluttertoast.showToast(msg: 'Copied URL');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _method = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _authType = val!),
            ),
            const SizedBox(height: 16),
            _buildKeyValueTable('Dynamic Headers', _headers, () => setState(() => _headers.add(const MapEntry('', '')))),
            const SizedBox(height: 16),
            _buildKeyValueTable('Dynamic Query Params', _queryParams, () => setState(() => _queryParams.add(const MapEntry('', '')))),
            const SizedBox(height: 16),
            const Text('Request Body (JSON Template)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.black26,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: _stdoutMapCtrl, decoration: const InputDecoration(labelText: 'stdout path (e.g., data.stdout)')),
            TextField(controller: _stderrMapCtrl, decoration: const InputDecoration(labelText: 'stderr path (e.g., error.message)')),
            TextField(controller: _timeMapCtrl, decoration: const InputDecoration(labelText: 'execution time path')),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
