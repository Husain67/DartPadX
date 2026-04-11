import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late final GlobalKey<FormState> _formKey;
  late String _name;
  late String _endpointUrl;
  late String _httpMethod;
  late String _authType;
  late String _authValue;
  late String _requestBodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  late List<MapEntry<String, String>> _headersList;
  late List<MapEntry<String, String>> _queryParamsList;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _name = widget.preset.name;
    _endpointUrl = widget.preset.endpointUrl;
    _httpMethod = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _authValue = widget.preset.authValue;
    _requestBodyTemplate = widget.preset.requestBodyTemplate;
    _stdoutPath = widget.preset.stdoutPath;
    _stderrPath = widget.preset.stderrPath;
    _errorPath = widget.preset.errorPath;
    _executionTimePath = widget.preset.executionTimePath;
    _memoryPath = widget.preset.memoryPath;
    _headersList = widget.preset.headers.entries.toList();
    _queryParamsList = widget.preset.queryParams.entries.toList();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final headersMap = {for (var e in _headersList) if(e.key.isNotEmpty) e.key: e.value};
      final queryParamsMap = {for (var e in _queryParamsList) if(e.key.isNotEmpty) e.key: e.value};

      final updated = widget.preset.copyWith(
        name: _name,
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        authType: _authType,
        authValue: _authValue,
        headers: headersMap,
        queryParams: queryParamsMap,
        requestBodyTemplate: _requestBodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );
      ref.read(settingsProvider.notifier).updatePreset(updated);
      Fluttertoast.showToast(msg: "Preset saved");
      Navigator.pop(context);
    }
  }

  void _delete() {
    ref.read(settingsProvider.notifier).deletePreset(widget.preset.id);
    Fluttertoast.showToast(msg: "Preset deleted");
    Navigator.pop(context);
  }

  Widget _buildMapEditor(String title, List<MapEntry<String, String>> list, VoidCallback onAdd, Function(int, String, String) onUpdate, Function(int) onRemove) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
             IconButton(
               icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFACC15), size: 20),
               onPressed: onAdd,
             )
          ],
        ),
        if (list.isEmpty)
           const Text('None', style: TextStyle(color: Colors.white54, fontSize: 13)),
        ...list.asMap().entries.map((entry) {
           int idx = entry.key;
           var item = entry.value;
           return Row(
             children: [
               Expanded(
                 child: TextFormField(
                   initialValue: item.key,
                   decoration: const InputDecoration(hintText: 'Key', isDense: true),
                   onChanged: (val) => onUpdate(idx, val, item.value),
                 ),
               ),
               const SizedBox(width: 8),
               Expanded(
                 child: TextFormField(
                   initialValue: item.value,
                   decoration: const InputDecoration(hintText: 'Value', isDense: true),
                   onChanged: (val) => onUpdate(idx, item.key, val),
                 ),
               ),
               IconButton(
                 icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                 onPressed: () => onRemove(idx),
               )
             ],
           );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _delete,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFFACC15)),
            onPressed: _save,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              onSaved: (val) => _name = val ?? '',
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _endpointUrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              keyboardType: TextInputType.url,
              onSaved: (val) => _endpointUrl = val ?? '',
              validator: (val) => val == null || val.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _httpMethod = val);
              },
              onSaved: (val) => _httpMethod = val ?? 'POST',
            ),
            const SizedBox(height: 16),
             DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _authType = val);
              },
              onSaved: (val) => _authType = val ?? 'None',
            ),
            if (_authType != 'None') ...[
               const SizedBox(height: 16),
               TextFormField(
                initialValue: _authValue,
                decoration: InputDecoration(labelText: 'Auth Value for $_authType'),
                onSaved: (val) => _authValue = val ?? '',
              ),
            ],
            const SizedBox(height: 24),
            _buildMapEditor(
               'Headers',
               _headersList,
               () => setState(() => _headersList.add(const MapEntry('', ''))),
               (idx, k, v) => setState(() => _headersList[idx] = MapEntry(k, v)),
               (idx) => setState(() => _headersList.removeAt(idx))
            ),
            const SizedBox(height: 16),
            _buildMapEditor(
               'Query Params',
               _queryParamsList,
               () => setState(() => _queryParamsList.add(const MapEntry('', ''))),
               (idx, k, v) => setState(() => _queryParamsList[idx] = MapEntry(k, v)),
               (idx) => setState(() => _queryParamsList.removeAt(idx))
            ),
            const SizedBox(height: 32),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Use {code}, {language}, {stdin}', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _requestBodyTemplate,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{\\n  "code": "{code}"\\n}',
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              onSaved: (val) => _requestBodyTemplate = val ?? '',
            ),
            const SizedBox(height: 32),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _stdoutPath,
              decoration: const InputDecoration(labelText: 'stdout path (e.g. data.run.stdout)'),
              onSaved: (val) => _stdoutPath = val ?? '',
            ),
            TextFormField(
              initialValue: _stderrPath,
              decoration: const InputDecoration(labelText: 'stderr path'),
              onSaved: (val) => _stderrPath = val ?? '',
            ),
            TextFormField(
              initialValue: _errorPath,
              decoration: const InputDecoration(labelText: 'error path'),
              onSaved: (val) => _errorPath = val ?? '',
            ),
            TextFormField(
              initialValue: _executionTimePath,
              decoration: const InputDecoration(labelText: 'executionTime path'),
              onSaved: (val) => _executionTimePath = val ?? '',
            ),
            TextFormField(
              initialValue: _memoryPath,
              decoration: const InputDecoration(labelText: 'memory path'),
              onSaved: (val) => _memoryPath = val ?? '',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
