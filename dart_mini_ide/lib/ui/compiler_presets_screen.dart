import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';
import '../services/api_client.dart';
import '../utils/colors.dart';

class CompilerPresetsScreen extends ConsumerStatefulWidget {
  const CompilerPresetsScreen({super.key});

  @override
  ConsumerState<CompilerPresetsScreen> createState() => _CompilerPresetsScreenState();
}

class _CompilerPresetsScreenState extends ConsumerState<CompilerPresetsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler APIs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openPresetEditor(context, ref, null),
            tooltip: 'Add New Preset',
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: settingsState.presets.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.toolbarButtonBorder),
        itemBuilder: (context, index) {
          final preset = settingsState.presets[index];
          final isActive = preset.id == settingsState.activePresetId;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tileColor: isActive ? AppColors.tabActive : null,
            leading: Icon(
              isActive ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isActive ? AppColors.accentYellow : Colors.grey,
            ),
            title: Text(
              preset.name,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
            subtitle: Text(
              preset.endpointUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _openPresetEditor(context, ref, preset),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'duplicate') {
                      ref.read(settingsProvider.notifier).duplicatePreset(preset);
                      Fluttertoast.showToast(msg: 'Preset duplicated');
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref, preset);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'duplicate',
                      child: Text('Duplicate'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: AppColors.outputStderr)),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              ref.read(settingsProvider.notifier).setActivePreset(preset.id);
              Fluttertoast.showToast(msg: 'Selected ${preset.name}');
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CompilerPreset preset) {
    if (ref.read(settingsProvider).presets.length <= 1) {
      Fluttertoast.showToast(msg: 'Cannot delete the last preset.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('Delete Preset?'),
        content: Text('Are you sure you want to delete "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).deletePreset(preset.id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Preset deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.outputStderr,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openPresetEditor(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresetEditorScreen(preset: preset),
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
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _httpMethod;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final List<String> _httpMethods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? 'New Compiler');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? 'https://api.example.com/execute');
    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyTemplateCtrl = TextEditingController(
        text: p?.bodyTemplate ?? '{\n  "code": {code},\n  "language": "dart",\n  "stdin": "{stdin}"\n}');
    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? 'stdout');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? 'stderr');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? 'error');
    _timePathCtrl = TextEditingController(text: p?.executionTimePath ?? 'executionTime');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? 'memory');

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _timePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameCtrl.text,
        endpointUrl: _urlCtrl.text,
        httpMethod: _httpMethod,
        authType: _authType,
        authValue: _authValueCtrl.text,
        headers: Map.fromEntries(_headers),
        queryParams: Map.fromEntries(_queryParams),
        bodyTemplate: _bodyTemplateCtrl.text,
        stdoutPath: _stdoutPathCtrl.text,
        stderrPath: _stderrPathCtrl.text,
        errorPath: _errorPathCtrl.text,
        executionTimePath: _timePathCtrl.text,
        memoryPath: _memoryPathCtrl.text,
        isDefault: widget.preset?.isDefault ?? false,
      );

      if (widget.preset == null) {
        ref.read(settingsProvider.notifier).addPreset(newPreset);
        Fluttertoast.showToast(msg: 'Preset created');
      } else {
        ref.read(settingsProvider.notifier).updatePreset(newPreset);
        Fluttertoast.showToast(msg: 'Preset updated');
      }
      Navigator.pop(context);
    }
  }

  void _testConnection() async {
    Fluttertoast.showToast(msg: 'Testing connection...');
    final tempPreset = CompilerPreset(
      id: 'test',
      name: 'Test',
      endpointUrl: _urlCtrl.text,
      httpMethod: _httpMethod,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      bodyTemplate: _bodyTemplateCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errorPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memoryPathCtrl.text,
      isDefault: false,
    );

    final client = ApiClient();
    try {
      final result = await client.executeCode(
        code: "void main() { print('Hello from custom API'); }",
        preset: tempPreset,
      );

      _showTestResultDialog(result);
    } catch (e) {
      _showTestResultDialog({'error': e.toString()});
    }
  }

  void _showTestResultDialog(Map<String, String> result) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: result.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('${e.key}: ${e.value.isEmpty ? "<empty>" : e.value}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.editorBackground,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
      ),
    );
  }

  Widget _buildKeyValueList(String title, List<MapEntry<String, String>> items, Function(List<MapEntry<String, String>>) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentYellow)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.accentYellow),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('New Key', 'New Value'));
                  onUpdate(items);
                });
              },
            ),
          ],
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text('No items added', style: TextStyle(color: Colors.grey)),
          ),
        ...items.asMap().entries.map((entry) {
          int idx = entry.key;
          var mapEntry = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: mapEntry.key,
                    onChanged: (val) {
                      setState(() {
                        items[idx] = MapEntry(val, mapEntry.value);
                        onUpdate(items);
                      });
                    },
                    decoration: const InputDecoration(hintText: 'Key', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: mapEntry.value,
                    onChanged: (val) {
                      setState(() {
                        items[idx] = MapEntry(mapEntry.key, val);
                        onUpdate(items);
                      });
                    },
                    decoration: const InputDecoration(hintText: 'Value', isDense: true),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: AppColors.outputStderr),
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
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'Add Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreset,
            tooltip: 'Save Preset',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField('Preset Name', _nameCtrl),
            _buildTextField(
              'Endpoint URL',
              _urlCtrl,
              suffixIcon: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                  Fluttertoast.showToast(msg: 'URL copied');
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _httpMethod,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: _httpMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => _httpMethod = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    items: _authTypes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => _authType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_authType != 'None')
              _buildTextField('Auth Value / Key', _authValueCtrl),

            const Divider(),
            _buildKeyValueList('Headers', _headers, (val) => _headers = val),
            _buildKeyValueList('Query Params', _queryParams, (val) => _queryParams = val),
            const Divider(),

            const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentYellow)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Use placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            _buildTextField('JSON Body', _bodyTemplateCtrl, maxLines: 8),

            const Divider(),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentYellow)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('e.g., "result.run_status.output". Leave empty if not provided.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            _buildTextField('Stdout Path', _stdoutPathCtrl),
            _buildTextField('Stderr Path', _stderrPathCtrl),
            _buildTextField('Error Path', _errorPathCtrl),
            _buildTextField('Execution Time Path', _timePathCtrl),
            _buildTextField('Memory Path', _memoryPathCtrl),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tabActive,
                foregroundColor: AppColors.accentYellow,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}