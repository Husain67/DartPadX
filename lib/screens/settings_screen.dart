// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFACC15),
            labelColor: Color(0xFFFACC15),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('General Settings (coming soon)')),
            CompilerPresetsTab(),
          ],
        ),
      ),
    );
  }
}

class CompilerPresetsTab extends ConsumerStatefulWidget {
  const CompilerPresetsTab({super.key});

  @override
  ConsumerState<CompilerPresetsTab> createState() => _CompilerPresetsTabState();
}

class _CompilerPresetsTabState extends ConsumerState<CompilerPresetsTab> {
  void _editPreset(CompilerPreset preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorScreen(preset: preset),
      ),
    );
  }

  void _createNewPreset() {
    final newPreset = CompilerPreset(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      platformName: 'New Preset',
      endpointUrl: 'https://api.example.com/execute',
      httpMethod: 'POST',
      authType: 'None',
      requestBodyTemplate: '{"code": "{code}"}',
      stdoutPath: 'stdout',
      stderrPath: 'stderr',
      errorPath: 'error',
      executionTimePath: 'time',
      memoryPath: 'memory',
    );
    _editPreset(newPreset);
  }

  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _createNewPreset,
            icon: const Icon(Icons.add),
            label: const Text('Add New Preset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: compilerState.presets.length,
            itemBuilder: (context, index) {
              final preset = compilerState.presets[index];
              final isActive = compilerState.activePreset?.id == preset.id;

              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(preset.platformName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive)
                        const Icon(Icons.check_circle, color: Color(0xFFFACC15)),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editPreset(preset),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          ref.read(compilerProvider.notifier).deletePreset(preset.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController urlCtrl;
  late TextEditingController bodyCtrl;
  late TextEditingController stdoutCtrl;
  late TextEditingController stderrCtrl;
  late TextEditingController errorCtrl;
  late TextEditingController timeCtrl;
  late TextEditingController memoryCtrl;

  String selectedMethod = 'POST';
  String selectedAuth = 'None';

  List<MapEntry<String, String>> headers = [];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.preset.platformName);
    urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    errorCtrl = TextEditingController(text: widget.preset.errorPath);
    timeCtrl = TextEditingController(text: widget.preset.executionTimePath);
    memoryCtrl = TextEditingController(text: widget.preset.memoryPath);

    selectedMethod = widget.preset.httpMethod;
    selectedAuth = widget.preset.authType;
    headers = widget.preset.dynamicHeaders.entries.toList();
  }

  void _save() {
    final updated = widget.preset.copyWith(
      platformName: nameCtrl.text,
      endpointUrl: urlCtrl.text,
      httpMethod: selectedMethod,
      authType: selectedAuth,
      dynamicHeaders: Map.fromEntries(headers),
      requestBodyTemplate: bodyCtrl.text,
      stdoutPath: stdoutCtrl.text,
      stderrPath: stderrCtrl.text,
      errorPath: errorCtrl.text,
      executionTimePath: timeCtrl.text,
      memoryPath: memoryCtrl.text,
    );
    ref.read(compilerProvider.notifier).addOrUpdatePreset(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name')),
            const SizedBox(height: 16),
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => selectedMethod = v!),
              decoration: const InputDecoration(labelText: 'HTTP Method'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedAuth,
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => selectedAuth = v!),
              decoration: const InputDecoration(labelText: 'Auth Type'),
            ),
            const SizedBox(height: 16),
            const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold)),
            ...headers.asMap().entries.map((entry) {
              int idx = entry.key;
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: entry.value.key,
                      onChanged: (v) => headers[idx] = MapEntry(v, headers[idx].value),
                      decoration: const InputDecoration(hintText: 'Key'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: entry.value.value,
                      onChanged: (v) => headers[idx] = MapEntry(headers[idx].key, v),
                      decoration: const InputDecoration(hintText: 'Value'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => setState(() => headers.removeAt(idx)),
                  )
                ],
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => headers.add(const MapEntry('', ''))),
              icon: const Icon(Icons.add),
              label: const Text('Add Header'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Request Body Template (JSON)',
                helperText: 'Use placeholders: {code}, {stdin}',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(controller: stdoutCtrl, decoration: const InputDecoration(labelText: 'Stdout Path')),
            TextField(controller: stderrCtrl, decoration: const InputDecoration(labelText: 'Stderr Path')),
            TextField(controller: errorCtrl, decoration: const InputDecoration(labelText: 'Error Path')),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Execution Time Path')),
            TextField(controller: memoryCtrl, decoration: const InputDecoration(labelText: 'Memory Path')),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
