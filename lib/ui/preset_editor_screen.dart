import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/compiler_preset.dart';
import '../providers/preset_provider.dart';
import '../theme/app_theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  late String _name;
  late String _endpointUrl;
  late String _method;
  late String _authType;
  late String _authValue;
  late Map<String, String> _headers;
  late Map<String, String> _queryParams;
  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _timePath;
  late String _memoryPath;

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) {
      _id = widget.preset!.id;
      _name = widget.preset!.name;
      _endpointUrl = widget.preset!.endpointUrl;
      _method = widget.preset!.method;
      _authType = widget.preset!.authType;
      _authValue = widget.preset!.authValue;
      _headers = Map.from(widget.preset!.headers);
      _queryParams = Map.from(widget.preset!.queryParams);
      _bodyTemplate = widget.preset!.bodyTemplate;
      _stdoutPath = widget.preset!.stdoutPath;
      _stderrPath = widget.preset!.stderrPath;
      _errorPath = widget.preset!.errorPath;
      _timePath = widget.preset!.timePath;
      _memoryPath = widget.preset!.memoryPath;
    } else {
      _id = const Uuid().v4();
      _name = 'New Preset';
      _endpointUrl = '';
      _method = 'POST';
      _authType = 'None';
      _authValue = '';
      _headers = {};
      _queryParams = {};
      _bodyTemplate = '{}';
      _stdoutPath = '';
      _stderrPath = '';
      _errorPath = '';
      _timePath = '';
      _memoryPath = '';
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: _id,
        name: _name,
        endpointUrl: _endpointUrl,
        method: _method,
        authType: _authType,
        authValue: _authValue,
        headers: _headers,
        queryParams: _queryParams,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        timePath: _timePath,
        memoryPath: _memoryPath,
      );

      if (widget.preset != null) {
        ref.read(presetProvider.notifier).updatePreset(newPreset);
      } else {
        ref.read(presetProvider.notifier).addPreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Text(widget.preset != null ? 'Edit API' : 'New API'),
        backgroundColor: AppTheme.appBarColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryAccent),
            onPressed: _save,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Platform Name (e.g. HackerEarth)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _name = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _endpointUrl,
                decoration: const InputDecoration(labelText: 'Endpoint URL'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _endpointUrl = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _method = val!),
                onSaved: (val) => _method = val!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _authType = val!),
                onSaved: (val) => _authType = val!,
              ),
              if (_authType != 'None') ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _authValue,
                  decoration: const InputDecoration(
                    labelText: 'Auth Value',
                    hintText: 'e.g. key:value or token',
                  ),
                  onSaved: (val) => _authValue = val ?? '',
                ),
              ],
              const SizedBox(height: 24),
              const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Use {code}, {stdin}, {language} as placeholders.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _bodyTemplate,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black45,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                onSaved: (val) => _bodyTemplate = val ?? '',
              ),
              const SizedBox(height: 24),
              const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              _buildPathField('stdout Path', _stdoutPath, (val) => _stdoutPath = val),
              _buildPathField('stderr Path', _stderrPath, (val) => _stderrPath = val),
              _buildPathField('Error Path', _errorPath, (val) => _errorPath = val),
              _buildPathField('Execution Time Path', _timePath, (val) => _timePath = val),
              _buildPathField('Memory Path', _memoryPath, (val) => _memoryPath = val),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPathField(String label, String initialVal, Function(String) onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: initialVal,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'e.g. data.output',
          isDense: true,
        ),
        onSaved: (val) => onSaved(val ?? ''),
      ),
    );
  }
}
