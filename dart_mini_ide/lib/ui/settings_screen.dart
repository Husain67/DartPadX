import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/preset_provider.dart';
import '../models/compiler_preset.dart';
import '../services/execution_service.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final presetState = ref.watch(presetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('Compiler Presets', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload, color: Colors.white),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(presetState.presets),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: presetState.presets.length,
        itemBuilder: (context, index) {
          final preset = presetState.presets[index];
          final isActive = presetState.activePreset?.id == preset.id;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isActive ? const Color(0xFFFACC15) : Colors.transparent),
            ),
            child: ListTile(
              title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    const Icon(Icons.check_circle, color: Color(0xFFFACC15)),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => _editPreset(context, ref, preset),
                  ),
                  if (!preset.isDefault)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => ref.read(presetProvider.notifier).deletePreset(preset.id),
                    ),
                ],
              ),
              onTap: () => ref.read(presetProvider.notifier).setActivePreset(preset.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFACC15),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _editPreset(context, ref, null),
      ),
    );
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset? existingPreset) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PresetEditorScreen(preset: existingPreset)),
    );
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    try {
      final list = presets.map((p) => {
        'name': p.name,
        'endpointUrl': p.endpointUrl,
        'httpMethod': p.httpMethod,
        'authType': p.authType,
        'authValue': p.authValue,
        'headers': p.headers,
        'queryParams': p.queryParams,
        'requestBodyTemplate': p.requestBodyTemplate,
        'stdoutPath': p.stdoutPath,
        'stderrPath': p.stderrPath,
        'errorPath': p.errorPath,
        'executionTimePath': p.executionTimePath,
        'memoryPath': p.memoryPath,
      }).toList();

      final jsonStr = jsonEncode(list);
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/presets.json';
      final file = File(path);
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(path)], text: 'Exported Presets from DartMini IDE');
    } catch (e) {
      Fluttertoast.showToast(msg: "Error exporting presets", backgroundColor: Colors.red);
    }
  }

  Future<void> _importPresets(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        final list = jsonDecode(content) as List;
        final uuid = const Uuid();

        for (var map in list) {
          final p = CompilerPreset(
            id: uuid.v4(),
            name: map['name'] ?? 'Imported Preset',
            endpointUrl: map['endpointUrl'] ?? '',
            httpMethod: map['httpMethod'] ?? 'POST',
            authType: map['authType'] ?? 'None',
            authValue: map['authValue'] ?? '',
            headers: Map<String, String>.from(map['headers'] ?? {}),
            queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
            requestBodyTemplate: map['requestBodyTemplate'] ?? '',
            stdoutPath: map['stdoutPath'] ?? '',
            stderrPath: map['stderrPath'] ?? '',
            errorPath: map['errorPath'] ?? '',
            executionTimePath: map['executionTimePath'] ?? '',
            memoryPath: map['memoryPath'] ?? '',
          );
          ref.read(presetProvider.notifier).addPreset(p);
        }
        Fluttertoast.showToast(msg: "Presets imported successfully", backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing presets", backgroundColor: Colors.red);
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
  final _formKey = GlobalKey<FormState>();
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
  late List<MapEntry<String, String>> _headers;
  late List<MapEntry<String, String>> _queryParams;

  @override
  void initState() {
    super.initState();
    _name = widget.preset?.name ?? '';
    _endpointUrl = widget.preset?.endpointUrl ?? '';
    _httpMethod = widget.preset?.httpMethod ?? 'POST';
    _authType = widget.preset?.authType ?? 'None';
    _authValue = widget.preset?.authValue ?? '';
    _requestBodyTemplate = widget.preset?.requestBodyTemplate ?? '{"code": "{code}", "language": "{language}"}';
    _stdoutPath = widget.preset?.stdoutPath ?? 'stdout';
    _stderrPath = widget.preset?.stderrPath ?? 'stderr';
    _errorPath = widget.preset?.errorPath ?? 'error';
    _executionTimePath = widget.preset?.executionTimePath ?? '';
    _memoryPath = widget.preset?.memoryPath ?? '';
    _headers = widget.preset?.headers.entries.toList() ?? [const MapEntry('Content-Type', 'application/json')];
    _queryParams = widget.preset?.queryParams.entries.toList() ?? [];
  }

  CompilerPreset _buildTempPreset() {
    return CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _name,
      endpointUrl: _endpointUrl,
      httpMethod: _httpMethod,
      authType: _authType,
      authValue: _authValue,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      requestBodyTemplate: _requestBodyTemplate,
      stdoutPath: _stdoutPath,
      stderrPath: _stderrPath,
      errorPath: _errorPath,
      executionTimePath: _executionTimePath,
      memoryPath: _memoryPath,
      isDefault: widget.preset?.isDefault ?? false,
    );
  }

  void _testConnection() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final tempPreset = _buildTempPreset();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFFFACC15))),
      );

      final result = await ExecutionService.executeCode("void main() { print('Hello from custom API'); }", tempPreset);

      if (mounted) {
        Navigator.pop(context); // close loader
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1a1a1a),
            title: const Text('Test Connection Result', style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Stdout:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(result.stdout, style: const TextStyle(color: Colors.green, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  const Text('Stderr:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(result.stderr, style: const TextStyle(color: Colors.red, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  const Text('Error:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(result.error, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  Text('Time: ${result.executionTime}ms, Mem: ${result.memory}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Close', style: TextStyle(color: Color(0xFFFACC15))),
                onPressed: () => Navigator.pop(ctx),
              )
            ],
          ),
        );
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = _buildTempPreset();

      if (widget.preset == null) {
        ref.read(presetProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(presetProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: Color(0xFFFACC15)), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildField('Platform Name', _name, (v) => _name = v!),
            _buildField('Endpoint URL', _endpointUrl, (v) => _endpointUrl = v!),
            _buildDropdown('HTTP Method', _httpMethod, ['POST', 'GET', 'PUT'], (v) => setState(() => _httpMethod = v!)),
            _buildDropdown('Auth Type', _authType, ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'], (v) => setState(() => _authType = v!)),
            if (_authType != 'None')
              _buildField('Auth Value', _authValue, (v) => _authValue = v!),
            const SizedBox(height: 16),

            const Text('Headers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            _buildDynamicTable(_headers),
            const SizedBox(height: 16),

            const Text('Query Parameters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            _buildDynamicTable(_queryParams),
            const SizedBox(height: 16),

            const Text('Request Body Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Available placeholders: {code}, {language}, {stdin}', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _requestBodyTemplate,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF1a1a1a),
                border: OutlineInputBorder(),
              ),
              onSaved: (v) => _requestBodyTemplate = v!,
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (dot notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            _buildField('stdout path', _stdoutPath, (v) => _stdoutPath = v!),
            _buildField('stderr path', _stderrPath, (v) => _stderrPath = v!),
            _buildField('error path', _errorPath, (v) => _errorPath = v!),
            _buildField('execution time path', _executionTimePath, (v) => _executionTimePath = v!),
            _buildField('memory path', _memoryPath, (v) => _memoryPath = v!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.speed, color: Colors.black),
              label: const Text('Test Connection', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFACC15),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String initialValue, Function(String?) onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initialValue,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF1a1a1a),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFACC15))),
        ),
        validator: (v) => v!.isEmpty && label != 'execution time path' && label != 'memory path' ? 'Required' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: const Color(0xFF1a1a1a),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF1a1a1a),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDynamicTable(List<MapEntry<String, String>> list) {
    return Column(
      children: [
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          var mapEntry = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: mapEntry.key,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Key',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Color(0xFF1a1a1a),
                      isDense: true,
                    ),
                    onChanged: (v) => list[idx] = MapEntry(v, list[idx].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: mapEntry.value,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Value',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Color(0xFF1a1a1a),
                      isDense: true,
                    ),
                    onChanged: (v) => list[idx] = MapEntry(list[idx].key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () => setState(() => list.removeAt(idx)),
                )
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => list.add(const MapEntry('', ''))),
          icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
          label: const Text('Add Row', style: TextStyle(color: Color(0xFFFACC15))),
        )
      ],
    );
  }
}
