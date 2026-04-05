import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/compiler_preset.dart';
import '../../providers/settings_provider.dart';

class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditor({super.key, this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _url, _method, _authType, _authValue, _bodyTemplate;
  late Map<String, String> _resultPaths;

  @override
  void initState() {
    super.initState();
    _name = widget.preset?.name ?? '';
    _url = widget.preset?.url ?? '';
    _method = widget.preset?.method ?? 'POST';
    _authType = widget.preset?.authType ?? 'None';
    _authValue = widget.preset?.authValue ?? '';
    _bodyTemplate = widget.preset?.bodyTemplate ?? '{}';
    _resultPaths = widget.preset?.resultPaths != null ? Map.from(widget.preset!.resultPaths) : {
      'stdout': '', 'stderr': '', 'error': '', 'executionTime': '', 'memory': ''
    };
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _name,
        url: _url,
        method: _method,
        authType: _authType,
        authValue: _authValue,
        headers: widget.preset?.headers ?? {},
        queryParams: widget.preset?.queryParams ?? {},
        bodyTemplate: _bodyTemplate,
        resultPaths: _resultPaths,
      );
      ref.read(settingsProvider.notifier).addOrUpdatePreset(newPreset);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.preset != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                ref.read(settingsProvider.notifier).deletePreset(widget.preset!.id);
                Navigator.pop(context);
              },
            ),
          IconButton(icon: const Icon(Icons.save, color: Color(0xFFFACC15)), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _name = v!,
            ),
            TextFormField(
              initialValue: _url,
              decoration: const InputDecoration(labelText: 'URL Endpoint', labelStyle: TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _url = v!,
            ),
            DropdownButtonFormField<String>(
              value: _method,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Method', labelStyle: TextStyle(color: Colors.grey)),
              items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
              onSaved: (v) => _method = v!,
            ),
            DropdownButtonFormField<String>(
              value: _authType,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.grey)),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
              onSaved: (v) => _authType = v!,
            ),
            if (_authType != 'None')
              TextFormField(
                initialValue: _authValue,
                decoration: const InputDecoration(labelText: 'Auth Value', labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
                onSaved: (v) => _authValue = v ?? '',
              ),
            const SizedBox(height: 16),
            const Text('Body Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: _bodyTemplate,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '{ "code": {code} }', hintStyle: TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              onSaved: (v) => _bodyTemplate = v ?? '',
            ),
            const SizedBox(height: 16),
            const Text('Result Paths (dot notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ..._resultPaths.keys.map((key) => TextFormField(
              initialValue: _resultPaths[key],
              decoration: InputDecoration(labelText: key, labelStyle: const TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white),
              onSaved: (v) => _resultPaths[key] = v ?? '',
            )),
          ],
        ),
      ),
    );
  }
}
