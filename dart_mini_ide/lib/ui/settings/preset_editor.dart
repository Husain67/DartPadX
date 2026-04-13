import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../providers/preset_provider.dart';
import '../../providers/execution_provider.dart';
import '../../models/compiler_preset.dart';
import '../output_sheet.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _endpointController;
  late TextEditingController _authKeyController;
  late TextEditingController _authValueController;
  late TextEditingController _bodyTemplateController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;

  String _method = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];
  final _methods = ['GET', 'POST', 'PUT'];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _endpointController = TextEditingController(text: p?.endpoint ?? '');
    _authKeyController = TextEditingController(text: p?.authKey ?? '');
    _authValueController = TextEditingController(text: p?.authValue ?? '');
    _bodyTemplateController = TextEditingController(text: p?.bodyTemplate ?? '{}');
    _stdoutController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrController = TextEditingController(text: p?.stderrPath ?? '');
    _errorController = TextEditingController(text: p?.errorPath ?? '');
    _timeController = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryController = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _method = p.method;
      _authType = p.authType;
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _authKeyController.dispose();
    _authValueController.dispose();
    _bodyTemplateController.dispose();
    _stdoutController.dispose();
    _stderrController.dispose();
    _errorController.dispose();
    _timeController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        endpoint: _endpointController.text.trim(),
        method: _method,
        authType: _authType,
        authKey: _authKeyController.text.trim(),
        authValue: _authValueController.text.trim(),
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplateController.text.trim(),
        stdoutPath: _stdoutController.text.trim(),
        stderrPath: _stderrController.text.trim(),
        errorPath: _errorController.text.trim(),
        executionTimePath: _timeController.text.trim(),
        memoryPath: _memoryController.text.trim(),
      );

      if (widget.preset == null) {
        ref.read(presetProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(presetProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  void _testConnection() {
    if (_formKey.currentState!.validate()) {
      final dummyPreset = CompilerPreset(
        id: 'test',
        name: 'test',
        endpoint: _endpointController.text.trim(),
        method: _method,
        authType: _authType,
        authKey: _authKeyController.text.trim(),
        authValue: _authValueController.text.trim(),
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplateController.text.trim(),
        stdoutPath: _stdoutController.text.trim(),
        stderrPath: _stderrController.text.trim(),
        errorPath: _errorController.text.trim(),
        executionTimePath: _timeController.text.trim(),
        memoryPath: _memoryController.text.trim(),
      );

      ref.read(executionProvider.notifier).executeCode(
        code: "print('Hello from custom API');",
        stdin: '',
        preset: dummyPreset,
        isTestConnection: true,
      );

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const OutputSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _testConnection,
            child: const Text('Test', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFFACC15)),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(controller: _nameController, label: 'Platform Name', isRequired: true),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _endpointController,
              label: 'Endpoint URL',
              isRequired: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _endpointController.text));
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDropdown(label: 'Method', value: _method, items: _methods, onChanged: (v) => setState(() => _method = v!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown(label: 'Auth Type', value: _authType, items: _authTypes, onChanged: (v) => setState(() => _authType = v!))),
              ],
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              if (_authType == 'API-Key Header' || _authType == 'Query Param')
                _buildTextField(controller: _authKeyController, label: 'Auth Key (e.g., X-RapidAPI-Key)'),
              if (_authType != 'None')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildTextField(controller: _authValueController, label: 'Auth Value / Token'),
                ),
            ],
            const Divider(color: Colors.white24, height: 32),
            _buildDynamicList('Headers', _headers, (k, v) => setState(() => _headers.add(MapEntry(k, v)))),
            const SizedBox(height: 16),
            _buildDynamicList('Query Params', _queryParams, (k, v) => setState(() => _queryParams.add(MapEntry(k, v)))),
            const Divider(color: Colors.white24, height: 32),
            const Text('Request Body Template', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTextField(controller: _bodyTemplateController, label: 'JSON Template', maxLines: 5),
            const Divider(color: Colors.white24, height: 32),
            const Text('Response Mapping (Dot notation)', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTextField(controller: _stdoutController, label: 'stdout Path (e.g., data.output)'),
            const SizedBox(height: 16),
            _buildTextField(controller: _stderrController, label: 'stderr Path'),
            const SizedBox(height: 16),
            _buildTextField(controller: _errorController, label: 'error Path'),
            const SizedBox(height: 16),
            _buildTextField(controller: _timeController, label: 'executionTime Path'),
            const SizedBox(height: 16),
            _buildTextField(controller: _memoryController, label: 'memory Path'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isRequired = false,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      validator: isRequired ? (value) => value == null || value.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required void Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1E1E1E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDynamicList(String title, List<MapEntry<String, String>> list, Function(String, String) onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFFFACC15)),
              onPressed: () {
                _showAddDialog(title, onAdd);
              },
            ),
          ],
        ),
        if (list.isEmpty)
          const Text('None', style: TextStyle(color: Colors.white38, fontSize: 13))
        else
          ...list.asMap().entries.map((entry) {
            final idx = entry.key;
            final mapEntry = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(child: Text('${mapEntry.key}: ${mapEntry.value}', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                  GestureDetector(
                    onTap: () => setState(() => list.removeAt(idx)),
                    child: const Icon(Icons.delete, color: Colors.white38, size: 16),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddDialog(String title, Function(String, String) onAdd) {
    String k = '';
    String v = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Add $title', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Key', labelStyle: TextStyle(color: Colors.white54)),
                onChanged: (val) => k = val,
              ),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Value', labelStyle: TextStyle(color: Colors.white54)),
                onChanged: (val) => v = val,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            TextButton(
              onPressed: () {
                if (k.isNotEmpty && v.isNotEmpty) {
                  onAdd(k, v);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Color(0xFFFACC15))),
            ),
          ],
        );
      },
    );
  }
}
