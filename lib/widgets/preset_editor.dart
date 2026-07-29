import 'package:flutter/material.dart';
import '../models/compiler_preset.dart';
import '../theme.dart';
import '../services/compiler_api.dart';
import '../widgets/output_bottom_sheet.dart';
import 'dart:convert';

class PresetEditor extends StatefulWidget {
  final CompilerPreset initialPreset;
  final Function(CompilerPreset) onSave;

  const PresetEditor({super.key, required this.initialPreset, required this.onSave});

  @override
  State<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends State<PresetEditor> {
  late CompilerPreset _preset;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset.copyWith(); // Deep copy
  }

  Future<void> _testConnection() async {
    _formKey.currentState?.save(); // sync form data first

    showOutputSheet(context, ExecutionResult(stdout: '', stderr: '', error: '', executionTime: '', memory: ''), isLoading: true);

    final testCode = "void main() { print('Hello from custom API'); }";
    final result = await CompilerApi.executeDart(testCode, preset: _preset);

    if (mounted) {
       Navigator.pop(context); // close loader
       showOutputSheet(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gradientEnd,
      appBar: AppBar(
        title: const Text('Edit Compiler Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                widget.onSave(_preset);
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _preset.name,
                decoration: const InputDecoration(labelText: 'Platform Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _preset.name = v!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _preset.endpointUrl,
                decoration: const InputDecoration(labelText: 'Endpoint URL'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _preset.endpointUrl = v!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _preset.httpMethod,
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _preset.httpMethod = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _preset.authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _preset.authType = v!),
              ),
              const SizedBox(height: 16),

              // Headers UI
              const Text('Dynamic Headers (JSON format)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: jsonEncode(_preset.headers),
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"Content-Type": "application/json"}'),
                onSaved: (v) {
                  try {
                    final map = jsonDecode(v ?? '{}') as Map;
                    _preset.headers = map.map((key, value) => MapEntry(key.toString(), value.toString()));
                  } catch (e) {
                     // ignore format error for brevity
                  }
                },
              ),
              const SizedBox(height: 16),

              // Query Params UI
              const Text('Dynamic Query Params (JSON format)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: jsonEncode(_preset.queryParams),
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"api_key": "YOUR_KEY"}'),
                onSaved: (v) {
                  try {
                    final map = jsonDecode(v ?? '{}') as Map;
                    _preset.queryParams = map.map((key, value) => MapEntry(key.toString(), value.toString()));
                  } catch (e) {
                     // ignore format error
                  }
                },
              ),
              const SizedBox(height: 16),

              const Text('Request Body Template (Use {code}, {stdin}, {language})', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _preset.requestBodyTemplate,
                maxLines: 5,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onSaved: (v) => _preset.requestBodyTemplate = v ?? '',
              ),
              const SizedBox(height: 16),
              const Text('Response Mapping (JSON dot path)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: _preset.stdoutPath,
                decoration: const InputDecoration(labelText: 'STDOUT Path'),
                onSaved: (v) => _preset.stdoutPath = v ?? '',
              ),
              TextFormField(
                initialValue: _preset.stderrPath,
                decoration: const InputDecoration(labelText: 'STDERR Path'),
                onSaved: (v) => _preset.stderrPath = v ?? '',
              ),
              TextFormField(
                initialValue: _preset.executionTimePath,
                decoration: const InputDecoration(labelText: 'Execution Time Path'),
                onSaved: (v) => _preset.executionTimePath = v ?? '',
              ),
              const SizedBox(height: 24),

              Center(
                 child: ElevatedButton.icon(
                    onPressed: _testConnection,
                    icon: const Icon(Icons.bolt, color: Colors.black),
                    label: const Text('Test Connection', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                 ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
