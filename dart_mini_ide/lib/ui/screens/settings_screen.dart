import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../../providers/settings_provider.dart';
import '../../providers/execution_provider.dart';
import '../../models/compiler_preset.dart';
import '../../core/constants.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppConstants.bgColorStart,
      ),
      body: Container(
        decoration: AppTheme.scaffoldGradient,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler'),
              subtitle: const Text('Use the built-in OneCompiler configuration.'),
              value: settingsState.useDefaultOneCompiler,
              onChanged: (val) => ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(val),
              activeThumbColor: AppConstants.accentColor,
            ),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Compiler Presets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPresetEditor(context, ref, null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...settingsState.presets.map((preset) => Card(
                  color: AppConstants.bgColorStart,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (preset.id == settingsState.activePresetId && !settingsState.useDefaultOneCompiler)
                          const Icon(Icons.check_circle, color: AppConstants.successColor, size: 20),
                        PopupMenuButton<String>(
                          onSelected: (val) {
                            if (val == 'select') {
                              ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                              ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
                            } else if (val == 'edit') {
                              _showPresetEditor(context, ref, preset);
                            } else if (val == 'duplicate') {
                              ref.read(settingsProvider.notifier).duplicatePreset(preset);
                            } else if (val == 'delete') {
                              ref.read(settingsProvider.notifier).deletePreset(preset.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'select', child: Text('Set Active')),
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                            if (settingsState.presets.length > 1)
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final jsonString = ref.read(settingsProvider.notifier).exportPresets();
                    Clipboard.setData(ClipboardData(text: jsonString));
                    Fluttertoast.showToast(msg: "Exported to clipboard");
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Export JSON'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importPresets(context, ref),
                  icon: const Icon(Icons.download),
                  label: const Text('Import JSON'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _importPresets(BuildContext context, WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        ref.read(settingsProvider.notifier).importPresets(content);
        Fluttertoast.showToast(msg: "Presets imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to import presets");
    }
  }

  void _showPresetEditor(BuildContext context, WidgetRef ref, CompilerPreset? presetToEdit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresetEditorScreen(preset: presetToEdit),
      ),
    );
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
  late TextEditingController _urlCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _authKeyCtrl;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyTemplateCtrl;

  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final List<String> _methods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? 'New Preset');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _method = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authKeyCtrl = TextEditingController(text: p?.authKey ?? '');
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyTemplateCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{"code":"{code}"}');

    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timePathCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _authKeyCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _timePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final Map<String, String> headerMap = {};
    for (var h in _headers) {
      if (h.key.isNotEmpty) headerMap[h.key] = h.value;
    }

    final Map<String, String> queryMap = {};
    for (var q in _queryParams) {
      if (q.key.isNotEmpty) queryMap[q.key] = q.value;
    }

    final preset = CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.isEmpty ? 'Unnamed Preset' : _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authKey: _authKeyCtrl.text,
      authValue: _authValueCtrl.text,
      headers: headerMap,
      queryParams: queryMap,
      requestBodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    if (widget.preset == null) {
      ref.read(settingsProvider.notifier).addPreset(preset);
      Fluttertoast.showToast(msg: "Preset created");
    } else {
      ref.read(settingsProvider.notifier).updatePreset(preset);
      Fluttertoast.showToast(msg: "Preset updated");
    }
    Navigator.pop(context);
  }

  Widget _buildTableSection(String title, List<MapEntry<String, String>> items, Function(List<MapEntry<String, String>>) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppConstants.accentColor),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('', ''));
                  onUpdate(items);
                });
              },
            ),
          ],
        ),
        ...items.asMap().entries.map((e) {
          int idx = e.key;
          var entry = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.key,
                    decoration: const InputDecoration(hintText: 'Key', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                    onChanged: (v) {
                      items[idx] = MapEntry(v, entry.value);
                      onUpdate(items);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value,
                    decoration: const InputDecoration(hintText: 'Value', contentPadding: EdgeInsets.symmetric(horizontal: 8)),
                    onChanged: (v) {
                      items[idx] = MapEntry(entry.key, v);
                      onUpdate(items);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      items.removeAt(idx);
                      onUpdate(items);
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
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
      body: Container(
        decoration: AppTheme.scaffoldGradient,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Platform Name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      decoration: const InputDecoration(labelText: 'Endpoint URL'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _method,
                      decoration: const InputDecoration(labelText: 'HTTP Method'),
                      items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setState(() => _method = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _authType,
                      decoration: const InputDecoration(labelText: 'Auth Type'),
                      items: _authTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (v) => setState(() => _authType = v!),
                    ),
                  ),
                ],
              ),
              if (_authType != 'None' && _authType != 'Bearer Token') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _authKeyCtrl,
                  decoration: const InputDecoration(labelText: 'Auth Key (e.g. Header name or Username)'),
                ),
              ],
              if (_authType != 'None') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _authValueCtrl,
                  decoration: InputDecoration(labelText: _authType == 'Basic Auth' ? 'Auth Value (Password)' : 'Auth Value (Token/Key)'),
                  obscureText: true,
                ),
              ],
              const SizedBox(height: 24),
              _buildTableSection('Headers', _headers, (v) => _headers = v),
              const SizedBox(height: 16),
              _buildTableSection('Query Parameters', _queryParams, (v) => _queryParams = v),
              const SizedBox(height: 24),
              const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Use placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyTemplateCtrl,
                maxLines: 6,
                decoration: const InputDecoration(hintText: '{"code":"{code}","stdin":"{stdin}"}'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text('Response Mapping (Dot Notation Paths)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: _stdoutPathCtrl, decoration: const InputDecoration(labelText: 'stdout path (e.g., result.output)')),
              const SizedBox(height: 8),
              TextField(controller: _stderrPathCtrl, decoration: const InputDecoration(labelText: 'stderr path')),
              const SizedBox(height: 8),
              TextField(controller: _errorPathCtrl, decoration: const InputDecoration(labelText: 'error path')),
              const SizedBox(height: 8),
              TextField(controller: _timePathCtrl, decoration: const InputDecoration(labelText: 'executionTime path')),
              const SizedBox(height: 8),
              TextField(controller: _memoryPathCtrl, decoration: const InputDecoration(labelText: 'memory path')),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.bolt),
                  label: const Text('Test Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentColor,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _testConnection() async {
    Fluttertoast.showToast(msg: "Testing connection...");

    // Create a temporary preset for testing
    final testPreset = CompilerPreset(
      id: 'test_preset',
      name: 'Test',
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authKey: _authKeyCtrl.text,
      authValue: _authValueCtrl.text,
      headers: {for (var e in _headers) e.key: e.value},
      queryParams: {for (var e in _queryParams) e.key: e.value},
      requestBodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
    );

    // Call the execution provider with test code
    final notifier = ref.read(executionProvider.notifier);

    // Temporary swap of active preset state to test
    final originalSettings = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).addPreset(testPreset);
    ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
    ref.read(settingsProvider.notifier).setActivePreset(testPreset.id);

    try {
      await notifier.executeCode("void main() { print('Hello from custom API'); }");
      final executionState = ref.read(executionProvider);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConstants.bgColorEnd,
          title: const Text('Test Result', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Parsed Output:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  'stdout: ${executionState.stdout}\nstderr: ${executionState.stderr}\nerror: ${executionState.error}\ntime: ${executionState.executionTime}',
                  style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } finally {
      // Restore previous state
      ref.read(settingsProvider.notifier).deletePreset(testPreset.id);
      ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(originalSettings.useDefaultOneCompiler);
      if (originalSettings.activePresetId.isNotEmpty) {
        ref.read(settingsProvider.notifier).setActivePreset(originalSettings.activePresetId);
      }
    }
  }
}
