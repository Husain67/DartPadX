import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import '../../providers/compiler_provider.dart';
import '../editor/output_sheet.dart';

class EditPresetScreen extends ConsumerStatefulWidget {
  final String? presetId;

  const EditPresetScreen({super.key, this.presetId});

  @override
  ConsumerState<EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<EditPresetScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _endpointController;
  late TextEditingController _authValueController;
  late TextEditingController _requestBodyController;
  late TextEditingController _stdoutPathController;
  late TextEditingController _stderrPathController;
  late TextEditingController _errorPathController;
  late TextEditingController _timePathController;
  late TextEditingController _memoryPathController;

  String _method = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final preset = widget.presetId != null
        ? ref.read(settingsProvider).presets.firstWhere((p) => p.id == widget.presetId)
        : null;

    _nameController = TextEditingController(text: preset?.name ?? '');
    _endpointController = TextEditingController(text: preset?.endpoint ?? '');
    _authValueController = TextEditingController(text: preset?.authValue ?? '');
    _requestBodyController = TextEditingController(text: preset?.requestBodyTemplate ?? '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "code": {code}\n}');
    _stdoutPathController = TextEditingController(text: preset?.stdoutPath ?? 'stdout');
    _stderrPathController = TextEditingController(text: preset?.stderrPath ?? 'stderr');
    _errorPathController = TextEditingController(text: preset?.errorPath ?? 'error');
    _timePathController = TextEditingController(text: preset?.executionTimePath ?? 'time');
    _memoryPathController = TextEditingController(text: preset?.memoryPath ?? 'memory');

    if (preset != null) {
      _method = preset.method;
      _authType = preset.authType;
      _headers = preset.headers.entries.toList();
      _queryParams = preset.queryParams.entries.toList();
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.presetId ?? const Uuid().v4(),
        name: _nameController.text,
        endpoint: _endpointController.text,
        method: _method,
        authType: _authType,
        authValue: _authValueController.text,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _requestBodyController.text,
        stdoutPath: _stdoutPathController.text,
        stderrPath: _stderrPathController.text,
        errorPath: _errorPathController.text,
        executionTimePath: _timePathController.text,
        memoryPath: _memoryPathController.text,
      );

      if (widget.presetId == null) {
        ref.read(settingsProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  void _testConnection() async {
    if (_formKey.currentState!.validate()) {
      final tempPreset = CompilerPreset(
        id: 'test',
        name: 'Test',
        endpoint: _endpointController.text,
        method: _method,
        authType: _authType,
        authValue: _authValueController.text,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        requestBodyTemplate: _requestBodyController.text,
        stdoutPath: _stdoutPathController.text,
        stderrPath: _stderrPathController.text,
        errorPath: _errorPathController.text,
        executionTimePath: _timePathController.text,
        memoryPath: _memoryPathController.text,
      );

      ref.read(compilerProvider.notifier).runCode("void main() { print('Hello from custom API'); }", tempPreset);

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        enableDrag: true,
        builder: (context) => const OutputSheet(),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('', ''));
                  onChanged(items);
                });
              },
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Row(
              key: ValueKey('$title-$index'),
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: items[index].key,
                    decoration: const InputDecoration(hintText: 'Key', isDense: true),
                    onChanged: (v) {
                      items[index] = MapEntry(v, items[index].value);
                      onChanged(items);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: items[index].value,
                    decoration: const InputDecoration(hintText: 'Value', isDense: true),
                    onChanged: (v) {
                      items[index] = MapEntry(items[index].key, v);
                      onChanged(items);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      items.removeAt(index);
                      onChanged(items);
                    });
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Text(widget.presetId == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_circle_filled, color: Color(0xFFFACC15)), tooltip: 'Test Connection', onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endpointController,
              decoration: const InputDecoration(
                labelText: 'Endpoint URL',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.copy),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _method, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            const SizedBox(height: 16),
            if (_authType != 'None')
              TextFormField(
                controller: _authValueController,
                decoration: const InputDecoration(labelText: 'Auth Value', border: OutlineInputBorder()),
              ),
            const SizedBox(height: 16),
            _buildDynamicTable('Headers', _headers, (newHeaders) => _headers = newHeaders),
            const SizedBox(height: 16),
            _buildDynamicTable('Query Parameters', _queryParams, (newParams) => _queryParams = newParams),
            const SizedBox(height: 16),
            const Text('Request Body Template (Use {code} for source)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _requestBodyController,
              maxLines: 6,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{\n  "code": {code}\n}'),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping Paths (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _stdoutPathController, decoration: const InputDecoration(labelText: 'stdout path', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _stderrPathController, decoration: const InputDecoration(labelText: 'stderr path', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _errorPathController, decoration: const InputDecoration(labelText: 'error path', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _timePathController, decoration: const InputDecoration(labelText: 'time path', border: OutlineInputBorder()))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
