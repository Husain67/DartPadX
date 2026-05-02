import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../theme/app_theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;

  String _httpMethod = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  late Map<String, String> _responseMapping;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyCtrl = TextEditingController(text: p?.bodyTemplate ?? '{}');

    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';

    _headers = p?.headers.entries.toList() ?? [];
    _queryParams = p?.queryParams.entries.toList() ?? [];

    _responseMapping = p?.responseMapping != null
        ? Map.from(p!.responseMapping)
        : {'stdout': '', 'stderr': '', 'error': '', 'executionTime': '', 'memory': ''};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newPreset = CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      bodyTemplate: _bodyCtrl.text,
      responseMapping: _responseMapping,
    );

    if (widget.preset == null) {
      ref.read(compilerProvider.notifier).addPreset(newPreset);
    } else {
      ref.read(compilerProvider.notifier).updatePreset(newPreset);
    }

    Fluttertoast.showToast(msg: "Preset saved");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.network_check),
            tooltip: 'Test Connection',
            onPressed: () {
              // Stub for Test Connection
              Fluttertoast.showToast(msg: "Test Connection (Stub)");
            },
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryColor),
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
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlCtrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _httpMethod = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            if (_authType != 'None') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _authValueCtrl,
                decoration: const InputDecoration(labelText: 'Auth Value'),
              ),
            ],
            const SizedBox(height: 24),
            _buildDynamicList('Headers', _headers),
            const SizedBox(height: 24),
            _buildDynamicList('Query Params', _queryParams),
            const SizedBox(height: 24),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('{code}, {stdin} placeholders supported', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 8,
              decoration: const InputDecoration(hintText: '{"code": "{code}"}'),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...['stdout', 'stderr', 'error', 'executionTime', 'memory'].map((key) {
               return Padding(
                 padding: const EdgeInsets.only(bottom: 8),
                 child: TextFormField(
                   initialValue: _responseMapping[key],
                   decoration: InputDecoration(labelText: '$key path'),
                   onChanged: (v) => _responseMapping[key] = v,
                 ),
               );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicList(String title, List<MapEntry<String, String>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() => list.add(const MapEntry('', '')));
              },
            )
          ],
        ),
        ...list.asMap().entries.map((entry) {
           final idx = entry.key;
           final mapEntry = entry.value;
           return Row(
             children: [
               Expanded(
                 child: TextFormField(
                   initialValue: mapEntry.key,
                   decoration: const InputDecoration(hintText: 'Key'),
                   onChanged: (v) => setState(() => list[idx] = MapEntry(v, list[idx].value)),
                 ),
               ),
               const SizedBox(width: 8),
               Expanded(
                 child: TextFormField(
                   initialValue: mapEntry.value,
                   decoration: const InputDecoration(hintText: 'Value'),
                   onChanged: (v) => setState(() => list[idx] = MapEntry(list[idx].key, v)),
                 ),
               ),
               IconButton(
                 icon: const Icon(Icons.remove_circle, color: Colors.red),
                 onPressed: () => setState(() => list.removeAt(idx)),
               )
             ],
           );
        }),
      ],
    );
  }
}
