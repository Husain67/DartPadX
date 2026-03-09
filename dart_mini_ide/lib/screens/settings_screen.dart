import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);
    final presets = compilerState.presets;
    final activeId = compilerState.activePresetId;

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Compiler Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Import JSON',
            onPressed: () => _importPreset(ref),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];
            final isActive = preset.id == activeId;

            return Card(
              color: isActive ? AppTheme.backgroundEnd : AppTheme.backgroundStart,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isActive ? AppTheme.primaryAccent : Colors.white12,
                  width: isActive ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text(
                  preset.name,
                  style: TextStyle(
                    color: isActive ? AppTheme.primaryAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  preset.endpointUrl.isEmpty ? 'No endpoint configured' : preset.endpointUrl,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: isActive
                    ? const Icon(Icons.check_circle, color: AppTheme.primaryAccent)
                    : const Icon(Icons.api, color: Colors.white54),
                children: [
                  _buildPresetDetails(preset, isActive, ref),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryAccent,
        foregroundColor: AppTheme.pureBlack,
        onPressed: () {
          final newPreset = CompilerPreset.getDefaultPresets().last; // Blank preset
          ref.read(compilerProvider.notifier).addPreset(newPreset);
          _editPreset(context, ref, newPreset);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPresetDetails(CompilerPreset preset, bool isActive, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!isActive)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pillBackground,
                    foregroundColor: AppTheme.pureBlack,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Set Active'),
                  onPressed: () {
                    ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  },
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.backgroundEnd,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                onPressed: () => _editPreset(context, ref, preset),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.backgroundEnd,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Duplicate'),
                onPressed: () {
                  ref.read(compilerProvider.notifier).duplicatePreset(preset);
                },
              ),
              if (preset.name != 'OneCompiler') // Prevent deleting default fallback
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    ref.read(compilerProvider.notifier).deletePreset(preset.id);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _importPreset(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        final preset = CompilerPreset.fromJson(data);
        ref.read(compilerProvider.notifier).addPreset(preset);
        Fluttertoast.showToast(msg: 'Preset imported successfully');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to import: \$e');
    }
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPresetScreen(preset: preset),
      ),
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
  late TextEditingController _urlCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memCtrl;

  String _method = 'POST';
  String _authType = 'None';

  Map<String, String> _headers = {};
  Map<String, String> _queryParams = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    _stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorCtrl = TextEditingController(text: widget.preset.errorPath);
    _timeCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memCtrl = TextEditingController(text: widget.preset.memoryPath);

    _method = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _headers = Map.from(widget.preset.headers);
    _queryParams = Map.from(widget.preset.queryParams);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutCtrl.dispose();
    _stderrCtrl.dispose();
    _errorCtrl.dispose();
    _timeCtrl.dispose();
    _memCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.preset.copyWith(
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      headers: _headers,
      queryParams: _queryParams,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memCtrl.text,
    );
    ref.read(compilerProvider.notifier).updatePreset(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryAccent),
            onPressed: _save,
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Basic Settings'),
            _buildTextField('Preset Name', _nameCtrl),
            _buildTextField('Endpoint URL', _urlCtrl, maxLines: 2),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.backgroundEnd,
                    initialValue: _method,
                    decoration: const InputDecoration(labelText: 'Method', labelStyle: TextStyle(color: Colors.white54)),
                    style: const TextStyle(color: Colors.white),
                    items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.backgroundEnd,
                    initialValue: _authType,
                    decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.white54)),
                    style: const TextStyle(color: Colors.white),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _authType = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Headers'),
            _buildMapEditor(_headers, 'Header'),

            const SizedBox(height: 24),
            _buildSectionTitle('Query Params'),
            _buildMapEditor(_queryParams, 'Param'),

            const SizedBox(height: 24),
            _buildSectionTitle('Request Body Template'),
            const Text(
              'Use placeholders: {code}, {stdin}, {language}',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _buildTextField('Body JSON/Form', _bodyCtrl, maxLines: 6),

            const SizedBox(height: 24),
            _buildSectionTitle('Response Mapping (Dot Notation)'),
            _buildTextField('stdout Path (e.g. run.stdout)', _stdoutCtrl),
            _buildTextField('stderr Path', _stderrCtrl),
            _buildTextField('Error Path', _errorCtrl),
            _buildTextField('Execution Time Path', _timeCtrl),
            _buildTextField('Memory Usage Path', _memCtrl),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryAccent)),
          filled: true,
          fillColor: AppTheme.backgroundEnd,
        ),
      ),
    );
  }

  Widget _buildMapEditor(Map<String, String> map, String itemLabel) {
    return Column(
      children: [
        ...map.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white))),
                Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white54))),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () {
                    setState(() => map.remove(e.key));
                  },
                )
              ],
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
          label: Text('Add \$itemLabel', style: const TextStyle(color: AppTheme.primaryAccent)),
          onPressed: () {
            _showAddMapEntryDialog(map, itemLabel);
          },
        )
      ],
    );
  }

  void _showAddMapEntryDialog(Map<String, String> map, String label) {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundEnd,
        title: Text('Add \$label', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Key', labelStyle: TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: valCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Value', labelStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              if (keyCtrl.text.isNotEmpty) {
                setState(() => map[keyCtrl.text] = valCtrl.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );
  }
}
