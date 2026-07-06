import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFACC15),
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('General Settings (WIP)', style: TextStyle(color: Colors.grey))),
            PresetsTab(),
          ],
        ),
      ),
    );
  }
}

class PresetsTab extends ConsumerWidget {
  const PresetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Add New', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15)),
                onPressed: () => _editPreset(context, ref, null),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.presets.length,
            itemBuilder: (context, index) {
              final preset = state.presets[index];
              final isActive = preset.id == state.activePresetId;
              return ListTile(
                title: Text(preset.name, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(preset.endpointUrl.isEmpty ? 'Default Built-in API' : preset.endpointUrl),
                leading: Radio<String>(
                  value: preset.id,
                  // ignore: deprecated_member_use
groupValue: state.activePresetId,
                  activeColor: const Color(0xFFFACC15),
                  // ignore: deprecated_member_use
onChanged: (val) {
                    if (val != null) ref.read(settingsProvider.notifier).setActivePreset(val);
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!preset.isDefault)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPreset(context, ref, preset),
                      ),
                    if (!preset.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deletePreset(context, ref, preset.id),
                      ),
                  ],
                ),
                onTap: () => ref.read(settingsProvider.notifier).setActivePreset(preset.id),
              );
            },
          ),
        ),
      ],
    );
  }

  void _deletePreset(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset'),
        content: const Text('Are you sure you want to delete this preset?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(settingsProvider.notifier).deletePreset(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditPresetScreen(preset: preset)));
  }
}

class EditPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const EditPresetScreen({super.key, this.preset});

  @override
  ConsumerState<EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<EditPresetScreen> {
  final _formKey = GlobalKey<FormState>();
  late String name, endpointUrl, httpMethod, authType, authValue, requestBodyTemplate;
  late String stdoutPath, stderrPath, errorPath, executionTimePath, memoryPath;
  late List<MapEntry<String, String>> headers, queryParams;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    name = p?.name ?? '';
    endpointUrl = p?.endpointUrl ?? '';
    httpMethod = p?.httpMethod ?? 'POST';
    authType = p?.authType ?? 'None';
    authValue = p?.authValue ?? '';
    requestBodyTemplate = p?.requestBodyTemplate ?? '{\n  "language": "{language}",\n  "code": "{code}"\n}';
    stdoutPath = p?.stdoutPath ?? 'stdout';
    stderrPath = p?.stderrPath ?? 'stderr';
    errorPath = p?.errorPath ?? 'error';
    executionTimePath = p?.executionTimePath ?? 'time';
    memoryPath = p?.memoryPath ?? 'memory';
    headers = p?.headers.entries.toList() ?? [const MapEntry('Content-Type', 'application/json')];
    queryParams = p?.queryParams.entries.toList() ?? [];
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? '',
        name: name,
        endpointUrl: endpointUrl,
        httpMethod: httpMethod,
        authType: authType,
        authValue: authValue,
        headers: Map.fromEntries(headers.where((e) => e.key.isNotEmpty)),
        queryParams: Map.fromEntries(queryParams.where((e) => e.key.isNotEmpty)),
        requestBodyTemplate: requestBodyTemplate,
        stdoutPath: stdoutPath,
        stderrPath: stderrPath,
        errorPath: errorPath,
        executionTimePath: executionTimePath,
        memoryPath: memoryPath,
      );

      if (widget.preset == null) {
        ref.read(settingsProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15))),
    );

    try {
      final uri = Uri.parse(endpointUrl).replace(queryParameters: Map.fromEntries(queryParams));
      Map<String, String> hdrs = Map.fromEntries(headers.where((e) => e.key.isNotEmpty));

      if (authType == 'API-Key Header' && authValue.isNotEmpty) {
         hdrs['Authorization'] = authValue;
      } else if (authType == 'Bearer Token' && authValue.isNotEmpty) {
         hdrs['Authorization'] = 'Bearer $authValue';
      } else if (authType == 'Basic Auth' && authValue.isNotEmpty) {
         final encoded = base64Encode(utf8.encode(authValue));
         hdrs['Authorization'] = 'Basic $encoded';
      }

      String bodyStr = requestBodyTemplate;
      bodyStr = bodyStr.replaceAll('{code}', jsonEncode("void main() { print('Hello from custom API'); }").substring(1, jsonEncode("void main() { print('Hello from custom API'); }").length - 1));
      bodyStr = bodyStr.replaceAll('{language}', 'dart');
      bodyStr = bodyStr.replaceAll('{stdin}', '');

      http.Response response;
      if (httpMethod == 'POST') {
        response = await http.post(uri, headers: hdrs, body: bodyStr);
      } else if (httpMethod == 'PUT') {
        response = await http.put(uri, headers: hdrs, body: bodyStr);
      } else {
        response = await http.get(uri, headers: hdrs);
      }

      if (!mounted) return;
      Navigator.pop(context); // pop loading

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Test Result: ${response.statusCode}'),
          content: SingleChildScrollView(child: Text(response.body)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      Fluttertoast.showToast(msg: 'Test Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Color(0xFFFACC15)),
            tooltip: 'Test Connection',
            onPressed: _testConnection,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
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
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Platform Name (e.g. JDoodle)'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => name = v!,
            ),
            TextFormField(
              initialValue: endpointUrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => endpointUrl = v!,
            ),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
value: httpMethod,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => httpMethod = v!),
              onSaved: (v) => httpMethod = v!,
            ),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
value: authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => authType = v!),
              onSaved: (v) => authType = v!,
            ),
            if (authType != 'None')
              TextFormField(
                initialValue: authValue,
                decoration: const InputDecoration(labelText: 'Auth Value (Token/Key)'),
                onSaved: (v) => authValue = v ?? '',
              ),

            const SizedBox(height: 16),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('Use {code}, {language}, {stdin} as placeholders.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            TextFormField(
              initialValue: requestBodyTemplate,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onSaved: (v) => requestBodyTemplate = v ?? '',
            ),

            const SizedBox(height: 16),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: stdoutPath,
              decoration: const InputDecoration(labelText: 'stdout path (e.g. output.stdout)'),
              onSaved: (v) => stdoutPath = v ?? '',
            ),
            TextFormField(
              initialValue: stderrPath,
              decoration: const InputDecoration(labelText: 'stderr path'),
              onSaved: (v) => stderrPath = v ?? '',
            ),
            TextFormField(
              initialValue: errorPath,
              decoration: const InputDecoration(labelText: 'error path'),
              onSaved: (v) => errorPath = v ?? '',
            ),
            TextFormField(
              initialValue: executionTimePath,
              decoration: const InputDecoration(labelText: 'execution time path'),
              onSaved: (v) => executionTimePath = v ?? '',
            ),
            TextFormField(
              initialValue: memoryPath,
              decoration: const InputDecoration(labelText: 'memory path'),
              onSaved: (v) => memoryPath = v ?? '',
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black),
              onPressed: _save,
              child: const Text('Save Preset'),
            )
          ],
        ),
      ),
    );
  }
}
