import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_presets_provider.dart';
import '../utils/theme.dart';

class CompilerPresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  final bool isNew;

  const CompilerPresetEditor({
    super.key,
    required this.preset,
    this.isNew = false,
  });

  @override
  ConsumerState<CompilerPresetEditor> createState() => _CompilerPresetEditorState();
}

class _CompilerPresetEditorState extends ConsumerState<CompilerPresetEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _url;
  late String _method;
  late String _authType;
  late String _authValue;
  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final _methods = ['POST', 'GET', 'PUT'];
  final _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  @override
  void initState() {
    super.initState();
    _name = widget.preset.name;
    _url = widget.preset.url;
    _method = widget.preset.method;
    _authType = widget.preset.authType;
    _authValue = widget.preset.authValue;
    _bodyTemplate = widget.preset.bodyTemplate;
    _stdoutPath = widget.preset.stdoutPath;
    _stderrPath = widget.preset.stderrPath;
    _errorPath = widget.preset.errorPath;
    _executionTimePath = widget.preset.executionTimePath;
    _memoryPath = widget.preset.memoryPath;

    _headers = widget.preset.headers.entries.toList();
    _queryParams = widget.preset.queryParams.entries.toList();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedPreset = CompilerPreset(
        id: widget.preset.id,
        name: _name,
        url: _url,
        method: _method,
        authType: _authType,
        authValue: _authValue,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );

      if (widget.isNew) {
        ref.read(compilerPresetsProvider.notifier).addPreset(updatedPreset);
      } else {
        ref.read(compilerPresetsProvider.notifier).updatePreset(updatedPreset);
      }

      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Preset saved');
    }
  }

  void _duplicate() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final duplicatedPreset = CompilerPreset(
        id: const Uuid().v4(),
        name: '\$_name (Copy)',
        url: _url,
        method: _method,
        authType: _authType,
        authValue: _authValue,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );

      ref.read(compilerPresetsProvider.notifier).addPreset(duplicatedPreset);
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Preset duplicated');
    }
  }

  void _delete() {
    ref.read(compilerPresetsProvider.notifier).deletePreset(widget.preset.id);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: 'Preset deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Preset' : 'Edit Preset'),
        actions: [
          if (!widget.isNew)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Duplicate',
              onPressed: _duplicate,
            ),
          if (!widget.isNew)
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorRed),
              tooltip: 'Delete',
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.accentYellow),
            onPressed: _save,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.mainBackgroundDecoration,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('General Settings'),
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Platform Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _url,
                decoration: const InputDecoration(labelText: 'Endpoint URL'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _url = val!,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _method,
                      items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => _method = val!),
                      decoration: const InputDecoration(labelText: 'HTTP Method'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _authType,
                      items: _authTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (val) => setState(() => _authType = val!),
                      decoration: const InputDecoration(labelText: 'Auth Type'),
                    ),
                  ),
                ],
              ),
              if (_authType != 'None') ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _authValue,
                  decoration: InputDecoration(labelText: 'Auth Value (\$_authType)'),
                  onSaved: (val) => _authValue = val ?? '',
                ),
              ],

              const SizedBox(height: 24),
              _buildSectionTitle('Headers'),
              _buildKeyValueList(_headers, 'Header'),

              const SizedBox(height: 24),
              _buildSectionTitle('Query Params'),
              _buildKeyValueList(_queryParams, 'Param'),

              const SizedBox(height: 24),
              _buildSectionTitle('Request Body Template'),
              const Text(
                'Use {code}, {stdin}, {language} as placeholders. It will be sent as a string payload (usually JSON).',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _bodyTemplate,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: '{"language": "dart", "code": {code}}',
                ),
                onSaved: (val) => _bodyTemplate = val ?? '',
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Response Mapping (Dot Notation)'),
              const Text(
                'Path to extract from JSON response. E.g., data.output',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _buildMappingField('Stdout Path', _stdoutPath, (val) => _stdoutPath = val),
              _buildMappingField('Stderr Path', _stderrPath, (val) => _stderrPath = val),
              _buildMappingField('Error Path', _errorPath, (val) => _errorPath = val),
              _buildMappingField('Execution Time Path', _executionTimePath, (val) => _executionTimePath = val),
              _buildMappingField('Memory Path', _memoryPath, (val) => _memoryPath = val),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(color: AppTheme.accentYellow, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMappingField(String label, String initialVal, Function(String) onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: initialVal,
        decoration: InputDecoration(labelText: label),
        onSaved: (val) => onSaved(val ?? ''),
      ),
    );
  }

  Widget _buildKeyValueList(List<MapEntry<String, String>> list, String itemType) {
    return Column(
      children: [
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          var kv = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: kv.key,
                    decoration: const InputDecoration(hintText: 'Key', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    onChanged: (val) => list[idx] = MapEntry(val, list[idx].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: kv.value,
                    decoration: const InputDecoration(hintText: 'Value', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    onChanged: (val) => list[idx] = MapEntry(list[idx].key, val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: AppTheme.errorRed),
                  onPressed: () {
                    setState(() => list.removeAt(idx));
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            setState(() => list.add(const MapEntry('', '')));
          },
          icon: const Icon(Icons.add),
          label: Text('Add \$itemType'),
        ),
      ],
    );
  }
}
