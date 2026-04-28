import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/compiler_preset.dart';
import '../../providers/compiler_provider.dart';
import '../../providers/execution_provider.dart';
import '../../theme/app_theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset; // Null means new preset
  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _id;
  late String _name;
  late String _endpoint;
  late String _method;
  late String _authType;
  late String _authKey;
  late String _authValue;
  late List<MapEntry<String, String>> _headers;
  late List<MapEntry<String, String>> _queryParams;
  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;
  late bool _isDefaultSystem;

  @override
  void initState() {
    super.initState();
    final p = widget.preset ?? CompilerPreset(id: DateTime.now().millisecondsSinceEpoch.toString(), name: 'New Preset', endpoint: '');
    _id = p.id;
    _name = p.name;
    _endpoint = p.endpoint;
    _method = p.method;
    _authType = p.authType;
    _authKey = p.authKey;
    _authValue = p.authValue;
    _headers = List.from(p.headers);
    _queryParams = List.from(p.queryParams);
    _bodyTemplate = p.bodyTemplate;
    _stdoutPath = p.stdoutPath;
    _stderrPath = p.stderrPath;
    _errorPath = p.errorPath;
    _executionTimePath = p.executionTimePath;
    _memoryPath = p.memoryPath;
    _isDefaultSystem = p.isDefaultSystem;
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: _id,
        name: _name,
        endpoint: _endpoint,
        method: _method,
        authType: _authType,
        authKey: _authKey,
        authValue: _authValue,
        headers: _headers,
        queryParams: _queryParams,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
        isDefaultSystem: _isDefaultSystem,
      );
      ref.read(compilerProvider.notifier).savePreset(newPreset);
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    _formKey.currentState?.save();
    final tempPreset = CompilerPreset(
      id: 'test',
      name: 'test',
      endpoint: _endpoint,
      method: _method,
      authType: _authType,
      authKey: _authKey,
      authValue: _authValue,
      headers: _headers,
      queryParams: _queryParams,
      bodyTemplate: _bodyTemplate,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
    );

    final result = await ref.read(executionProvider.notifier).testConnection(tempPreset);

    if (!mounted) return;
    Navigator.pop(context); // close loading

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Text(result, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _buildDynamicList(String title, List<MapEntry<String, String>> items, Function(List<MapEntry<String, String>>) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: boldStyle)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('', ''));
                  onUpdate(items);
                });
              },
            )
          ],
        ),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.key,
                    decoration: const InputDecoration(labelText: 'Key', isDense: true),
                    onChanged: (val) {
                      items[idx] = MapEntry(val, item.value);
                      onUpdate(items);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.value,
                    decoration: const InputDecoration(labelText: 'Value', isDense: true),
                    onChanged: (val) {
                      items[idx] = MapEntry(item.key, val);
                      onUpdate(items);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      items.removeAt(idx);
                      onUpdate(items);
                    });
                  },
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  static const FontWeight boldStyle = FontWeight.bold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow), tooltip: 'Test Connection', onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isDefaultSystem)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withValues(alpha: 0.1),
                child: const Text('This is a System Preset. You can modify it, but updates might be restricted in future versions. Duplicate it to create a custom variant.', style: TextStyle(color: Colors.redAccent)),
              ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Preset Name'),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _name = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _endpoint,
              decoration: const InputDecoration(labelText: 'Endpoint URL (e.g., https://api.com/run)'),
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              onSaved: (val) => _endpoint = val!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _method = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _authType = val!),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              if (_authType != 'Bearer Token')
                TextFormField(
                  initialValue: _authKey,
                  decoration: InputDecoration(labelText: _authType == 'Basic Auth' ? 'Username' : 'Auth Key Name (e.g., X-API-Key)'),
                  onSaved: (val) => _authKey = val ?? '',
                ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _authValue,
                decoration: InputDecoration(labelText: _authType == 'Basic Auth' ? 'Password' : 'Auth Value (Token/Secret)'),
                obscureText: true,
                onSaved: (val) => _authValue = val ?? '',
              ),
            ],
            const Divider(height: 32),
            _buildDynamicList('Headers', _headers, (val) => _headers = val),
            const Divider(height: 32),
            _buildDynamicList('Query Parameters', _queryParams, (val) => _queryParams = val),
            const Divider(height: 32),
            const Text('Request Body Template (JSON)', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: boldStyle)),
            const Text('Use placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _bodyTemplate,
              maxLines: 8,
              decoration: const InputDecoration(hintText: '{"code": "{code}"}'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              onSaved: (val) => _bodyTemplate = val ?? '',
            ),
            const Divider(height: 32),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: boldStyle)),
            const Text('e.g., data.run.stdout', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextFormField(initialValue: _stdoutPath, decoration: const InputDecoration(labelText: 'stdout path'), onSaved: (val) => _stdoutPath = val ?? ''),
            const SizedBox(height: 8),
            TextFormField(initialValue: _stderrPath, decoration: const InputDecoration(labelText: 'stderr path'), onSaved: (val) => _stderrPath = val ?? ''),
            const SizedBox(height: 8),
            TextFormField(initialValue: _errorPath, decoration: const InputDecoration(labelText: 'error path'), onSaved: (val) => _errorPath = val ?? ''),
            const SizedBox(height: 8),
            TextFormField(initialValue: _executionTimePath, decoration: const InputDecoration(labelText: 'execution time path'), onSaved: (val) => _executionTimePath = val ?? ''),
            const SizedBox(height: 8),
            TextFormField(initialValue: _memoryPath, decoration: const InputDecoration(labelText: 'memory path'), onSaved: (val) => _memoryPath = val ?? ''),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
