import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../providers/compiler_provider.dart';
import '../providers/execution_provider.dart';
import '../models/models.dart';
import '../core/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _importController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & API'),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        Widget leftPanel = Container(
          width: isMobile ? constraints.maxWidth : 250,
            color: AppTheme.backgroundStart,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Use Default OneCompiler'),
                  value: compilerState.useDefaultOneCompiler,
                  onChanged: (val) {
                    ref.read(compilerProvider.notifier).setUseDefaultOneCompiler(val);
                  },
                  activeTrackColor: AppTheme.primaryAccent,
                  activeThumbColor: AppTheme.pureBlack,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Export JSON'),
                  leading: const Icon(Icons.download),
                  onTap: () {
                    final jsonStr = ref.read(compilerProvider.notifier).exportPresets();
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    Fluttertoast.showToast(msg: 'Export copied to clipboard');
                  },
                ),
                ListTile(
                  title: const Text('Import JSON'),
                  leading: const Icon(Icons.upload),
                  onTap: () {
                    _showImportDialog();
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Custom Presets', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: compilerState.presets.length,
                    itemBuilder: (context, index) {
                      final p = compilerState.presets[index];
                      final isSelected = p.id == compilerState.activePresetId;
                      return ListTile(
                        title: Text(p.name),
                        selected: isSelected,
                        selectedTileColor: Colors.white10,
                        onTap: () {
                          ref.read(compilerProvider.notifier).setActivePreset(p.id);
                          if (isMobile) {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text('Edit Preset')), body: PresetEditor(presetId: p.id))));
                          }
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            ref.read(compilerProvider.notifier).duplicatePreset(p.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New Preset'),
                    onPressed: () {
                      final newPreset = CompilerPreset(
                        id: const Uuid().v4(),
                        name: 'New Custom API',
                        url: '',
                      );
                      ref.read(compilerProvider.notifier).savePreset(newPreset);
                      ref.read(compilerProvider.notifier).setActivePreset(newPreset.id);
                      if (isMobile) {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text('Edit Preset')), body: PresetEditor(presetId: newPreset.id))));
                      }
                    },
                  ),
                )
              ],
            ),
        );

        Widget rightPanel = Expanded(
            child: compilerState.activePreset != null
                ? PresetEditor(presetId: compilerState.activePresetId)
                : const Center(child: Text('Select a preset')),
        );

        if (isMobile) {
           return leftPanel;
        }
        return Row(
          children: [
            leftPanel,
            const VerticalDivider(width: 1),
            rightPanel,
          ],
        );
      }),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Presets'),
        content: TextField(
          controller: _importController,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Paste JSON here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(compilerProvider.notifier).importPresets(_importController.text);
              _importController.clear();
              Navigator.pop(ctx);
              Fluttertoast.showToast(msg: 'Imported successfully');
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

class PresetEditor extends ConsumerStatefulWidget {
  final String presetId;
  const PresetEditor({super.key, required this.presetId});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  late CompilerPreset preset;

  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _authKeyCtrl = TextEditingController();
  final _authValueCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  final _stdoutCtrl = TextEditingController();
  final _stderrCtrl = TextEditingController();
  final _errorCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _memCtrl = TextEditingController();

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _loadPreset();
  }

  @override
  void didUpdateWidget(PresetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presetId != widget.presetId) {
      _loadPreset();
    }
  }

  void _loadPreset() {
    final state = ref.read(compilerProvider);
    preset = state.presets.firstWhere((p) => p.id == widget.presetId);

    _nameCtrl.text = preset.name;
    _urlCtrl.text = preset.url;
    _authKeyCtrl.text = preset.authKey;
    _authValueCtrl.text = preset.authValue;
    _bodyCtrl.text = preset.bodyTemplate;

    _stdoutCtrl.text = preset.stdoutPath;
    _stderrCtrl.text = preset.stderrPath;
    _errorCtrl.text = preset.errorPath;
    _timeCtrl.text = preset.executionTimePath;
    _memCtrl.text = preset.memoryPath;

    _headers = preset.headers.entries.toList();
    _queryParams = preset.queryParams.entries.toList();
  }

  void _save() {
    final newPreset = preset.copyWith(
      name: _nameCtrl.text,
      url: _urlCtrl.text,
      authKey: _authKeyCtrl.text,
      authValue: _authValueCtrl.text,
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
    );
    ref.read(compilerProvider.notifier).savePreset(newPreset);
    Fluttertoast.showToast(msg: 'Saved');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Platform Name'),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Changes'),
            ),
            if (!preset.isPreloaded) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                onPressed: () {
                  ref.read(compilerProvider.notifier).deletePreset(preset.id);
                },
              )
            ]
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(labelText: 'Endpoint URL'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                Fluttertoast.showToast(msg: 'URL Copied');
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: preset.method,
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  setState(() => preset = preset.copyWith(method: val!));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: preset.authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  setState(() => preset = preset.copyWith(authType: val!));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (preset.authType != 'None')
          Row(
            children: [
              if (preset.authType == 'API-Key Header' || preset.authType == 'Query Param')
                Expanded(
                  child: TextField(
                    controller: _authKeyCtrl,
                    decoration: const InputDecoration(labelText: 'Auth Key Name'),
                  ),
                ),
              if (preset.authType == 'API-Key Header' || preset.authType == 'Query Param')
                const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _authValueCtrl,
                  decoration: const InputDecoration(labelText: 'Auth Value'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
        const Text('Dynamic Headers', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._headers.asMap().entries.map((e) {
          int idx = e.key;
          var entry = e.value;
          return Row(
            key: ValueKey('header_$idx'),
            children: [
              Expanded(child: TextFormField(initialValue: entry.key, decoration: const InputDecoration(hintText: 'Key'), onChanged: (val) { _headers[idx] = MapEntry(val, entry.value); })),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(initialValue: entry.value, decoration: const InputDecoration(hintText: 'Value'), onChanged: (val) { _headers[idx] = MapEntry(entry.key, val); })),
              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () { setState(() { _headers.removeAt(idx); }); })
            ],
          );
        }),
        TextButton.icon(onPressed: () { setState(() { _headers.add(const MapEntry('', '')); }); }, icon: const Icon(Icons.add), label: const Text('Add Header')),

        const SizedBox(height: 24),
        const Text('Dynamic Query Params', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._queryParams.asMap().entries.map((e) {
          int idx = e.key;
          var entry = e.value;
          return Row(
            key: ValueKey('query_$idx'),
            children: [
              Expanded(child: TextFormField(initialValue: entry.key, decoration: const InputDecoration(hintText: 'Key'), onChanged: (val) { _queryParams[idx] = MapEntry(val, entry.value); })),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(initialValue: entry.value, decoration: const InputDecoration(hintText: 'Value'), onChanged: (val) { _queryParams[idx] = MapEntry(entry.key, val); })),
              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () { setState(() { _queryParams.removeAt(idx); }); })
            ],
          );
        }),
        TextButton.icon(onPressed: () { setState(() { _queryParams.add(const MapEntry('', '')); }); }, icon: const Icon(Icons.add), label: const Text('Add Query Param')),

        const SizedBox(height: 24),
        const Text('Request Body Template JSON (Use {code}, {stdin})', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyCtrl,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '{\n  "language": "dart",\n  "content": "{code}"\n}',
            alignLabelWithHint: true,
          ),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 24),
        const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path'))),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path'))),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _errorCtrl, decoration: const InputDecoration(labelText: 'error path'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'executionTime path'))),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _memCtrl, decoration: const InputDecoration(labelText: 'memory path'))),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            _save();
            await ref.read(executionProvider.notifier).testConnection(preset);
            final resp = ref.read(executionProvider).rawResponse;
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Test Result Raw Response'),
                content: SingleChildScrollView(child: Text(resp)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
                ],
              ),
            );
          },
          child: const Text('Test Connection'),
        ),
      ],
    );
  }
}
