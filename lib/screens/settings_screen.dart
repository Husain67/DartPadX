import '../utils/constants.dart';
import '../services/compiler_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Runs code via default API'),
            value: settings.useDefaultOneCompiler,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleDefaultCompiler(val);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Custom Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...settings.presets.map((preset) => ListTile(
            title: Text(preset.name),
            subtitle: Text(preset.endpointUrl),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!settings.useDefaultOneCompiler && settings.activePresetId == preset.id)
                  const Icon(Icons.check_circle, color: Colors.green),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPreset(preset),
                ),
              ],
            ),
            onTap: () {
              ref.read(settingsProvider.notifier).setActivePreset(preset.id);
              ref.read(settingsProvider.notifier).toggleDefaultCompiler(false);
            },
          )),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Test Connection (Active Preset)'),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportPresets(),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Export JSON'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _importPresets(),
                  icon: const Icon(Icons.download),
                  label: const Text('Import JSON'),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _editPreset(null),
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Preset'),
            ),
          )
        ],
      ),
    );
  }


  Future<void> _exportPresets() async {
    final presets = ref.read(settingsProvider).presets;
    final jsonStr = jsonEncode(presets.map((p) => p.toJson()).toList());
    await Clipboard.setData(ClipboardData(text: jsonStr));
    Fluttertoast.showToast(msg: "Presets exported to clipboard as JSON");
  }

  Future<void> _importPresets() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        final List<dynamic> jsonList = jsonDecode(data.text!);
        for (var item in jsonList) {
          final preset = CompilerPreset.fromJson(item);
          ref.read(settingsProvider.notifier).addPreset(preset);
        }
        Fluttertoast.showToast(msg: "Presets imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to import presets from clipboard");
    }
  }

  void _testConnection() async {
    final settingsState = ref.read(settingsProvider);
    if (settingsState.activePreset == null) {
        Fluttertoast.showToast(msg: "Please select an active custom preset first");
        return;
    }
    Fluttertoast.showToast(msg: "Testing connection...");
    final result = await CompilerService.executeCustom(settingsState.activePreset!, Constants.testConnectionCode, "");

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stdout: ${result.stdout}', style: const TextStyle(color: Colors.green)),
              Text('Stderr: ${result.stderr}', style: const TextStyle(color: Colors.red)),
              Text('Error: ${result.error}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      )
    );
  }

  void _editPreset(CompilerPreset? preset) {
    // In a real app, this would push to a complex editing screen.
    // For brevity, adding a simple dialog or basic screen.
    // Given the prompt requirement for "Super Advanced Custom Compiler API System",
    // We should implement a detailed form.
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
  }
}


