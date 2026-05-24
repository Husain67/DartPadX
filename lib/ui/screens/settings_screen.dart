import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/compiler_service.dart';
import '../../providers/compiler_provider.dart';
import '../../models/compiler_preset.dart';
import '../../utils/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _editPreset(CompilerPreset preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
  }

  void _createNewPreset() {
    final newPreset = CompilerPreset(
      id: const Uuid().v4(),
      name: 'New Preset',
      endpoint: 'https://',
      method: 'POST',
      authType: 'None',
      authValue: '',
      headers: {},
      queryParams: {},
      bodyTemplate: '{"code": "{code}"}',
      stdoutPath: '',
      stderrPath: '',
      errorPath: '',
      executionTimePath: '',
      memoryPath: '',
      isPreloaded: false,
    );
    _editPreset(newPreset);
  }

  @override
  Widget build(BuildContext context) {
    final compState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createNewPreset),
        ],
      ),
      body: ListView.builder(
        itemCount: compState.presets.length,
        itemBuilder: (context, index) {
          final preset = compState.presets[index];
          final isActive = preset.id == compState.activePresetId;

          return ListTile(
            title: Text(preset.name, style: TextStyle(color: isActive ? DartMiniTheme.primary : DartMiniTheme.textMain)),
            subtitle: Text(preset.endpoint, style: const TextStyle(color: DartMiniTheme.textMuted)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!preset.isPreloaded)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                  ),
                // ignore: deprecated_member_use
                Radio<String>(
                  value: preset.id,
                  // ignore: deprecated_member_use
                  groupValue: compState.activePresetId,
                  activeColor: DartMiniTheme.primary,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    if (val != null) ref.read(compilerProvider.notifier).setActivePreset(val);
                  },
                ),
              ],
            ),
            onTap: () => _editPreset(preset),
          );
        },
      ),
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
  late TextEditingController _nameController;
  late TextEditingController _endpointController;
  late TextEditingController _bodyTemplateController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _executionTimeController;
  late TextEditingController _memoryController;
  late TextEditingController _authValueController;

  String _method = 'POST';
  String _authType = 'None';
  final List<String> _methods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _endpointController = TextEditingController(text: widget.preset.endpoint);
    _bodyTemplateController = TextEditingController(text: widget.preset.bodyTemplate);
    _stdoutController = TextEditingController(text: widget.preset.stdoutPath);
    _stderrController = TextEditingController(text: widget.preset.stderrPath);
    _errorController = TextEditingController(text: widget.preset.errorPath);
    _executionTimeController = TextEditingController(text: widget.preset.executionTimePath);
    _memoryController = TextEditingController(text: widget.preset.memoryPath);
    _authValueController = TextEditingController(text: widget.preset.authValue);
    _method = widget.preset.method;
    _authType = widget.preset.authType;

    _headers = widget.preset.headers.entries.toList();
    _queryParams = widget.preset.queryParams.entries.toList();
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameController.text,
      endpoint: _endpointController.text,
      bodyTemplate: _bodyTemplateController.text,
      stdoutPath: _stdoutController.text,
      stderrPath: _stderrController.text,
      errorPath: _errorController.text,
      executionTimePath: _executionTimeController.text,
      memoryPath: _memoryController.text,
      method: _method,
      authType: _authType,
      authValue: _authValueController.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
    );
    ref.read(compilerProvider.notifier).savePreset(updated);
    Navigator.pop(context);
  }

  void _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Testing Connection...')])),
    );

    try {
      final preset = widget.preset.copyWith(
        endpoint: _endpointController.text,
        bodyTemplate: _bodyTemplateController.text,
        stdoutPath: _stdoutController.text,
        stderrPath: _stderrController.text,
        errorPath: _errorController.text,
        executionTimePath: _executionTimeController.text,
        memoryPath: _memoryController.text,
        method: _method,
        authType: _authType,
        authValue: _authValueController.text,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
      );

      final result = await CompilerService.executeCode(
        preset: preset,
        code: "print('Hello from custom API');",
        stdin: "",
        language: "dart"
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Stdout: ${result.stdout}', style: const TextStyle(color: Colors.green)),
                Text('Stderr: ${result.stderr}', style: const TextStyle(color: Colors.redAccent)),
                Text('Error: ${result.error}', style: const TextStyle(color: Colors.red)),
                Text('Time: ${result.executionTime}'),
                Text('Memory: ${result.memory}'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        )
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Test Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        )
      );
    }
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> items, void Function(List<MapEntry<String, String>>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: DartMiniTheme.primary)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('', ''));
                  onChanged(items);
                });
              },
            )
          ],
        ),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> mapEntry = entry.value;
          return Row(
            key: ValueKey('$title-$idx'),
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: mapEntry.key,
                  decoration: const InputDecoration(hintText: 'Key', isDense: true),
                  onChanged: (val) {
                    items[idx] = MapEntry(val, items[idx].value);
                    onChanged(items);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: mapEntry.value,
                  decoration: const InputDecoration(hintText: 'Value', isDense: true),
                  onChanged: (val) {
                    items[idx] = MapEntry(items[idx].key, val);
                    onChanged(items);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    items.removeAt(idx);
                    onChanged(items);
                  });
                },
              )
            ],
          );
        }).toList(),
      ],
    );
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            TextField(controller: _endpointController, decoration: const InputDecoration(labelText: 'Endpoint URL')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _method,
              items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _method = val!),
              decoration: const InputDecoration(labelText: 'HTTP Method'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              items: _authTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (val) => setState(() => _authType = val!),
              decoration: const InputDecoration(labelText: 'Auth Type'),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextField(controller: _authValueController, decoration: const InputDecoration(labelText: 'Auth Value')),
            ],
            const SizedBox(height: 16),
            _buildDynamicTable('Headers', _headers, (newItems) => _headers = newItems),
            const SizedBox(height: 16),
            _buildDynamicTable('Query Params', _queryParams, (newItems) => _queryParams = newItems),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyTemplateController,
              decoration: const InputDecoration(labelText: 'Body Template JSON'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold, color: DartMiniTheme.primary)),
            TextField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'Stdout Path')),
            TextField(controller: _stderrController, decoration: const InputDecoration(labelText: 'Stderr Path')),
            TextField(controller: _errorController, decoration: const InputDecoration(labelText: 'Error Path')),
            TextField(controller: _executionTimeController, decoration: const InputDecoration(labelText: 'Execution Time Path')),
            TextField(controller: _memoryController, decoration: const InputDecoration(labelText: 'Memory Path')),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _testConnection,
                  style: ElevatedButton.styleFrom(backgroundColor: DartMiniTheme.surface, foregroundColor: DartMiniTheme.primary),
                  child: const Text('Test Connection'),
                ),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Preset'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}