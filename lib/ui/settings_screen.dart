// ignore_for_file: prefer_const_constructors, deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../providers/execution_notifier.dart';
import '../models/compiler_preset.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(presetsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Compiler Presets', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
            onPressed: () => _editPreset(null),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final preset = presets[index];
          return ListTile(
            title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: preset.isDefault
              ? const Icon(Icons.check_circle, color: Color(0xFFFACC15))
              : PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: const Color(0xFF1a1a1a),
                  onSelected: (val) {
                    if (val == 'set_default') {
                      ref.read(presetsProvider.notifier).setDefault(preset.id);
                      Fluttertoast.showToast(msg: 'Set as default');
                    } else if (val == 'edit') {
                      _editPreset(preset);
                    } else if (val == 'duplicate') {
                      final newPreset = preset.copyWith(
                        id: const Uuid().v4(),
                        name: '${preset.name} (Copy)',
                        isDefault: false,
                      );
                      ref.read(presetsProvider.notifier).addPreset(newPreset);
                    } else if (val == 'delete') {
                      if (preset.id != 'default_oc') {
                         ref.read(presetsProvider.notifier).deletePreset(preset.id);
                      } else {
                         Fluttertoast.showToast(msg: 'Cannot delete default preset');
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'set_default', child: Text('Set Default', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
            onTap: () => _editPreset(preset),
          );
        },
      ),
    );
  }

  void _editPreset(CompilerPreset? preset) {
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
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  String _method = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _execTimePathCtrl;
  late TextEditingController _memoryPathCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }

    _bodyTemplateCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '');
    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? '');
    _execTimePathCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _execTimePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameCtrl.text,
        endpointUrl: _urlCtrl.text,
        method: _method,
        authType: _authType,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _bodyTemplateCtrl.text,
        stdoutPath: _stdoutPathCtrl.text,
        stderrPath: _stderrPathCtrl.text,
        errorPath: _errorPathCtrl.text,
        executionTimePath: _execTimePathCtrl.text,
        memoryPath: _memoryPathCtrl.text,
        isDefault: widget.preset?.isDefault ?? false,
      );

      if (widget.preset == null) {
        ref.read(presetsProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(presetsProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    Fluttertoast.showToast(msg: 'Testing...');

    // Create a temporary preset from current form values to test
    final tempPreset = CompilerPreset(
      id: 'temp',
      name: 'Temp',
      endpointUrl: _urlCtrl.text,
      method: _method,
      authType: _authType,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      requestBodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _execTimePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    try {
      String code = "void main() { print('Hello from custom API'); }";
      String requestBody = tempPreset.requestBodyTemplate
          .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{stdin}', '')
          .replaceAll('{language}', 'dart');

      final uri = Uri.parse(tempPreset.endpointUrl).replace(queryParameters: tempPreset.queryParams.isNotEmpty ? tempPreset.queryParams : null);

      http.Response response;
      if (_method == 'GET') {
        response = await http.get(uri, headers: tempPreset.headers);
      } else if (_method == 'PUT') {
        response = await http.put(uri, headers: tempPreset.headers, body: requestBody);
      } else {
        response = await http.post(uri, headers: tempPreset.headers, body: requestBody);
      }

      // Show result dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          title: Text('Status: ${response.statusCode}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Text(response.body, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Color(0xFFFACC15))))
          ],
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.science, color: Colors.blueAccent), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save, color: Color(0xFFFACC15)), onPressed: _save)
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Basic Settings'),
            _buildTextField(_nameCtrl, 'Platform Name'),
            _buildTextField(_urlCtrl, 'Endpoint URL', maxLines: null),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _method,
              dropdownColor: const Color(0xFF1a1a1a),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType,
              dropdownColor: const Color(0xFF1a1a1a),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),

            _buildSectionTitle('Headers'),
            _buildDynamicTable(_headers),

            _buildSectionTitle('Query Params'),
            _buildDynamicTable(_queryParams),

            _buildSectionTitle('Request Body Template'),
            const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTextField(_bodyTemplateCtrl, 'JSON Template', maxLines: 10, isCode: true),

            _buildSectionTitle('Response Mapping (Dot Notation)'),
            _buildTextField(_stdoutPathCtrl, 'stdout Path (e.g., data.output)'),
            _buildTextField(_stderrPathCtrl, 'stderr Path'),
            _buildTextField(_errorPathCtrl, 'error Path'),
            _buildTextField(_execTimePathCtrl, 'executionTime Path'),
            _buildTextField(_memoryPathCtrl, 'memory Path'),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {int? maxLines = 1, bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: Colors.white, fontFamily: isCode ? 'monospace' : null),
        maxLines: maxLines,
        decoration: _inputDecoration(label),
        validator: (v) => v!.isEmpty && label.contains('Name') ? 'Required field' : null,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1a1a1a),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }

  Widget _buildDynamicTable(List<MapEntry<String, String>> list) {
    return Column(
      children: [
        for (int i = 0; i < list.length; i++)
          Padding(
            key: ValueKey('${list.hashCode}_$i'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: list[i].key,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Key'),
                    onChanged: (v) => list[i] = MapEntry(v, list[i].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: list[i].value,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Value'),
                    onChanged: (v) => list[i] = MapEntry(list[i].key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () => setState(() => list.removeAt(i)),
                )
              ],
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
          label: const Text('Add Row', style: TextStyle(color: Color(0xFFFACC15))),
          onPressed: () => setState(() => list.add(const MapEntry('', ''))),
        )
      ],
    );
  }
}
