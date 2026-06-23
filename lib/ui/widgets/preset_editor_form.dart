import 'package:flutter/material.dart';
import '../../models/compiler_preset.dart';

class PresetEditorForm extends StatefulWidget {
  final CompilerPreset initialPreset;
  final ValueChanged<CompilerPreset> onSave;

  const PresetEditorForm({
    super.key,
    required this.initialPreset,
    required this.onSave,
  });

  @override
  State<PresetEditorForm> createState() => _PresetEditorFormState();
}

class _PresetEditorFormState extends State<PresetEditorForm> {
  late CompilerPreset preset;

  final _nameCtrl = TextEditingController();
  final _endpointCtrl = TextEditingController();
  final _authValueCtrl = TextEditingController();
  final _bodyTemplateCtrl = TextEditingController();

  final _stdoutCtrl = TextEditingController();
  final _stderrCtrl = TextEditingController();
  final _errorCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _memCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    preset = widget.initialPreset.copyWith();

    _nameCtrl.text = preset.name;
    _endpointCtrl.text = preset.endpoint;
    _authValueCtrl.text = preset.authValue;
    _bodyTemplateCtrl.text = preset.bodyTemplate;

    _stdoutCtrl.text = preset.stdoutPath;
    _stderrCtrl.text = preset.stderrPath;
    _errorCtrl.text = preset.errorPath;
    _timeCtrl.text = preset.executionTimePath;
    _memCtrl.text = preset.memoryPath;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Platform Name'),
            onChanged: (v) => preset.name = v,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _endpointCtrl,
                  decoration: const InputDecoration(labelText: 'Endpoint URL'),
                  onChanged: (v) => preset.endpoint = v,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {}, // copy logic
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: preset.method.isNotEmpty ? preset.method : 'POST',
            decoration: const InputDecoration(labelText: 'HTTP Method'),
            items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => preset.method = v ?? 'POST'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: preset.authType.isNotEmpty ? preset.authType : 'None',
            decoration: const InputDecoration(labelText: 'Auth Type'),
            items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => preset.authType = v ?? 'None'),
          ),
          if (preset.authType != 'None') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _authValueCtrl,
              decoration: const InputDecoration(labelText: 'Auth Value'),
              onChanged: (v) => preset.authValue = v,
            ),
          ],
          const SizedBox(height: 24),
          const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
          ...preset.headers.entries.map((e) => _buildKVRow(e.key, e.value, (k, v) {
            setState(() { preset.headers.remove(e.key); preset.headers[k] = v; });
          }, () {
            setState(() => preset.headers.remove(e.key));
          })).toList(),
          TextButton.icon(
            onPressed: () => setState(() => preset.headers['new-header'] = 'value'),
            icon: const Icon(Icons.add),
            label: const Text('Add Header'),
          ),

          const SizedBox(height: 24),
          const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
          const Text('Use placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.white54)),
          TextField(
            controller: _bodyTemplateCtrl,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'e.g. {"script": "{code}"}'),
            onChanged: (v) => preset.bodyTemplate = v,
          ),

          const SizedBox(height: 24),
          const Text('Response Mapping (Dot notation)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
          TextField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path'), onChanged: (v) => preset.stdoutPath = v),
          TextField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path'), onChanged: (v) => preset.stderrPath = v),
          TextField(controller: _errorCtrl, decoration: const InputDecoration(labelText: 'error path'), onChanged: (v) => preset.errorPath = v),
          TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'executionTime path'), onChanged: (v) => preset.executionTimePath = v),
          TextField(controller: _memCtrl, decoration: const InputDecoration(labelText: 'memory path'), onChanged: (v) => preset.memoryPath = v),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black),
              onPressed: () => widget.onSave(preset),
              child: const Text('Save Preset'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildKVRow(String k, String v, Function(String, String) onChange, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(child: TextFormField(initialValue: k, onChanged: (val) => onChange(val, v))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(initialValue: v, onChanged: (val) => onChange(k, val))),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }
}
