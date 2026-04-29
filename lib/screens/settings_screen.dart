import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/all_providers.dart';
import '../models/compiler_preset.dart';
import '../utils/theme.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/file_ops.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings & Compilers', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
          ),
        ),
        child: const PresetList(),
      ),
    );
  }
}

class PresetList extends ConsumerWidget {
  const PresetList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Fastest, requires no setup'),
          value: settings.useDefaultOneCompiler,
          activeTrackColor: AppTheme.primaryAccent.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.primaryAccent,
          onChanged: (val) {
            notifier.setUseDefaultOneCompiler(val);
          },
        ),
        const Divider(color: Colors.white24),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Custom Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
        ),
        if (!settings.useDefaultOneCompiler) ...[
          for (var preset in settings.presets)
            Card(
              color: Colors.white10,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                // ignore: deprecated_member_use
                leading: Radio<String>(
                  value: preset.id,
                  // ignore: deprecated_member_use
                  groupValue: settings.activePresetId,
                  activeColor: AppTheme.primaryAccent,
                  // ignore: deprecated_member_use
                  onChanged: (val) {
                    if (val != null) notifier.setActivePreset(val);
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => EditPresetScreen(preset: preset)));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      onPressed: () {
                         final duplicate = preset.copyWith(id: const Uuid().v4(), name: "${preset.name} (Copy)");
                         notifier.addPreset(duplicate);
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

              ElevatedButton.icon(
                icon: const Icon(Icons.upload, color: Colors.black),
                label: const Text('Import JSON', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                onPressed: () async {
                   final jsonStr = await FileOps.pasteFromClipboard();
                   if (jsonStr != null) {
                     try {
                        final List<dynamic> decoded = jsonDecode(jsonStr);
                        for (var item in decoded) {
                          final p = CompilerPreset(
                             id: const Uuid().v4(),
                             name: item['name'] ?? 'Imported Preset',
                             endpoint: item['endpoint'] ?? '',
                             httpMethod: item['httpMethod'] ?? 'POST',
                             authType: item['authType'] ?? 'None',
                             authValue: item['authValue'] ?? '',
                             bodyTemplate: item['bodyTemplate'] ?? '{"content": "{code}"}',
                             stdoutPath: item['stdoutPath'] ?? '',
                             stderrPath: item['stderrPath'] ?? '',
                             errorPath: item['errorPath'] ?? '',
                             timePath: item['timePath'] ?? '',
                             memoryPath: item['memoryPath'] ?? '',
                             headers: (item['headers'] as List?)?.map((e) => MapEntry<String,String>(e['key'] ?? '', e['value'] ?? '')).toList() ?? [],
                             queryParams: (item['queryParams'] as List?)?.map((e) => MapEntry<String,String>(e['key'] ?? '', e['value'] ?? '')).toList() ?? [],
                          );
                          notifier.addPreset(p);
                        }
                        Fluttertoast.showToast(msg: "Imported successfully");
                     } catch (e) {
                        Fluttertoast.showToast(msg: "Invalid JSON");
                     }
                   }
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download, color: Colors.black),
                label: const Text('Export JSON', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                onPressed: () {
                   final List<Map<String, dynamic>> jsonList = settings.presets.map((p) => {
                     'name': p.name,
                     'endpoint': p.endpoint,
                     'httpMethod': p.httpMethod,
                     'authType': p.authType,
                     'authValue': p.authValue,
                     'bodyTemplate': p.bodyTemplate,
                     'stdoutPath': p.stdoutPath,
                     'stderrPath': p.stderrPath,
                     'errorPath': p.errorPath,
                     'timePath': p.timePath,
                     'memoryPath': p.memoryPath,
                     'headers': p.headers.map((e) => {'key': e.key, 'value': e.value}).toList(),
                     'queryParams': p.queryParams.map((e) => {'key': e.key, 'value': e.value}).toList(),
                   }).toList();
                   FileOps.copyToClipboard(jsonEncode(jsonList));
                   Fluttertoast.showToast(msg: "Exported to clipboard");
                },
              ),

            ],
          ),
        ),

          ElevatedButton.icon(
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Add New Preset', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditPresetScreen(preset: CompilerPreset(id: const Uuid().v4(), name: 'New Preset', endpoint: ''))));
            },
          ),
        ] else ...[
           const Padding(
             padding: EdgeInsets.all(16.0),
             child: Text('Disable "Use Default OneCompiler" to use and edit custom presets.', style: TextStyle(color: Colors.white54)),
           )
        ]
      ],
    );
  }
}

class EditPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  const EditPresetScreen({super.key, required this.preset});

  @override
  ConsumerState<EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<EditPresetScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late String _httpMethod;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late List<MapEntry<String, String>> _headers;
  late List<MapEntry<String, String>> _queryParams;
  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _endpointCtrl = TextEditingController(text: widget.preset.endpoint);
    _httpMethod = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _authValueCtrl = TextEditingController(text: widget.preset.authValue);
    _headers = List.from(widget.preset.headers);
    _queryParams = List.from(widget.preset.queryParams);
    _bodyTemplateCtrl = TextEditingController(text: widget.preset.bodyTemplate);
    _stdoutPathCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrPathCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorPathCtrl = TextEditingController(text: widget.preset.errorPath);
    _timePathCtrl = TextEditingController(text: widget.preset.timePath);
    _memoryPathCtrl = TextEditingController(text: widget.preset.memoryPath);
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpoint: _endpointCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: _headers,
      queryParams: _queryParams,
      bodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      timePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    // If it's a new one (not in list), add it, otherwise update
    final presets = ref.read(settingsProvider).presets;
    final exists = presets.any((p) => p.id == updated.id);
    if (exists) {
      ref.read(settingsProvider.notifier).updatePreset(updated);
    } else {
      ref.read(settingsProvider.notifier).addPreset(updated);
    }

    Navigator.pop(context);
  }

  void _testConnection() async {
    Fluttertoast.showToast(msg: 'Testing connection...');
    final headers = <String, String>{};
    for (var e in _headers) {
      headers[e.key] = e.value;
    }

    if (_authType == 'Header') {
      headers['Authorization'] = _authValueCtrl.text;
    } else if (_authType == 'Bearer') {
      headers['Authorization'] = 'Bearer ${_authValueCtrl.text}';
    } else if (_authType == 'Basic') {
      headers['Authorization'] = 'Basic ${base64Encode(utf8.encode(_authValueCtrl.text))}';
    }

    final bodyStr = _bodyTemplateCtrl.text
        .replaceAll('{code}', jsonEncode("print('Hello from custom API');").replaceAll(RegExp(r'^"|"$'), ''))
        .replaceAll('{stdin}', '')
        .replaceAll('{language}', 'dart');

    try {
      http.Response res;
      final uri = Uri.parse(_endpointCtrl.text);
      if (_httpMethod == 'POST') {
        res = await http.post(uri, headers: headers, body: bodyStr);
      } else {
        res = await http.get(uri, headers: headers);
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Status: ${res.statusCode}'),
          content: SingleChildScrollView(child: Text(res.body)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Edit Preset', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
            ref.read(settingsProvider.notifier).deletePreset(widget.preset.id);
            Navigator.pop(context);
          }),
          IconButton(icon: const Icon(Icons.save, color: AppTheme.primaryAccent), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTextField('Platform Name', _nameCtrl),
          _buildTextField('Endpoint URL', _endpointCtrl),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.backgroundEnd,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.white54)),
            initialValue: _httpMethod,
            items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _httpMethod = v!),
          ),
          DropdownButtonFormField<String>(
            dropdownColor: AppTheme.backgroundEnd,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.white54)),
            initialValue: _authType,
            items: ['None', 'Header', 'Bearer', 'Basic', 'Query'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _authType = v!),
          ),
          if (_authType != 'None') _buildTextField('Auth Value', _authValueCtrl),

          const SizedBox(height: 16),
          const Text('Headers', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold)),
          ..._headers.asMap().entries.map((e) => Row(
            children: [
              Expanded(child: TextFormField(initialValue: e.value.key, style: const TextStyle(color: Colors.white), onChanged: (v) => _headers[e.key] = MapEntry(v, _headers[e.key].value))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(initialValue: e.value.value, style: const TextStyle(color: Colors.white), onChanged: (v) => _headers[e.key] = MapEntry(_headers[e.key].key, v))),
              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _headers.removeAt(e.key))),
            ],
          )),
          TextButton(onPressed: () => setState(() => _headers.add(const MapEntry('',''))), child: const Text('+ Add Header')),

          const SizedBox(height: 16),
          const Text('JSON Body Template', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold)),
          const Text('Use placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
          _buildTextField('', _bodyTemplateCtrl, maxLines: 5),

          const SizedBox(height: 16),
          const Text('Response Mapping (Dot Notation)', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold)),
          _buildTextField('stdout path', _stdoutPathCtrl),
          _buildTextField('stderr path', _stderrPathCtrl),
          _buildTextField('error path', _errorPathCtrl),
          _buildTextField('execution time path', _timePathCtrl),
          _buildTextField('memory path', _memoryPathCtrl),

          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
            onPressed: _testConnection,
            child: const Text('Test Connection', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryAccent)),
        ),
      ),
    );
  }
}
