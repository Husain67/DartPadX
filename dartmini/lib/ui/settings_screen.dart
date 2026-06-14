import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import '../providers/compiler_notifier.dart';
import '../models/compiler_preset.dart';
import '../theme.dart';

import '../models/compiler_preset.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}


class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _exportPresets(BuildContext context, List<CompilerPreset> presets) async {
    final list = presets.map((p) => {
      'id': p.id,
      'name': p.name,
      'endpointUrl': p.endpointUrl,
      'httpMethod': p.httpMethod,
      'authType': p.authType,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'requestBodyTemplate': p.requestBodyTemplate,
      'responseMapping': p.responseMapping,
    }).toList();
    final jsonStr = jsonEncode(list);
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported presets copied to clipboard!')));
  }

  void _importPresets(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      try {
        final List<dynamic> list = jsonDecode(data.text!);
        for (var item in list) {
          final p = CompilerPreset(
            id: item['id'] ?? const Uuid().v4(),
            name: item['name'] ?? 'Imported Preset',
            endpointUrl: item['endpointUrl'] ?? '',
            httpMethod: item['httpMethod'] ?? 'POST',
            authType: item['authType'] ?? 'None',
            headers: Map<String, String>.from(item['headers'] ?? {}),
            queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
            requestBodyTemplate: item['requestBodyTemplate'] ?? '',
            responseMapping: Map<String, String>.from(item['responseMapping'] ?? {}),
          );
          ref.read(compilerProvider.notifier).addPreset(p);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presets imported successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to parse JSON.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Settings & API Configuration'),
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Toggle between default fast execution and custom API presets.', style: TextStyle(color: Colors.white70)),
              value: state.useDefaultOneCompiler,
              onChanged: (val) {
                ref.read(compilerProvider.notifier).toggleDefault(val);
              },
              activeColor: AppTheme.primaryAccent,
            ),
            const Divider(color: Colors.white24, height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportPresets(context, state.presets),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Export JSON'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.buttonBackground, foregroundColor: Colors.black),
                ),
                ElevatedButton.icon(
                  onPressed: () => _importPresets(context, ref),
                  icon: const Icon(Icons.download),
                  label: const Text('Import JSON'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.buttonBackground, foregroundColor: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                const Text('Compiler Presets', style: TextStyle(color: AppTheme.primaryAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent),
                  onPressed: () {
                    // Create empty preset
                    final newPreset = CompilerPreset(
                      id: const Uuid().v4(),
                      name: 'New Custom API',
                      endpointUrl: '',
                      httpMethod: 'POST',
                      authType: 'None',
                      headers: {},
                      queryParams: {},
                      requestBodyTemplate: '{\n  "code": "{code}"\n}',
                      responseMapping: {'stdout': '', 'stderr': '', 'error': '', 'executionTime': '', 'memory': ''},
                    );
                    ref.read(compilerProvider.notifier).addPreset(newPreset);
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            ...state.presets.map((preset) {
              final isSelected = !state.useDefaultOneCompiler && state.activePresetId == preset.id;
              return Card(
                color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isSelected ? AppTheme.primaryAccent : Colors.white24, width: isSelected ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(preset.endpointUrl.isEmpty ? 'No endpoint' : preset.endpointUrl, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  leading: Radio<String>(
                    value: preset.id,
                    groupValue: state.useDefaultOneCompiler ? null : state.activePresetId,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(compilerProvider.notifier).toggleDefault(false);
                        ref.read(compilerProvider.notifier).setActivePreset(val);
                      }
                    },
                    activeColor: AppTheme.primaryAccent,
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  children: [
                    _PresetEditor(preset: preset),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  const _PresetEditor({Key? key, required this.preset}) : super(key: key);

  @override
  ConsumerState<_PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<_PresetEditor> {
  late TextEditingController nameCtrl;
  late TextEditingController urlCtrl;
  late TextEditingController bodyCtrl;
  late TextEditingController stdoutCtrl;
  late TextEditingController stderrCtrl;
  late TextEditingController errorCtrl;
  late TextEditingController timeCtrl;
  late TextEditingController memCtrl;

  late String method;
  late String authType;

  List<MapEntry<String, String>> headerList = [];
  List<MapEntry<String, String>> paramList = [];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.preset.name);
    urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    stdoutCtrl = TextEditingController(text: widget.preset.responseMapping['stdout'] ?? '');
    stderrCtrl = TextEditingController(text: widget.preset.responseMapping['stderr'] ?? '');
    errorCtrl = TextEditingController(text: widget.preset.responseMapping['error'] ?? '');
    timeCtrl = TextEditingController(text: widget.preset.responseMapping['executionTime'] ?? '');
    memCtrl = TextEditingController(text: widget.preset.responseMapping['memory'] ?? '');

    method = widget.preset.httpMethod;
    authType = widget.preset.authType;

    headerList = widget.preset.headers.entries.toList();
    paramList = widget.preset.queryParams.entries.toList();
  }

  void _save() {
    final newHeaders = Map.fromEntries(headerList.where((e) => e.key.isNotEmpty));
    final newParams = Map.fromEntries(paramList.where((e) => e.key.isNotEmpty));

    final updated = widget.preset.copyWith(
      name: nameCtrl.text,
      endpointUrl: urlCtrl.text,
      httpMethod: method,
      authType: authType,
      headers: newHeaders,
      queryParams: newParams,
      requestBodyTemplate: bodyCtrl.text,
      responseMapping: {
        'stdout': stdoutCtrl.text,
        'stderr': stderrCtrl.text,
        'error': errorCtrl.text,
        'executionTime': timeCtrl.text,
        'memory': memCtrl.text,
      },
    );
    ref.read(compilerProvider.notifier).updatePreset(updated);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(controller: nameCtrl, decoration: _inputDec('Preset Name'), style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField(controller: urlCtrl, decoration: _inputDec('Endpoint URL'), style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: method,
                dropdownColor: AppTheme.backgroundStart,
                decoration: _inputDec('HTTP Method'),
                items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setState(() => method = val!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: authType,
                dropdownColor: AppTheme.backgroundStart,
                decoration: _inputDec('Auth Type'),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (val) => setState(() => authType = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDynamicTable('Headers', headerList),
        const SizedBox(height: 16),
        _buildDynamicTable('Query Params', paramList),
        const SizedBox(height: 16),
        const Text('Request Body JSON Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(controller: bodyCtrl, maxLines: 6, decoration: _inputDec('{}'), style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
        const SizedBox(height: 16),
        const Text('Response Mapping (Dot Notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: stdoutCtrl, decoration: _inputDec('stdout path (e.g., data.output)'), style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField(controller: stderrCtrl, decoration: _inputDec('stderr path'), style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField(controller: errorCtrl, decoration: _inputDec('error path'), style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField(controller: timeCtrl, decoration: _inputDec('executionTime path'), style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField(controller: memCtrl, decoration: _inputDec('memory path'), style: const TextStyle(color: Colors.white)),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [

            TextButton.icon(
              onPressed: () {
                final duplicate = widget.preset.copyWith(
                  id: const Uuid().v4(),
                  name: '${widget.preset.name} (Copy)',
                );
                ref.read(compilerProvider.notifier).addPreset(duplicate);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset duplicated!')));
              },
              icon: const Icon(Icons.copy, color: Colors.white70),
              label: const Text('Duplicate', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(width: 8),

            TextButton.icon(
              onPressed: () {
                ref.read(compilerProvider.notifier).deletePreset(widget.preset.id);
              },
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent, foregroundColor: Colors.black),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Preset', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryAccent, size: 20),
              onPressed: () => setState(() => list.add(const MapEntry('', ''))),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int i = entry.key;
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(child: TextFormField(
                  initialValue: list[i].key,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDec('Key'),
                  onChanged: (val) => list[i] = MapEntry(val, list[i].value),
                )),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(
                  initialValue: list[i].value,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDec('Value'),
                  onChanged: (val) => list[i] = MapEntry(list[i].key, val),
                )),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  onPressed: () => setState(() => list.removeAt(i)),
                )
              ],
            ),
          );
        }).toList()
      ],
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryAccent)),
      isDense: true,
    );
  }
}