class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController urlCtrl;
  late TextEditingController bodyCtrl;
  late TextEditingController authValueCtrl;

  String httpMethod = 'POST';
  String authType = 'None';
  List<MapEntry<String, String>> headers = [];
  List<MapEntry<String, String>> queryParams = [];

  // Response Mapping Controllers
  late TextEditingController stdoutCtrl;
  late TextEditingController stderrCtrl;
  late TextEditingController errorCtrl;
  late TextEditingController timeCtrl;
  late TextEditingController memoryCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.preset?.name ?? '');
    urlCtrl = TextEditingController(text: widget.preset?.endpointUrl ?? '');
    bodyCtrl = TextEditingController(text: widget.preset?.bodyTemplate ?? '{"code": "{code}", "language": "{language}"}');
    authValueCtrl = TextEditingController(text: widget.preset?.authValue ?? '');

    if (widget.preset != null) {
      httpMethod = widget.preset!.httpMethod;
      authType = widget.preset!.authType;
      headers = widget.preset!.headers.entries.toList();
      queryParams = widget.preset!.queryParams.entries.toList();
    }

    final rm = widget.preset?.responseMapping ?? ResponseMapping();
    stdoutCtrl = TextEditingController(text: rm.stdoutPath);
    stderrCtrl = TextEditingController(text: rm.stderrPath);
    errorCtrl = TextEditingController(text: rm.errorPath);
    timeCtrl = TextEditingController(text: rm.executionTimePath);
    memoryCtrl = TextEditingController(text: rm.memoryPath);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    urlCtrl.dispose();
    bodyCtrl.dispose();
    authValueCtrl.dispose();
    stdoutCtrl.dispose();
    stderrCtrl.dispose();
    errorCtrl.dispose();
    timeCtrl.dispose();
    memoryCtrl.dispose();
    super.dispose();
  }

  void _addHeader() {
    setState(() {
      headers.add(const MapEntry('', ''));
    });
  }

  void _addQueryParam() {
    setState(() {
      queryParams.add(const MapEntry('', ''));
    });
  }

  Widget _buildKeyValueList(String title, List<MapEntry<String, String>> list, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> mapEntry = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: mapEntry.key,
                  decoration: const InputDecoration(hintText: 'Key'),
                  onChanged: (v) => setState(() => list[idx] = MapEntry(v, mapEntry.value)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: mapEntry.value,
                  decoration: const InputDecoration(hintText: 'Value'),
                  onChanged: (v) => setState(() => list[idx] = MapEntry(mapEntry.key, v)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => setState(() => list.removeAt(idx)),
              ),
            ],
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
          if (widget.preset != null) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                final duplicate = CompilerPreset(
                  id: const Uuid().v4(),
                  name: '${widget.preset!.name} (Copy)',
                  endpointUrl: widget.preset!.endpointUrl,
                  httpMethod: widget.preset!.httpMethod,
                  authType: widget.preset!.authType,
                  authValue: widget.preset!.authValue,
                  headers: Map.from(widget.preset!.headers),
                  queryParams: Map.from(widget.preset!.queryParams),
                  bodyTemplate: widget.preset!.bodyTemplate,
                  responseMapping: ResponseMapping.fromJson(widget.preset!.responseMapping.toJson()),
                );
                ref.read(settingsProvider.notifier).addPreset(duplicate);
                Navigator.pop(context);
              },
              tooltip: 'Duplicate',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref.read(settingsProvider.notifier).deletePreset(widget.preset!.id);
                Navigator.pop(context);
              },
              tooltip: 'Delete',
            ),
          ]
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Preset Name')),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                labelText: 'Endpoint URL',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => Clipboard.setData(ClipboardData(text: urlCtrl.text)),
                )
              )
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => httpMethod = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => authType = v!),
            ),
            if (authType != 'None')
              TextField(
                controller: authValueCtrl,
                decoration: InputDecoration(labelText: 'Auth Value (\$authType)'),
                obscureText: true,
              ),
            const SizedBox(height: 16),
            _buildKeyValueList('Headers', headers, _addHeader),
            const SizedBox(height: 16),
            _buildKeyValueList('Query Params', queryParams, _addQueryParam),
            const SizedBox(height: 16),
            const Text('Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Use placeholders: {code}, {stdin}, {language}'),
            TextField(
              controller: bodyCtrl,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextField(controller: stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path')),
            TextField(controller: stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path')),
            TextField(controller: errorCtrl, decoration: const InputDecoration(labelText: 'error path')),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'executionTime path')),
            TextField(controller: memoryCtrl, decoration: const InputDecoration(labelText: 'memory path')),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final newPreset = CompilerPreset(
                  id: widget.preset?.id ?? const Uuid().v4(),
                  name: nameCtrl.text,
                  endpointUrl: urlCtrl.text,
                  httpMethod: httpMethod,
                  authType: authType,
                  authValue: authValueCtrl.text.isEmpty ? null : authValueCtrl.text,
                  headers: Map.fromEntries(headers.where((e) => e.key.isNotEmpty)),
                  queryParams: Map.fromEntries(queryParams.where((e) => e.key.isNotEmpty)),
                  bodyTemplate: bodyCtrl.text,
                  responseMapping: ResponseMapping(
                    stdoutPath: stdoutCtrl.text,
                    stderrPath: stderrCtrl.text,
                    errorPath: errorCtrl.text,
                    executionTimePath: timeCtrl.text,
                    memoryPath: memoryCtrl.text,
                  ),
                );

                if (widget.preset == null) {
                  ref.read(settingsProvider.notifier).addPreset(newPreset);
                } else {
                  ref.read(settingsProvider.notifier).updatePreset(newPreset);
                }
                Navigator.pop(context);
              },
              child: const Text('Save Preset'),
            )
          ],
        ),
      ),
    );
  }
}
