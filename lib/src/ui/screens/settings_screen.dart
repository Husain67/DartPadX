import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/compiler_preset.dart';
import '../../data/providers/app_state.dart';
import '../../data/services/compiler_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _exportPresets() {
    final presets = ref.read(presetsProvider);
    final jsonList = presets.map((p) => {
      'name': p.name,
      'endpointUrl': p.endpointUrl,
      'method': p.method,
      'authType': p.authType,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'bodyTemplate': p.bodyTemplate,
      'stdoutPath': p.stdoutPath,
      'stderrPath': p.stderrPath,
      'errorPath': p.errorPath,
      'executionTimePath': p.executionTimePath,
      'memoryPath': p.memoryPath,
    }).toList();

    final jsonString = jsonEncode(jsonList);
    Share.share(jsonString, subject: 'DartMini IDE Compiler Presets');
  }

  void _importPresets() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String content = utf8.decode(result.files.single.bytes!);
        List<dynamic> jsonList = jsonDecode(content);

        for (var map in jsonList) {
          final newPreset = CompilerPreset(
            id: uuid.v4(),
            name: map['name'] ?? 'Imported Preset',
            endpointUrl: map['endpointUrl'] ?? '',
            method: map['method'] ?? 'POST',
            authType: map['authType'] ?? 'None',
            headers: Map<String, String>.from(map['headers'] ?? {}),
            queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
            bodyTemplate: map['bodyTemplate'] ?? '',
            stdoutPath: map['stdoutPath'] ?? '',
            stderrPath: map['stderrPath'] ?? '',
            errorPath: map['errorPath'] ?? '',
            executionTimePath: map['executionTimePath'] ?? '',
            memoryPath: map['memoryPath'] ?? '',
          );
          ref.read(presetsProvider.notifier).addPreset(newPreset);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presets imported successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error importing presets')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // fallback
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.appBarColor,
        actions: [
          IconButton(icon: const Icon(Icons.file_upload), onPressed: _exportPresets, tooltip: 'Export Presets'),
          IconButton(icon: const Icon(Icons.file_download), onPressed: _importPresets, tooltip: 'Import Presets'),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: const PresetList(),
      ),
    );
  }
}

class PresetList extends ConsumerWidget {
  const PresetList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetsProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: presets.length + 1,
      itemBuilder: (context, index) {
        if (index == presets.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Preset'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPresetScreen()));
              },
            ),
          );
        }

        final preset = presets[index];
        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            leading: IconButton(
              icon: const Icon(Icons.copy, color: AppTheme.primaryAccent, size: 20),
              tooltip: 'Duplicate',
              onPressed: () {
                final duplicate = preset.copyWith(
                  id: uuid.v4(),
                  name: '\${preset.name} (Copy)',
                  isDefault: false,
                );
                ref.read(presetsProvider.notifier).addPreset(duplicate);
              },
            ),
            trailing: preset.isDefault
                ? const Icon(Icons.check_circle, color: AppTheme.primaryAccent)
                : IconButton(
                    icon: const Icon(Icons.circle_outlined, color: Colors.white54),
                    onPressed: () => ref.read(presetsProvider.notifier).setDefault(preset.id),
                  ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditPresetScreen(preset: preset)));
            },
          ),
        );
      },
    );
  }
}

class EditPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const EditPresetScreen({Key? key, this.preset}) : super(key: key);

  @override
  ConsumerState<EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<EditPresetScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _bodyController;
  late TextEditingController _stdoutPathController;
  late TextEditingController _stderrPathController;
  late TextEditingController _errorPathController;
  late TextEditingController _timePathController;
  late TextEditingController _memPathController;

  String _method = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _urlController = TextEditingController(text: p?.endpointUrl ?? '');
    _bodyController = TextEditingController(text: p?.bodyTemplate ?? '{"code": "{code}"}');
    _stdoutPathController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathController = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathController = TextEditingController(text: p?.errorPath ?? '');
    _timePathController = TextEditingController(text: p?.executionTimePath ?? '');
    _memPathController = TextEditingController(text: p?.memoryPath ?? '');
    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _headers = p?.headers.entries.toList() ?? [];
    _queryParams = p?.queryParams.entries.toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    _stdoutPathController.dispose();
    _stderrPathController.dispose();
    _errorPathController.dispose();
    _timePathController.dispose();
    _memPathController.dispose();
    super.dispose();
  }

  void _save() {
    final Map<String, String> headersMap = {};
    for (var h in _headers) {
      if (h.key.isNotEmpty) headersMap[h.key] = h.value;
    }

    final Map<String, String> queryMap = {};
    for (var q in _queryParams) {
      if (q.key.isNotEmpty) queryMap[q.key] = q.value;
    }

    final newPreset = CompilerPreset(
      id: widget.preset?.id ?? uuid.v4(),
      name: _nameController.text.isEmpty ? 'Untitled' : _nameController.text,
      endpointUrl: _urlController.text,
      method: _method,
      authType: _authType,
      headers: headersMap,
      queryParams: queryMap,
      bodyTemplate: _bodyController.text,
      stdoutPath: _stdoutPathController.text,
      stderrPath: _stderrPathController.text,
      errorPath: _errorPathController.text,
      executionTimePath: _timePathController.text,
      memoryPath: _memPathController.text,
      isDefault: widget.preset?.isDefault ?? false,
    );

    if (widget.preset == null) {
      ref.read(presetsProvider.notifier).addPreset(newPreset);
    } else {
      ref.read(presetsProvider.notifier).updatePreset(newPreset);
    }

    Navigator.pop(context);
  }

  void _testConnection() async {
    final Map<String, String> headersMap = {};
    for (var h in _headers) {
      if (h.key.isNotEmpty) headersMap[h.key] = h.value;
    }
    final Map<String, String> queryMap = {};
    for (var q in _queryParams) {
      if (q.key.isNotEmpty) queryMap[q.key] = q.value;
    }

    final testPreset = CompilerPreset(
      id: 'test',
      name: 'test',
      endpointUrl: _urlController.text,
      method: _method,
      authType: _authType,
      headers: headersMap,
      queryParams: queryMap,
      bodyTemplate: _bodyController.text,
      stdoutPath: _stdoutPathController.text,
      stderrPath: _stderrPathController.text,
      errorPath: _errorPathController.text,
      executionTimePath: _timePathController.text,
      memoryPath: _memPathController.text,
    );

    showDialog(context: context, builder: (_) => const AlertDialog(content: Text('Testing...')));

    final result = await CompilerService().executeCode(
      code: 'void main() { print("Hello from custom API"); }',
      stdin: '',
      preset: testPreset,
    );

    if (!mounted) return;
    Navigator.pop(context); // pop loading

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('STDOUT: \${result.stdout}'),
              Text('STDERR: \${result.stderr}'),
              Text('ERROR: \${result.error}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        backgroundColor: AppTheme.appBarColor,
        actions: [
          IconButton(icon: const Icon(Icons.play_circle_outline), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Platform Name')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'Endpoint URL')),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: AppTheme.primaryAccent),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _urlController.text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied URL')));
                  },
                )
              ],
            ),
            const SizedBox(height: 12),

            // Method Dropdown
            DropdownButtonFormField<String>(
              value: _method,
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 12),

            // Auth Dropdown
            DropdownButtonFormField<String>(
              value: _authType,
              dropdownColor: const Color(0xFF1A1A1A),
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (v) => setState(() => _authType = v!),
            ),
            const SizedBox(height: 24),

            const Text('Headers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ..._headers.asMap().entries.map((e) {
              int idx = e.key;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: e.value.key,
                        decoration: const InputDecoration(labelText: 'Key'),
                        onChanged: (v) => setState(() => _headers[idx] = MapEntry(v, _headers[idx].value)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: e.value.value,
                        decoration: const InputDecoration(labelText: 'Value'),
                        onChanged: (v) => setState(() => _headers[idx] = MapEntry(_headers[idx].key, v)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _headers.removeAt(idx)),
                    )
                  ],
                ),
              );
            }).toList(),
            TextButton.icon(
              onPressed: () => setState(() => _headers.add(const MapEntry('', ''))),
              icon: const Icon(Icons.add), label: const Text('Add Header'),
            ),
            const SizedBox(height: 24),

            const Text('Query Params', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ..._queryParams.asMap().entries.map((e) {
              int idx = e.key;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: e.value.key,
                        decoration: const InputDecoration(labelText: 'Key'),
                        onChanged: (v) => setState(() => _queryParams[idx] = MapEntry(v, _queryParams[idx].value)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: e.value.value,
                        decoration: const InputDecoration(labelText: 'Value'),
                        onChanged: (v) => setState(() => _queryParams[idx] = MapEntry(_queryParams[idx].key, v)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _queryParams.removeAt(idx)),
                    )
                  ],
                ),
              );
            }).toList(),
            TextButton.icon(
              onPressed: () => setState(() => _queryParams.add(const MapEntry('', ''))),
              icon: const Icon(Icons.add), label: const Text('Add Query Param'),
            ),
            const SizedBox(height: 24),

            const Text('Body Template (JSON)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Use {code} and {stdin} placeholders', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: '{"code": "{code}"}'),
            ),
            const SizedBox(height: 24),

            const Text('Response Mapping (Dot Notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(controller: _stdoutPathController, decoration: const InputDecoration(labelText: 'stdout path (e.g. data.output)')),
            const SizedBox(height: 8),
            TextField(controller: _stderrPathController, decoration: const InputDecoration(labelText: 'stderr path')),
            const SizedBox(height: 8),
            TextField(controller: _errorPathController, decoration: const InputDecoration(labelText: 'error path')),
            const SizedBox(height: 8),
            TextField(controller: _timePathController, decoration: const InputDecoration(labelText: 'execution time path')),
            const SizedBox(height: 8),
            TextField(controller: _memPathController, decoration: const InputDecoration(labelText: 'memory path')),
            const SizedBox(height: 32),

            if (widget.preset != null && !widget.preset!.isDefault)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  ref.read(presetsProvider.notifier).deletePreset(widget.preset!.id);
                  Navigator.pop(context);
                },
                child: const Text('Delete Preset', style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
