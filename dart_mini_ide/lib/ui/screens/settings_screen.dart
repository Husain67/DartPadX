import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!settings.useDefaultCompiler)
            IconButton(
              icon: const Icon(Icons.file_upload, color: Colors.white),
              tooltip: 'Export Presets',
              onPressed: () => _exportPresets(settings.presets),
            ),
          if (!settings.useDefaultCompiler)
            IconButton(
              icon: const Icon(Icons.file_download, color: Colors.white),
              tooltip: 'Import Presets',
              onPressed: _importPresets,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Execution Environment'),
          SwitchListTile(
            title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Turn off to use custom endpoints', style: TextStyle(color: Colors.white54)),
            activeColor: const Color(0xFFFACC15),
            value: settings.useDefaultCompiler,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).setUseDefaultCompiler(val);
            },
          ),
          if (!settings.useDefaultCompiler) ...[
            const Divider(color: Colors.white24, height: 32),
            _buildSectionTitle('Custom Compiler Presets'),
            ...settings.presets.map((preset) => _buildPresetTile(preset, settings.activePresetId)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add Custom Preset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _openPresetEditor(null),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFFACC15),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPresetTile(CompilerPreset preset, String? activeId) {
    final isActive = preset.id == activeId;
    return Card(
      color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFF0D0D0D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? const Color(0xFFFACC15) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(preset.endpoint, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: () => _openPresetEditor(preset),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
              onPressed: () => _duplicatePreset(preset),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
              onPressed: () {
                ref.read(settingsProvider.notifier).deletePreset(preset.id);
                if (isActive) ref.read(settingsProvider.notifier).setActivePreset('');
              },
            ),
          ],
        ),
        onTap: () {
          ref.read(settingsProvider.notifier).setActivePreset(preset.id);
        },
      ),
    );
  }

  void _duplicatePreset(CompilerPreset preset) {
    final newPreset = CompilerPreset(
      id: const Uuid().v4(),
      name: '${preset.name} (Copy)',
      endpoint: preset.endpoint,
      method: preset.method,
      authType: preset.authType,
      headers: Map.from(preset.headers),
      queryParams: Map.from(preset.queryParams),
      requestBodyTemplate: preset.requestBodyTemplate,
      stdoutPath: preset.stdoutPath,
      stderrPath: preset.stderrPath,
      errorPath: preset.errorPath,
      executionTimePath: preset.executionTimePath,
      memoryPath: preset.memoryPath,
    );
    ref.read(settingsProvider.notifier).addPreset(newPreset);
    Fluttertoast.showToast(msg: "Preset duplicated");
  }

  void _openPresetEditor(CompilerPreset? preset) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PresetEditorScreen(preset: preset)),
    );
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    try {
      final data = presets.map((p) => {
        'id': p.id,
        'name': p.name,
        'endpoint': p.endpoint,
        'method': p.method,
        'authType': p.authType,
        'headers': p.headers,
        'queryParams': p.queryParams,
        'requestBodyTemplate': p.requestBodyTemplate,
        'stdoutPath': p.stdoutPath,
        'stderrPath': p.stderrPath,
        'errorPath': p.errorPath,
        'executionTimePath': p.executionTimePath,
        'memoryPath': p.memoryPath,
      }).toList();

      final jsonStr = jsonEncode(data);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/dart_mini_presets.json');
      await tempFile.writeAsString(jsonStr);

      await Share.shareXFiles([XFile(tempFile.path)], text: 'DartMini IDE Compiler Presets');
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to export presets", backgroundColor: Colors.red);
    }
  }

  Future<void> _importPresets() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        final List<dynamic> data = jsonDecode(jsonStr);

        for (var item in data) {
          final preset = CompilerPreset(
            id: const Uuid().v4(), // Regenerate ID to avoid conflicts
            name: item['name'] ?? 'Imported Preset',
            endpoint: item['endpoint'] ?? '',
            method: item['method'] ?? 'POST',
            authType: item['authType'] ?? 'None',
            headers: Map<String, String>.from(item['headers'] ?? {}),
            queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
            requestBodyTemplate: item['requestBodyTemplate'] ?? '',
            stdoutPath: item['stdoutPath'] ?? '',
            stderrPath: item['stderrPath'] ?? '',
            errorPath: item['errorPath'] ?? '',
            executionTimePath: item['executionTimePath'] ?? '',
            memoryPath: item['memoryPath'] ?? '',
          );
          ref.read(settingsProvider.notifier).addPreset(preset);
        }
        Fluttertoast.showToast(msg: "Presets imported successfully", backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing JSON", backgroundColor: Colors.red);
    }
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  String _method = 'POST';
  String _authType = 'None';
  Map<String, String> _headers = {};
  Map<String, String> _queryParams = {};

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _endpointCtrl = TextEditingController(text: p?.endpoint ?? '');
    _bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{\n  "code": "{code}",\n  "language": "dart"\n}');
    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? 'stdout');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? 'stderr');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? 'error');
    _timePathCtrl = TextEditingController(text: p?.executionTimePath ?? 'time');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? 'memory');

    _method = p?.method ?? 'POST';
    _authType = p?.authType ?? 'None';
    _headers = p != null ? Map.from(p.headers) : {'Content-Type': 'application/json'};
    _queryParams = p != null ? Map.from(p.queryParams) : {};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _endpointCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _timePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _savePreset() {
    if (_nameCtrl.text.isEmpty || _endpointCtrl.text.isEmpty) {
      Fluttertoast.showToast(msg: "Name and Endpoint are required", backgroundColor: Colors.red);
      return;
    }

    final preset = CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpoint: _endpointCtrl.text,
      method: _method,
      authType: _authType,
      headers: _headers,
      queryParams: _queryParams,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    if (widget.preset == null) {
      ref.read(settingsProvider.notifier).addPreset(preset);
    } else {
      ref.read(settingsProvider.notifier).updatePreset(preset);
    }

    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset saved", backgroundColor: Colors.green);
  }

  Future<void> _testConnection() async {
    Fluttertoast.showToast(msg: "Testing connection...");
    try {
      final uri = Uri.parse(_endpointCtrl.text).replace(queryParameters: _queryParams.isEmpty ? null : _queryParams);
      final request = http.Request(_method, uri);

      request.headers.addAll(_headers);

      String body = _bodyCtrl.text;
      body = body.replaceAll('{code}', jsonEncode("print('Hello from custom API');").replaceAll(RegExp(r'^"|"$'), ''));
      body = body.replaceAll('{language}', 'dart');
      body = body.replaceAll('{stdin}', '');

      if (_method != 'GET') {
        request.body = body;
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Test Result (${response.statusCode})', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Text(responseBody, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFFFACC15))),
            ),
          ],
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection failed: $e", backgroundColor: Colors.red);
    }
  }

  Widget _buildMapEditor(String title, Map<String, String> map, Function(Map<String, String>) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
              onPressed: () {
                _showMapEntryDialog('Add $title Entry', '', '', (k, v) {
                  setState(() => map[k] = v);
                  onChanged(map);
                });
              },
            )
          ],
        ),
        if (map.isEmpty) const Text('None', style: TextStyle(color: Colors.white38)),
        ...map.entries.map((e) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(e.key, style: const TextStyle(color: Colors.white70)),
          subtitle: Text(e.value, style: const TextStyle(color: Colors.white54)),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
            onPressed: () {
              setState(() => map.remove(e.key));
              onChanged(map);
            },
          ),
        )),
      ],
    );
  }

  void _showMapEntryDialog(String title, String initialKey, String initialValue, Function(String, String) onSave) {
    final kCtrl = TextEditingController(text: initialKey);
    final vCtrl = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: kCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Key', labelStyle: TextStyle(color: Colors.white54))),
            TextField(controller: vCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Value', labelStyle: TextStyle(color: Colors.white54))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15)),
            onPressed: () {
              if (kCtrl.text.isNotEmpty) {
                onSave(kCtrl.text, vCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFFFACC15)),
            onPressed: _savePreset,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Platform Name', labelStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _endpointCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Endpoint URL', labelStyle: TextStyle(color: Colors.white54), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _method,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.white54)),
            items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (val) => setState(() => _method = val!),
          ),
          const SizedBox(height: 24),
          _buildMapEditor('Headers', _headers, (m) => _headers = m),
          const Divider(color: Colors.white24),
          _buildMapEditor('Query Parameters', _queryParams, (m) => _queryParams = m),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text('Request Body Template (JSON)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const Text('Placeholders: {code}, {language}, {stdin}', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyCtrl,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
            maxLines: 6,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const Divider(color: Colors.white24, height: 32),
          const Text('Response Mapping (Dot Notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildMappingField('Stdout Path', _stdoutPathCtrl),
          _buildMappingField('Stderr Path', _stderrPathCtrl),
          _buildMappingField('Error Path', _errorPathCtrl),
          _buildMappingField('Execution Time Path', _timePathCtrl),
          _buildMappingField('Memory Path', _memoryPathCtrl),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.api, color: Colors.black),
            label: const Text('Test Connection', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _testConnection,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMappingField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          isDense: true,
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
        ),
      ),
    );
  }
}
