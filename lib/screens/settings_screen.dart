import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  CompilerPreset? _selectedPreset;

  void _selectPreset(CompilerPreset preset) {
    setState(() {
      _selectedPreset = preset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    // Auto-select active on first load if nothing is selected
    if (_selectedPreset == null && compilerState.presets.isNotEmpty) {
      _selectedPreset = compilerState.activePreset;
    }

    // Refresh selected from provider to get latest edits
    if (_selectedPreset != null) {
      try {
        _selectedPreset = compilerState.presets.firstWhere((p) => p.id == _selectedPreset!.id);
      } catch (e) {
        _selectedPreset = compilerState.presets.isNotEmpty ? compilerState.presets.first : null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom, allowedExtensions: ['json']
                );
                if (result != null && result.files.single.path != null) {
                  File file = File(result.files.single.path!);
                  String content = await file.readAsString();
                  List<dynamic> jsonList = jsonDecode(content);
                  for (var item in jsonList) {
                    final preset = CompilerPreset.fromMap(item).copyWith(
                      id: const Uuid().v4(),
                      isSystem: false,
                      isDefault: false,
                    );
                    ref.read(compilerProvider.notifier).addPreset(preset);
                  }
                  Fluttertoast.showToast(msg: "Imported \${jsonList.length} presets");
                }
              } catch (e) {
                Fluttertoast.showToast(msg: "Failed to import presets");
              }
            },
            tooltip: 'Import Presets',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              try {
                final presets = ref.read(compilerProvider).presets;
                final jsonStr = jsonEncode(presets.map((p) => p.toMap()).toList());
                Directory? dir;
                if (Platform.isAndroid) {
                  dir = await getExternalStorageDirectory();
                } else {
                  dir = await getApplicationDocumentsDirectory();
                }
                if (dir != null) {
                  final path = '${dir.path}/presets_export.json';
                  final file = File(path);
                  await file.writeAsString(jsonStr);
                  Fluttertoast.showToast(msg: "Exported to \$path");
                  Share.shareXFiles([XFile(path)], subject: 'DartMini IDE Compiler Presets');
                }
              } catch (e) {
                Fluttertoast.showToast(msg: "Failed to export presets");
              }
            },
            tooltip: 'Export Presets',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final newPreset = CompilerPreset(
                id: const Uuid().v4(),
                name: 'New Preset',
                endpoint: 'https://',
                method: 'POST',
                authType: 'None',
                headers: [],
                queryParams: [],
                bodyTemplate: '{"code": "{code}"}',
                stdoutPath: '',
                stderrPath: '',
                errorPath: '',
                executionTimePath: '',
                memoryPath: '',
                isSystem: false,
              );
              ref.read(compilerProvider.notifier).addPreset(newPreset);
              _selectPreset(newPreset);
            },
            tooltip: 'Add Preset',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile layout
            return Column(
              children: [
                SizedBox(
                  height: 120,
                  child: _PresetListView(
                    presets: compilerState.presets,
                    activePresetId: compilerState.activePresetId,
                    selectedPresetId: _selectedPreset?.id,
                    onSelect: _selectPreset,
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                Expanded(
                  child: _selectedPreset == null
                      ? const Center(child: Text('Select a preset'))
                      : _PresetEditor(preset: _selectedPreset!),
                ),
              ],
            );
          } else {
            // Tablet layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 250,
                  child: _PresetListView(
                    presets: compilerState.presets,
                    activePresetId: compilerState.activePresetId,
                    selectedPresetId: _selectedPreset?.id,
                    onSelect: _selectPreset,
                  ),
                ),
                const VerticalDivider(width: 1, color: Colors.white24),
                Expanded(
                  child: _selectedPreset == null
                      ? const Center(child: Text('Select a preset'))
                      : _PresetEditor(preset: _selectedPreset!),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _PresetListView extends ConsumerWidget {
  final List<CompilerPreset> presets;
  final String activePresetId;
  final String? selectedPresetId;
  final Function(CompilerPreset) onSelect;

  const _PresetListView({
    required this.presets,
    required this.activePresetId,
    required this.selectedPresetId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isActive = preset.id == activePresetId;
        final isSelected = preset.id == selectedPresetId;

        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor: Colors.white10,
          leading: Icon(
            preset.isSystem ? Icons.lock : Icons.settings_ethernet,
            color: isActive ? Theme.of(context).colorScheme.primary : Colors.white54,
          ),
          title: Text(
            preset.name,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          trailing: isActive ? const Icon(Icons.check_circle, color: Color(0xFFFACC15), size: 16) : null,
          onTap: () => onSelect(preset),
        );
      },
    );
  }
}

class _PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const _PresetEditor({required this.preset});

  @override
  ConsumerState<_PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<_PresetEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late TextEditingController _bodyTemplateCtrl;

  // Response mappings
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  late String _selectedMethod;
  late String _selectedAuthType;

  late List<Map<String, String>> _headers;
  late List<Map<String, String>> _queryParams;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(_PresetEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset.id != widget.preset.id) {
      _initControllers();
    }
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _endpointCtrl = TextEditingController(text: widget.preset.endpoint);
    _bodyTemplateCtrl = TextEditingController(text: widget.preset.bodyTemplate);
    _stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorCtrl = TextEditingController(text: widget.preset.errorPath);
    _timeCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memoryCtrl = TextEditingController(text: widget.preset.memoryPath);

    _selectedMethod = widget.preset.method;
    _selectedAuthType = widget.preset.authType;

    _headers = List<Map<String, String>>.from(widget.preset.headers.map((m) => Map<String, String>.from(m)));
    _queryParams = List<Map<String, String>>.from(widget.preset.queryParams.map((m) => Map<String, String>.from(m)));
  }

  void _savePreset() {
    if (widget.preset.isSystem) return;

    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpoint: _endpointCtrl.text,
      method: _selectedMethod,
      authType: _selectedAuthType,
      bodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memoryCtrl.text,
      headers: _headers,
      queryParams: _queryParams,
    );
    ref.read(compilerProvider.notifier).updatePreset(updated);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _endpointCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutCtrl.dispose();
    _stderrCtrl.dispose();
    _errorCtrl.dispose();
    _timeCtrl.dispose();
    _memoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSystem = widget.preset.isSystem;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Editing: \${widget.preset.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (isSystem)
              const Chip(
                label: Text('System Preset (Read Only)', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.white10,
              ),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ref.read(compilerProvider.notifier).setActivePreset(widget.preset.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Set \${widget.preset.name} as active')));
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Set as Active'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.preset.isDefault ? Colors.grey : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => ref.read(compilerProvider.notifier).duplicatePreset(widget.preset.id),
              icon: const Icon(Icons.copy, size: 18, color: Colors.white),
              label: const Text('Duplicate', style: TextStyle(color: Colors.white)),
            ),
            if (!isSystem) ...[
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  ref.read(compilerProvider.notifier).deletePreset(widget.preset.id);
                },
              ),
            ]
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Basic Setup'),
        _buildTextField('Preset Name', _nameCtrl, enabled: !isSystem),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder()),
                items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: isSystem ? null : (v) {
                  setState(() => _selectedMethod = v!);
                  _savePreset();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField('Endpoint URL', _endpointCtrl, enabled: !isSystem, suffixIcon: IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _endpointCtrl.text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied')));
                },
              )),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Headers & Params'),
        DropdownButtonFormField<String>(
          value: _selectedAuthType,
          decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
          items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: isSystem ? null : (v) {
            setState(() => _selectedAuthType = v!);
            _savePreset();
          },
        ),
        const SizedBox(height: 16),
        _buildDynamicTable('Headers', _headers, isSystem),
        const SizedBox(height: 16),
        _buildDynamicTable('Query Params', _queryParams, isSystem),

        const SizedBox(height: 24),
        _buildSectionHeader('Request Body Template'),
        const Text(
          'Use placeholders: {code}, {stdin}, {language}',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyTemplateCtrl,
          enabled: !isSystem,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'e.g. {"code": "{code}"}',
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          onChanged: (_) => _savePreset(),
        ),

        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _testConnection(context),
            icon: const Icon(Icons.network_ping),
            label: const Text('Test Connection'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 24),
        _buildSectionHeader('Response Mapping (Dot Notation)'),
        const Text('e.g. "result.output"', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        _buildTextField('Stdout Path', _stdoutCtrl, enabled: !isSystem),
        _buildTextField('Stderr Path', _stderrCtrl, enabled: !isSystem),
        _buildTextField('Error/Compile Path', _errorCtrl, enabled: !isSystem),
        _buildTextField('Execution Time Path', _timeCtrl, enabled: !isSystem),
        _buildTextField('Memory Path', _memoryCtrl, enabled: !isSystem),

      ],
    );
  }

  Future<void> _testConnection(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text("Testing Connection..."),
          ],
        ),
      ),
    );

    try {
      final code = "void main() { print('Hello from custom API'); }";
      final stdin = "";

      final headers = <String, String>{};
      for (var h in widget.preset.headers) {
        if (h['key']!.isNotEmpty) headers[h['key']!] = h['value']!;
      }

      String bodyStr = widget.preset.bodyTemplate
          .replaceAll('{code}', jsonEncode(code).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{stdin}', jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), ''))
          .replaceAll('{language}', 'dart');

      final uri = Uri.parse(widget.preset.endpoint);

      http.Response response;
      if (widget.preset.method.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: headers, body: bodyStr);
      } else if (widget.preset.method.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: headers, body: bodyStr);
      } else {
        response = await http.get(uri, headers: headers);
      }

      Navigator.pop(context); // close loading

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Response (\${response.statusCode})'),
          content: SingleChildScrollView(
            child: Text(response.body, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context); // close loading
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: suffixIcon,
        ),
        onChanged: (_) => _savePreset(),
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<Map<String, String>> list, bool isSystem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (!isSystem)
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () {
                  setState(() {
                    list.add({'key': '', 'value': ''});
                  });
                  _savePreset();
                },
              )
          ],
        ),
        if (list.isEmpty)
          const Text('None', style: TextStyle(color: Colors.white54, fontSize: 12))
        else
          ...list.asMap().entries.map((entry) {
            int idx = entry.key;
            Map<String, String> item = entry.value;
            return Padding(
              key: ValueKey('\$title-\$idx'),
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      enabled: !isSystem,
                      controller: TextEditingController(text: item['key']),
                      decoration: const InputDecoration(hintText: 'Key', isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) { item['key'] = v; _savePreset(); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      enabled: !isSystem,
                      controller: TextEditingController(text: item['value']),
                      decoration: const InputDecoration(hintText: 'Value', isDense: true, border: OutlineInputBorder()),
                      onChanged: (v) { item['value'] = v; _savePreset(); },
                    ),
                  ),
                  if (!isSystem)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() { list.removeAt(idx); });
                        _savePreset();
                      },
                    )
                ],
              ),
            );
          }).toList()
      ],
    );
  }
}
