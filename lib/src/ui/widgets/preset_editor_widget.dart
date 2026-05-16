import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/compiler_preset.dart';
import '../../providers/preset_provider.dart';
import '../../providers/execution_provider.dart';

class PresetEditorWidget extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const PresetEditorWidget({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorWidget> createState() => _PresetEditorWidgetState();
}

class _PresetEditorWidgetState extends ConsumerState<PresetEditorWidget> {
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _executionTimePathCtrl;
  late TextEditingController _memoryPathCtrl;

  String _httpMethod = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _initValues(widget.preset);
  }

  @override
  void didUpdateWidget(covariant PresetEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset.id != widget.preset.id || oldWidget.preset.isPreloaded != widget.preset.isPreloaded) {
      _initValues(widget.preset);
    }
  }

  void _initValues(CompilerPreset preset) {
    _nameCtrl = TextEditingController(text: preset.name);
    _endpointCtrl = TextEditingController(text: preset.endpointUrl);
    _authValueCtrl = TextEditingController(text: preset.authValue);
    _bodyTemplateCtrl = TextEditingController(text: preset.bodyTemplate);
    _stdoutPathCtrl = TextEditingController(text: preset.stdoutPath);
    _stderrPathCtrl = TextEditingController(text: preset.stderrPath);
    _errorPathCtrl = TextEditingController(text: preset.errorPath);
    _executionTimePathCtrl = TextEditingController(text: preset.executionTimePath);
    _memoryPathCtrl = TextEditingController(text: preset.memoryPath);

    _httpMethod = preset.httpMethod;
    if (_httpMethod.isEmpty) _httpMethod = 'POST';
    _authType = preset.authType;
    if (_authType.isEmpty) _authType = 'None';

    _headers = preset.headers.entries.toList();
    _queryParams = preset.queryParams.entries.toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _endpointCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _executionTimePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (widget.preset.isPreloaded) return;

    final updatedPreset = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _endpointCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      authValue: _authValueCtrl.text,
      bodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _executionTimePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
    );

    ref.read(presetProvider.notifier).updatePreset(updatedPreset);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset saved')));
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> data, VoidCallback onAdd, Function(int) onRemove, Function(int, String, String) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!widget.preset.isPreloaded)
              IconButton(icon: const Icon(Icons.add), onPressed: onAdd),
          ],
        ),
        ...data.asMap().entries.map((entry) {
          int index = entry.key;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: entry.value.key,
                  decoration: const InputDecoration(labelText: 'Key', isDense: true),
                  readOnly: widget.preset.isPreloaded,
                  onChanged: (val) => onChange(index, val, entry.value.value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: entry.value.value,
                  decoration: const InputDecoration(labelText: 'Value', isDense: true),
                  readOnly: widget.preset.isPreloaded,
                  onChanged: (val) => onChange(index, entry.value.key, val),
                ),
              ),
              if (!widget.preset.isPreloaded)
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => onRemove(index)),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool readOnly = widget.preset.isPreloaded;

    return Form(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (readOnly)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.red.withValues(alpha: 0.1),
              child: const Text('This is a pre-loaded default preset. It cannot be edited. Duplicate it to make changes.', style: TextStyle(color: Colors.redAccent)),
            ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
                  readOnly: readOnly,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => ref.read(presetProvider.notifier).duplicatePreset(widget.preset.id),
                icon: const Icon(Icons.copy),
                label: const Text('Duplicate'),
              ),
              if (!readOnly) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(presetProvider.notifier).deletePreset(widget.preset.id);
                  },
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _endpointCtrl,
            decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
            readOnly: readOnly,
            maxLines: null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _httpMethod,
                  decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                  items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: readOnly ? null : (v) => setState(() => _httpMethod = v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _authType,
                  decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                  items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: readOnly ? null : (v) => setState(() => _authType = v!),
                ),
              ),
            ],
          ),
          if (_authType != 'None') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _authValueCtrl,
              decoration: const InputDecoration(labelText: 'Auth Value (Token/Key)', border: OutlineInputBorder()),
              readOnly: readOnly,
            ),
          ],
          const Divider(height: 32),
          _buildDynamicTable(
            'HTTP Headers',
            _headers,
            () => setState(() => _headers.add(const MapEntry('', ''))),
            (i) => setState(() => _headers.removeAt(i)),
            (i, k, v) => setState(() => _headers[i] = MapEntry(k, v)),
          ),
          const Divider(height: 32),
          _buildDynamicTable(
            'Query Params',
            _queryParams,
            () => setState(() => _queryParams.add(const MapEntry('', ''))),
            (i) => setState(() => _queryParams.removeAt(i)),
            (i, k, v) => setState(() => _queryParams[i] = MapEntry(k, v)),
          ),
          const Divider(height: 32),
          const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bodyTemplateCtrl,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace'),
            readOnly: readOnly,
          ),
          const Divider(height: 32),
          const Text('Response Mapping Paths (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              TextFormField(controller: _stdoutPathCtrl, decoration: const InputDecoration(labelText: 'stdout Path'), readOnly: readOnly),
              TextFormField(controller: _stderrPathCtrl, decoration: const InputDecoration(labelText: 'stderr Path'), readOnly: readOnly),
              TextFormField(controller: _errorPathCtrl, decoration: const InputDecoration(labelText: 'error Path'), readOnly: readOnly),
              TextFormField(controller: _executionTimePathCtrl, decoration: const InputDecoration(labelText: 'executionTime Path'), readOnly: readOnly),
              TextFormField(controller: _memoryPathCtrl, decoration: const InputDecoration(labelText: 'memory Path'), readOnly: readOnly),
            ],
          ),
          const SizedBox(height: 24),
          if (!readOnly)
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save Preset'),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(

            onPressed: () async {
              // Implementation of Test Connection
              if (widget.preset.endpointUrl.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Endpoint URL is empty')));
                 return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text("Testing connection..."),
                    ],
                  ),
                ),
              );

              final tempPreset = widget.preset.copyWith(
                endpointUrl: _endpointCtrl.text,
                httpMethod: _httpMethod,
                authType: _authType,
                authValue: _authValueCtrl.text,
                headers: Map.fromEntries(_headers),
                queryParams: Map.fromEntries(_queryParams),
                bodyTemplate: _bodyTemplateCtrl.text,
                stdoutPath: _stdoutPathCtrl.text,
                stderrPath: _stderrPathCtrl.text,
                errorPath: _errorPathCtrl.text,
              );

              // We need to access executionNotifier bypassing normal state flow for a one-off test
              // We'll create a temporary notifier to test with this specific preset
              final tempNotifier = ExecutionNotifier(tempPreset);
              await tempNotifier.executeCode("void main() { print('Hello from custom API'); }", "");

              if (!mounted) return;
              Navigator.pop(context); // close dialog

              final state = tempNotifier.currentState;

              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Test Results'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('stdout:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        Text(state.stdout.isEmpty ? 'None' : state.stdout),
                        const SizedBox(height: 8),
                        Text('stderr/error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        Text(state.stderr.isEmpty ? 'None' : state.stderr),
                        const SizedBox(height: 8),
                        Text('Time: \${state.executionTime}', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },

            icon: const Icon(Icons.bug_report),
            label: const Text('Test Connection'),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColorDark),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
