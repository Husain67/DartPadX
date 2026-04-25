import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import '../theme.dart';

import '../../services/execution_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & API Presets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Disable to use Custom API Compiler System'),
            value: settings.useDefaultCompiler,
            activeTrackColor: accentYellow,
            activeThumbColor: Colors.black,
            onChanged: (val) => ref.read(settingsProvider.notifier).toggleUseDefault(val),
          ),
          const Divider(),
          const Text('Custom Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentYellow)),
          const SizedBox(height: 8),
          if (settings.presets.isEmpty)
             const Text('No presets available. Add one.')
          else
             ...settings.presets.map((preset) => Card(
               color: settings.activePresetId == preset.id ? accentYellow.withValues(alpha: 0.2) : Colors.white10,
               child: ListTile(
                 title: Text(preset.name),
                 subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                 trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editPreset(context, ref, preset)),
                     IconButton(icon: const Icon(Icons.copy, color: Colors.green), onPressed: () {
                        final copy = CompilerPreset.fromJson(preset.toJson());
                        copy.id = const Uuid().v4();
                        copy.name = '${preset.name} (Copy)';
                        ref.read(settingsProvider.notifier).savePreset(copy);
                     }),
                     IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset.id)),
                   ],
                 ),
                 onTap: () {
                   ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                   Fluttertoast.showToast(msg: "Set as active preset");
                 },
               ),
             )),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.file_upload, color: Colors.black),
                label: const Text('Export', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: accentYellow),
                onPressed: () => ref.read(settingsProvider.notifier).exportPresets(),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_download, color: Colors.black),
                label: const Text('Import', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: accentYellow),
                onPressed: () => ref.read(settingsProvider.notifier).importPresets(),
              ),
            ]
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(

            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Add New Preset', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(backgroundColor: accentYellow),
            onPressed: () => _editPreset(context, ref, null),
          ),
        ],
      ),
    );
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
     Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
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

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _name = p?.name ?? '';
    _url = p?.url ?? '';
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValue = p?.authValue ?? '';
    _bodyTemplate = p?.bodyTemplate ?? '{\n  "code": "{code}",\n  "language": "{language}"\n}';
    _stdoutPath = p?.stdoutPath ?? 'stdout';
    _stderrPath = p?.stderrPath ?? 'stderr';
    _errorPath = p?.errorPath ?? 'error';
    _executionTimePath = p?.executionTimePath ?? 'executionTime';
    _memoryPath = p?.memoryPath ?? 'memory';
    _headers = p != null ? List.from(p.headers) : [];
    _queryParams = p != null ? List.from(p.queryParams) : [];
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
        headers: _headers,
        queryParams: _queryParams,
        bodyTemplate: _bodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _executionTimePath,
        memoryPath: _memoryPath,
      );
      ref.read(settingsProvider.notifier).savePreset(newPreset);
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
     if (_formKey.currentState!.validate()) {
       _formKey.currentState!.save();
       final tempPreset = CompilerPreset(
         id: 'test',
         name: _name,
         url: _url,
         method: _method,
         authType: _authType,
         authValue: _authValue,
         headers: _headers,
         queryParams: _queryParams,
         bodyTemplate: _bodyTemplate,
         stdoutPath: _stdoutPath,
         stderrPath: _stderrPath,
         errorPath: _errorPath,
         executionTimePath: _executionTimePath,
         memoryPath: _memoryPath,
       );

       Fluttertoast.showToast(msg: "Testing connection...");
       final res = await ExecutionService.runCode(code: "print('Hello from custom API');", useDefault: false, preset: tempPreset);

       if (res.error.isNotEmpty && res.stdout.isEmpty) {
         Fluttertoast.showToast(msg: "Error: ${res.error}");
       } else {
         Fluttertoast.showToast(msg: "Success! Output: ${res.stdout.isEmpty ? 'None' : res.stdout}");
       }
     } else {
       Fluttertoast.showToast(msg: "Please fill required fields first");
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.network_check), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
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
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _name = v!,
            ),
            TextFormField(
              initialValue: _url,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _url = v!,
            ),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            DropdownButtonFormField<String>(
              initialValue: _authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            if (_authType != 'None')
              TextFormField(
                initialValue: _authValue,
                decoration: const InputDecoration(labelText: 'Auth Value'),
                onSaved: (v) => _authValue = v ?? '',
              ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Headers', style: TextStyle(color: accentYellow, fontSize: 16)),
                IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _headers.add(const MapEntry('', '')))),
              ],
            ),
            ..._headers.asMap().entries.map((entry) {
              int idx = entry.key;
              MapEntry<String, String> header = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: header.key,
                      decoration: const InputDecoration(labelText: 'Key'),
                      onChanged: (v) => _headers[idx] = MapEntry(v, header.value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: header.value,
                      decoration: const InputDecoration(labelText: 'Value'),
                      onChanged: (v) => _headers[idx] = MapEntry(header.key, v),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _headers.removeAt(idx))),
                ],
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Query Params', style: TextStyle(color: accentYellow, fontSize: 16)),
                IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _queryParams.add(const MapEntry('', '')))),
              ],
            ),
            ..._queryParams.asMap().entries.map((entry) {
              int idx = entry.key;
              MapEntry<String, String> param = entry.value;
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: param.key,
                      decoration: const InputDecoration(labelText: 'Key'),
                      onChanged: (v) => _queryParams[idx] = MapEntry(v, param.value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: param.value,
                      decoration: const InputDecoration(labelText: 'Value'),
                      onChanged: (v) => _queryParams[idx] = MapEntry(param.key, v),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _queryParams.removeAt(idx))),
                ],
              );
            }),
            const SizedBox(height: 16),
            const Text('Request Body Template', style: TextStyle(color: accentYellow)),

            TextFormField(
              initialValue: _bodyTemplate,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Use {code}, {language}, {stdin}'),
              onSaved: (v) => _bodyTemplate = v ?? '',
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (dot notation)', style: TextStyle(color: accentYellow)),
            TextFormField(initialValue: _stdoutPath, decoration: const InputDecoration(labelText: 'stdout path'), onSaved: (v) => _stdoutPath = v ?? ''),
            TextFormField(initialValue: _stderrPath, decoration: const InputDecoration(labelText: 'stderr path'), onSaved: (v) => _stderrPath = v ?? ''),
            TextFormField(initialValue: _errorPath, decoration: const InputDecoration(labelText: 'error path'), onSaved: (v) => _errorPath = v ?? ''),
            TextFormField(initialValue: _executionTimePath, decoration: const InputDecoration(labelText: 'execution time path'), onSaved: (v) => _executionTimePath = v ?? ''),
            TextFormField(initialValue: _memoryPath, decoration: const InputDecoration(labelText: 'memory path'), onSaved: (v) => _memoryPath = v ?? ''),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Save Preset')),
          ],
        ),
      ),
    );
  }
}
