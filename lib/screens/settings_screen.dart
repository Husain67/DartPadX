import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

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
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Compiler Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Recommended for stable dart execution.', style: TextStyle(color: Colors.grey)),
                  value: compilerState.useDefaultOneCompiler,
                  activeColor: const Color(0xFFFACC15),
                  onChanged: (val) {
                    ref.read(compilerProvider.notifier).toggleUseDefaultOneCompiler(val);
                  },
                ),
                const Divider(color: Colors.white24),
                if (!compilerState.useDefaultOneCompiler) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Custom Presets',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: Colors.black,
                        ),
                        onChanged: null,
                        onPressed: () => _showPresetDialog(context, null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: compilerState.presets.length,
                      itemBuilder: (context, index) {
                        final preset = compilerState.presets[index];
                        final isActive = preset.id == compilerState.activePresetId;

                        return Card(
                          color: const Color(0xFF1A1A1A),
                          child: ListTile(
                            leading: Icon(
                              Icons.api,
                              color: isActive ? const Color(0xFFFACC15) : Colors.grey,
                            ),
                            title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isActive)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                                    onPressed: () => ref.read(compilerProvider.notifier).setActivePreset(preset.id),
                                    tooltip: 'Set Active',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  onPressed: () => _showPresetDialog(context, preset),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                   const Expanded(
                     child: Center(
                       child: Text(
                         'Custom presets are disabled.\nToggle to enable custom APIs.',
                         textAlign: TextAlign.center,
                         style: TextStyle(color: Colors.grey),
                       ),
                     ),
                   )
                ]
              ],
            ),
          );
        }
      ),
    );
  }

  void _showPresetDialog(BuildContext context, CompilerPreset? preset) {
    showDialog(
      context: context,
      builder: (context) => _PresetEditDialog(preset: preset),
    );
  }
}

class _PresetEditDialog extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const _PresetEditDialog({this.preset});

  @override
  ConsumerState<_PresetEditDialog> createState() => _PresetEditDialogState();
}

class _PresetEditDialogState extends ConsumerState<_PresetEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _authValCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memCtrl;

  List<HeaderModel> _headers = [];
  List<QueryParamModel> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? 'New Preset');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _method = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{\n  "language": "dart",\n  "files": [\n    {\n      "content": "{code}"\n    }\n  ],\n  "stdin": "{stdin}"\n}');
    _stdoutCtrl = TextEditingController(text: p?.responseStdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: p?.responseStderrPath ?? '');
    _errCtrl = TextEditingController(text: p?.responseErrorPath ?? '');
    _timeCtrl = TextEditingController(text: p?.responseTimePath ?? '');
    _memCtrl = TextEditingController(text: p?.responseMemoryPath ?? '');

    if (p != null) {
      _headers = List.from(p.headers.map((h) => HeaderModel(key: h.key, value: h.value)));
      _queryParams = List.from(p.queryParams.map((q) => QueryParamModel(key: q.key, value: q.value)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildTextField(_nameCtrl, 'Platform Name'),
                  _buildTextField(_urlCtrl, 'Endpoint URL'),
                  _buildDropdown('HTTP Method', ['POST', 'GET', 'PUT'], _method, (val) => setState(() => _method = val!)),
                  _buildDropdown('Auth Type', ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'], _authType, (val) => setState(() => _authType = val!)),
                  if (_authType != 'None') _buildTextField(_authValCtrl, 'Auth Value / Key'),

                  const SizedBox(height: 16),
                  const Text('Headers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ..._headers.asMap().entries.map((e) => _buildKeyValueRow(
                    e.key, e.value.key, e.value.value,
                    (k) => setState(() => _headers[e.key].key = k),
                    (v) => setState(() => _headers[e.key].value = v),
                    () => setState(() => _headers.removeAt(e.key)),
                  )),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Header'),
                    onPressed: () => setState(() => _headers.add(HeaderModel(key: '', value: ''))),
                  ),

                  const SizedBox(height: 16),
                  const Text('Query Params', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ..._queryParams.asMap().entries.map((e) => _buildKeyValueRow(
                    e.key, e.value.key, e.value.value,
                    (k) => setState(() => _queryParams[e.key].key = k),
                    (v) => setState(() => _queryParams[e.key].value = v),
                    () => setState(() => _queryParams.removeAt(e.key)),
                  )),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Param'),
                    onPressed: () => setState(() => _queryParams.add(QueryParamModel(key: '', value: ''))),
                  ),

                  const SizedBox(height: 16),
                  const Text('Request Body JSON Template (use {code}, {stdin})', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _bodyCtrl,
                    maxLines: 8,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF050505),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Response Mapping (dot notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  _buildTextField(_stdoutCtrl, 'stdout path'),
                  _buildTextField(_stderrCtrl, 'stderr path'),
                  _buildTextField(_errCtrl, 'error path'),
                  _buildTextField(_timeCtrl, 'executionTime path'),
                  _buildTextField(_memCtrl, 'memory path'),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black),
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: const Color(0xFF1A1A1A),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        ),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildKeyValueRow(int index, String key, String value, void Function(String) onKeyChanged, void Function(String) onValChanged, VoidCallback onRemove) {
    return Padding(
      key: ValueKey(index),
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Expanded(child: TextField(
            onChanged: onKeyChanged,
            controller: TextEditingController(text: key)..selection = TextSelection.collapsed(offset: key.length),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.grey), isDense: true),
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            onChanged: onValChanged,
            controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.grey), isDense: true),
          )),
          IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20), onPressed: onRemove),
        ],
      ),
    );
  }

  void _save() {
    final newPreset = CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValCtrl.text,
      headers: _headers,
      queryParams: _queryParams,
      requestBodyTemplate: _bodyCtrl.text,
      responseStdoutPath: _stdoutCtrl.text,
      responseStderrPath: _stderrCtrl.text,
      responseErrorPath: _errCtrl.text,
      responseTimePath: _timeCtrl.text,
      responseMemoryPath: _memCtrl.text,
      isDefault: widget.preset?.isDefault ?? false,
    );

    if (widget.preset == null) {
      ref.read(compilerProvider.notifier).addPreset(newPreset);
    } else {
      ref.read(compilerProvider.notifier).updatePreset(newPreset);
    }

    Navigator.pop(context);
  }
}
