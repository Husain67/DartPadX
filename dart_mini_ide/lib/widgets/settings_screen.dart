import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/settings_provider.dart';
import '../providers/compiler_provider.dart';
import '../providers/file_provider.dart';
import '../models/compiler_preset.dart';
import '../services/compiler_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Tab(text: 'App Settings'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AppSettingsTab(),
            _CompilerPresetsTab(),
          ],
        ),
      ),
    );
  }
}

class _AppSettingsTab extends ConsumerWidget {
  const _AppSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API'),
          subtitle: const Text('Bypass custom presets and use standard API'),
          activeTrackColor: const Color(0xFFFACC15).withValues(alpha: 0.5),
          activeThumbColor: const Color(0xFFFACC15),
          value: settings.useDefaultOneCompiler,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).toggleUseDefaultOneCompiler(val);
          },
        ),
      ],
    );
  }
}

class _CompilerPresetsTab extends ConsumerWidget {
  const _CompilerPresetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presetsState = ref.watch(compilerProvider);
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Blank'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.import_export),
                label: const Text('Export JSON'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
                onPressed: () {
                    final json = ref.read(storageServiceProvider).exportPresetsAsJson();
                    // Just showing it for now, real app might copy to clipboard or share
                    showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Exported JSON'),
                        content: SelectableText(json),
                        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
                      )
                    );
                },
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: presetsState.presets.length,
            itemBuilder: (context, index) {
              final preset = presetsState.presets[index];
              final isActive = preset.id == settings.activePresetId && !settings.useDefaultOneCompiler;
              return Card(
                color: const Color(0xFF1A1A1A),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isActive ? const Color(0xFFFACC15) : Colors.white10, width: isActive ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isActive)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white54),
                          onPressed: () {
                            ref.read(settingsProvider.notifier).toggleUseDefaultOneCompiler(false);
                            ref.read(settingsProvider.notifier).setActivePresetId(preset.id);
                          },
                          tooltip: 'Set Active',
                        ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                        onPressed: () => ref.read(compilerProvider.notifier).duplicatePreset(preset),
                        tooltip: 'Duplicate',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
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
  final CompilerPreset? preset;
  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyTemplateCtrl;

  late TextEditingController _mapStdoutCtrl;
  late TextEditingController _mapStderrCtrl;
  late TextEditingController _mapErrorCtrl;
  late TextEditingController _mapTimeCtrl;
  late TextEditingController _mapMemoryCtrl;

  String _method = 'POST';
  String _authType = 'None';
  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _endpointCtrl = TextEditingController(text: p?.endpoint ?? '');
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyTemplateCtrl = TextEditingController(text: p?.bodyTemplate ?? '{}');

    _mapStdoutCtrl = TextEditingController(text: p?.mappings['stdout'] ?? '');
    _mapStderrCtrl = TextEditingController(text: p?.mappings['stderr'] ?? '');
    _mapErrorCtrl = TextEditingController(text: p?.mappings['error'] ?? '');
    _mapTimeCtrl = TextEditingController(text: p?.mappings['executionTime'] ?? '');
    _mapMemoryCtrl = TextEditingController(text: p?.mappings['memory'] ?? '');

    if (p != null) {
      _method = p.method;
      _authType = p.authType;
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final preset = CompilerPreset(
        id: widget.preset?.id ?? _uuid.v4(),
        name: _nameCtrl.text,
        endpoint: _endpointCtrl.text,
        method: _method,
        authType: _authType,
        authValue: _authValueCtrl.text,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplateCtrl.text,
        mappings: {
          'stdout': _mapStdoutCtrl.text,
          'stderr': _mapStderrCtrl.text,
          'error': _mapErrorCtrl.text,
          'executionTime': _mapTimeCtrl.text,
          'memory': _mapMemoryCtrl.text,
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

  Future<void> _testConnection() async {
      final tempPreset = CompilerPreset(
        id: 'test',
        name: 'Test',
        endpoint: _endpointCtrl.text,
        method: _method,
        authType: _authType,
        authValue: _authValueCtrl.text,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplateCtrl.text,
        mappings: {
          'stdout': _mapStdoutCtrl.text,
          'stderr': _mapStderrCtrl.text,
          'error': _mapErrorCtrl.text,
          'executionTime': _mapTimeCtrl.text,
          'memory': _mapMemoryCtrl.text,
        },
      );

      final result = await CompilerService().executeCode("print('Hello from custom API');", "", tempPreset);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Test Result'),
          content: SingleChildScrollView(
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text('Parsed Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                   Text('stdout: ${result["stdout"]}'),
                   Text('stderr: ${result["stderr"]}'),
                   Text('error: ${result["error"]}'),
                   const Divider(),
                   const Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                   Text(result['rawResponse'] ?? 'Null', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                ],
             )
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
        )
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointCtrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder()),
                    items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_authType != 'None')
              TextFormField(
                controller: _authValueCtrl,
                decoration: const InputDecoration(labelText: 'Auth Value (API Key, Token, etc)', border: OutlineInputBorder()),
              ),

            const SizedBox(height: 24),
            const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ..._headers.asMap().entries.map((e) {
               return Row(
                  children: [
                    Expanded(child: TextFormField(initialValue: e.value.key, onChanged: (v) => _headers[e.key] = MapEntry(v, e.value.value), decoration: const InputDecoration(hintText: 'Key'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(initialValue: e.value.value, onChanged: (v) => _headers[e.key] = MapEntry(e.value.key, v), decoration: const InputDecoration(hintText: 'Value'))),
                    IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _headers.removeAt(e.key))),
                  ],
               );
            }),
            TextButton.icon(onPressed: () => setState(() => _headers.add(const MapEntry('',''))), icon: const Icon(Icons.add), label: const Text('Add Header')),

            const SizedBox(height: 24),
            const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             ..._queryParams.asMap().entries.map((e) {
               return Row(
                  children: [
                    Expanded(child: TextFormField(initialValue: e.value.key, onChanged: (v) => _queryParams[e.key] = MapEntry(v, e.value.value), decoration: const InputDecoration(hintText: 'Key'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(initialValue: e.value.value, onChanged: (v) => _queryParams[e.key] = MapEntry(e.value.key, v), decoration: const InputDecoration(hintText: 'Value'))),
                    IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _queryParams.removeAt(e.key))),
                  ],
               );
            }),
            TextButton.icon(onPressed: () => setState(() => _queryParams.add(const MapEntry('',''))), icon: const Icon(Icons.add), label: const Text('Add Query Param')),

            const SizedBox(height: 24),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateCtrl,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"code": {code}}'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),

            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(controller: _mapStdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path (e.g., data.output)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _mapStderrCtrl, decoration: const InputDecoration(labelText: 'stderr path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _mapErrorCtrl, decoration: const InputDecoration(labelText: 'error path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _mapTimeCtrl, decoration: const InputDecoration(labelText: 'execution time path', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextFormField(controller: _mapMemoryCtrl, decoration: const InputDecoration(labelText: 'memory path', border: OutlineInputBorder())),

            const SizedBox(height: 24),
            ElevatedButton(
               onPressed: _testConnection,
               style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
               child: const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
