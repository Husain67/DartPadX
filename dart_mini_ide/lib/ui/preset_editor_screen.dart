import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../models.dart';
import '../theme.dart';
import '../api_service.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  final bool isNew;

  const PresetEditorScreen({super.key, required this.preset, this.isNew = false});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  late String _httpMethod;
  late String _authType;
  late Map<String, String> _headers;
  late Map<String, String> _queryParams;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _bodyCtrl = TextEditingController(text: widget.preset.bodyTemplate);
    _stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorCtrl = TextEditingController(text: widget.preset.errorPath);
    _timeCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memoryCtrl = TextEditingController(text: widget.preset.memoryPath);

    _httpMethod = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _headers = Map.from(widget.preset.headers);
    _queryParams = Map.from(widget.preset.queryParams);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutCtrl.dispose();
    _stderrCtrl.dispose();
    _errorCtrl.dispose();
    _timeCtrl.dispose();
    _memoryCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updatedPreset = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: _headers,
      queryParams: _queryParams,
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memoryCtrl.text,
    );

    if (widget.isNew) {
      ref.read(settingsProvider.notifier).addPreset(updatedPreset);
    } else {
      updatedPreset.id = widget.preset.id; // ensure ID consistency
      ref.read(settingsProvider.notifier).updatePreset(updatedPreset);
    }
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    final testPreset = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: _headers,
      queryParams: _queryParams,
      bodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memoryCtrl.text,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
    );

    try {
      final apiService = ApiService();
      final result = await apiService.executeCustom(testPreset, "print('Hello from custom API');", "");
      if (context.mounted) Navigator.pop(context); // close loader

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.backgroundLight,
            title: const Text('Test Successful', style: TextStyle(color: Colors.green)),
            content: Text('Stdout: \${result.stdout}\\nStderr: \${result.stderr}\\nTime: \${result.executionTime}',
                style: const TextStyle(color: AppTheme.textPrimary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close loader
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.backgroundLight,
            title: const Text('Test Failed', style: TextStyle(color: Colors.red)),
            content: Text(e.toString(), style: const TextStyle(color: AppTheme.textPrimary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildMapEditor(String title, Map<String, String> map) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
              onPressed: () {
                setState(() {
                  map['New Key \${map.length}'] = 'Value';
                });
              },
            )
          ],
        ),
        ...map.entries.map((e) {
          final keyCtrl = TextEditingController(text: e.key);
          final valCtrl = TextEditingController(text: e.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: keyCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                    onChanged: (v) {
                       final val = map.remove(e.key);
                       map[v] = val ?? '';
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: valCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                    onChanged: (v) => map[e.key] = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    setState(() {
                      map.remove(e.key);
                    });
                  },
                )
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow, color: AppTheme.primaryAccent), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save), onPressed: _save, tooltip: 'Save'),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField('Platform Name', _nameCtrl),
            _buildTextField('Endpoint URL', _urlCtrl),

            DropdownButtonFormField<String>(
              value: _httpMethod,
              dropdownColor: AppTheme.backgroundLight,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _httpMethod = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _authType,
              dropdownColor: AppTheme.backgroundLight,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            const SizedBox(height: 24),

            _buildMapEditor('Headers', _headers),
            _buildMapEditor('Query Params', _queryParams),

            const Text('Request Body Template (JSON)', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTextField('', _bodyCtrl, maxLines: 8),

            const SizedBox(height: 8),
            const Text('Response Mappings (JSON dot notation)', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            _buildTextField('stdout path (e.g. data.output)', _stdoutCtrl),
            _buildTextField('stderr path', _stderrCtrl),
            _buildTextField('error path', _errorCtrl),
            _buildTextField('executionTime path', _timeCtrl),
            _buildTextField('memory path', _memoryCtrl),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
