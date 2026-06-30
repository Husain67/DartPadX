import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/preset_model.dart';
import '../providers/preset_provider.dart';
import '../services/compiler_service.dart';
import '../theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final PresetModel preset;

  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _bodyTemplateCtrl;

  String _method = 'POST';
  String _authType = 'None';

  late Map<String, String> _headers;
  late Map<String, String> _queryParams;
  late Map<String, String> _responseMappings;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.url);
    _bodyTemplateCtrl = TextEditingController(text: widget.preset.bodyTemplate);
    _method = widget.preset.method;
    _authType = widget.preset.authType;
    _headers = Map.from(widget.preset.headers);
    _queryParams = Map.from(widget.preset.queryParams);
    _responseMappings = Map.from(widget.preset.responseMappings);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final newPreset = widget.preset.copyWith(
      name: _nameCtrl.text,
      url: _urlCtrl.text,
      method: _method,
      authType: _authType,
      headers: _headers,
      queryParams: _queryParams,
      bodyTemplate: _bodyTemplateCtrl.text,
      responseMappings: _responseMappings,
    );

    if (widget.preset.isInBox) {
       ref.read(presetProvider.notifier).updatePreset(newPreset);
    } else {
       ref.read(presetProvider.notifier).addPreset(newPreset);
    }
    Navigator.pop(context);
  }

  void _duplicate() {
    final duplicated = widget.preset.copyWith(name: '${_nameCtrl.text} Copy');
    ref.read(presetProvider.notifier).addPreset(duplicated);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset duplicated");
  }

  void _testConnection() async {
    final testPreset = widget.preset.copyWith(
      name: _nameCtrl.text,
      url: _urlCtrl.text,
      method: _method,
      authType: _authType,
      headers: _headers,
      queryParams: _queryParams,
      bodyTemplate: _bodyTemplateCtrl.text,
      responseMappings: _responseMappings,
    );

    // Create a temporary mock state to pass to the CompilerService
    final mockState = PresetState(
      presets: [testPreset],
      activePresetId: testPreset.id,
      useOneCompiler: false,
    );

    Fluttertoast.showToast(msg: "Testing connection...");
    final result = await CompilerService.executeCode("print('Hello from custom API');", mockState);

    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Text('STDOUT:\n${result['stdout']}\n\nSTDERR:\n${result['stderr']}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.green),
            tooltip: 'Test Connection',
            onPressed: _testConnection,
          ),
          if (widget.preset.isInBox) ...[
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.blueAccent),
              tooltip: 'Duplicate',
              onPressed: _duplicate,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Delete',
              onPressed: () {
                ref.read(presetProvider.notifier).deletePreset(widget.preset.id);
                Navigator.pop(context);
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryAccent),
            tooltip: 'Save',
            onPressed: _save,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Platform Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            const SizedBox(height: 24),
            const Text('Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
            const Text('Use placeholders: {code}, {language}, {stdin}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyTemplateCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"script": "{code}"}',
              ),
              maxLines: 5,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 24),
            const Text('Response Mappings (dot notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
            _buildMappingField('stdout', 'e.g., output.stdout'),
            _buildMappingField('stderr', 'e.g., output.error'),
            _buildMappingField('error', 'e.g., error'),
            _buildMappingField('executionTime', 'e.g., cpuTime'),
            _buildMappingField('memory', 'e.g., memory'),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingField(String key, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        initialValue: _responseMappings[key] ?? '',
        decoration: InputDecoration(labelText: key, hintText: hint),
        onChanged: (val) {
          _responseMappings[key] = val;
        },
      ),
    );
  }
}
