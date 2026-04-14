
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/preset_provider.dart';
import '../../models/compiler_preset.dart';
import '../../services/execution_service.dart';
import '../../utils/constants.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  late String _platformName;
  late String _endpointUrl;
  late String _httpMethod;
  late String _authType;
  late List<MapEntry<String, String>> _headers;
  late List<MapEntry<String, String>> _queryParams;
  late TextEditingController _bodyController;
  late ResponseMapping _responseMapping;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.preset ?? CompilerPreset(platformName: '', endpointUrl: '');
    _id = p.id;
    _platformName = p.platformName;
    _endpointUrl = p.endpointUrl;
    _httpMethod = p.httpMethod;
    _authType = p.authType;
    _headers = p.headers.entries.toList();
    _queryParams = p.queryParams.entries.toList();
    _bodyController = TextEditingController(text: p.requestBodyTemplate);
    _responseMapping = p.responseMapping.copyWith();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: _id,
        platformName: _platformName,
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        authType: _authType,
        headers: Map.fromEntries(_headers.where((e) => e.key.isNotEmpty)),
        queryParams: Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty)),
        requestBodyTemplate: _bodyController.text,
        responseMapping: _responseMapping,
      );

      if (widget.preset == null) {
        ref.read(presetProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(presetProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Preset Saved');
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);
    _formKey.currentState!.save();

    final tempPreset = CompilerPreset(
      id: _id,
      platformName: _platformName,
      endpointUrl: _endpointUrl,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: Map.fromEntries(_headers.where((e) => e.key.isNotEmpty)),
      queryParams: Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty)),
      requestBodyTemplate: _bodyController.text,
      responseMapping: _responseMapping,
    );

    final result = await ExecutionService.executeCustomPreset("print('Hello from custom API');", tempPreset);

    setState(() => _isTesting = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stdout:', style: TextStyle(color: AppColors.successGreen)),
              Text(result.stdout.isEmpty ? '(empty)' : result.stdout),
              const SizedBox(height: 8),
              Text('Stderr:', style: TextStyle(color: AppColors.errorRed)),
              Text(result.stderr.isEmpty ? '(empty)' : result.stderr),
              const SizedBox(height: 8),
              Text('Error:', style: TextStyle(color: AppColors.errorRed)),
              Text(result.error.isEmpty ? '(empty)' : result.error),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _platformName,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _platformName = v!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _endpointUrl,
                    decoration: const InputDecoration(labelText: 'Endpoint URL'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => _endpointUrl = v!,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _endpointUrl));
                    Fluttertoast.showToast(msg: 'URL copied');
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _httpMethod,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _httpMethod = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMapEditor('Headers', _headers),
            const SizedBox(height: 24),
            _buildMapEditor('Query Params', _queryParams),
            const SizedBox(height: 24),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {language}, {stdin} as placeholders.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '{"code": "{code}"}'),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _responseMapping.stdoutPath,
              decoration: const InputDecoration(labelText: 'Stdout Path (e.g. data.output)'),
              onSaved: (v) => _responseMapping = _responseMapping.copyWith(stdoutPath: v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _responseMapping.stderrPath,
              decoration: const InputDecoration(labelText: 'Stderr Path'),
              onSaved: (v) => _responseMapping = _responseMapping.copyWith(stderrPath: v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _responseMapping.errorPath,
              decoration: const InputDecoration(labelText: 'Error Path'),
              onSaved: (v) => _responseMapping = _responseMapping.copyWith(errorPath: v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _responseMapping.executionTimePath,
              decoration: const InputDecoration(labelText: 'Execution Time Path'),
              onSaved: (v) => _responseMapping = _responseMapping.copyWith(executionTimePath: v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _responseMapping.memoryPath,
              decoration: const InputDecoration(labelText: 'Memory Path'),
              onSaved: (v) => _responseMapping = _responseMapping.copyWith(memoryPath: v),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isTesting ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isTesting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMapEditor(String title, List<MapEntry<String, String>> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => setState(() => entries.add(const MapEntry('', ''))),
            )
          ],
        ),
        ...entries.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.key,
                    decoration: const InputDecoration(hintText: 'Key'),
                    onChanged: (v) => entries[idx] = MapEntry(v, entries[idx].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value,
                    decoration: const InputDecoration(hintText: 'Value'),
                    onChanged: (v) => entries[idx] = MapEntry(entries[idx].key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: AppColors.errorRed),
                  onPressed: () => setState(() => entries.removeAt(idx)),
                )
              ],
            ),
          );
        }),
      ],
    );
  }
}
