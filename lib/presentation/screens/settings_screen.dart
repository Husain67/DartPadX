import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' as java_io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../../services/execution_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Settings & Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(compilerState),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import Presets',
            onPressed: () => _importPresets(),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildActiveToggle(compilerState),
                const Divider(color: AppTheme.borderColor),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: compilerState.presets.length,
                    itemBuilder: (context, index) {
                      final preset = compilerState.presets[index];
                      final isActive = preset.id == compilerState.activePresetId;
                      return _buildPresetCard(preset, isActive);
                    },
                  ),
                ),
              ],
            );
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPresetDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _exportPresets(CompilerState state) async {
    try {
      final List<Map<String, dynamic>> jsonData = state.presets.map((p) => {
        'id': p.id,
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
        'timePath': p.timePath,
        'memoryPath': p.memoryPath,
      }).toList();

      final jsonString = jsonEncode(jsonData);
      await Share.share(jsonString, subject: 'DartMini Compiler Presets');
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: \$e");
    }
  }

  Future<void> _importPresets() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json', 'txt']);
      if (result != null) {
        final file = java_io.File(result.files.single.path!);
        final content = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(content);

        for (var item in jsonData) {
          final p = CompilerPreset(
            id: const Uuid().v4(), // Generate new ID to avoid conflicts
            name: item['name'] ?? 'Imported Preset',
            endpointUrl: item['endpointUrl'] ?? '',
            httpMethod: item['httpMethod'] ?? 'POST',
            authType: item['authType'] ?? 'None',
            authValue: item['authValue'] ?? '',
            headers: Map<String, String>.from(item['headers'] ?? {}),
            queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
            requestBodyTemplate: item['requestBodyTemplate'] ?? '',
            stdoutPath: item['stdoutPath'] ?? '',
            stderrPath: item['stderrPath'] ?? '',
            errorPath: item['errorPath'] ?? '',
            timePath: item['timePath'] ?? '',
            memoryPath: item['memoryPath'] ?? '',
          );
          ref.read(compilerProvider.notifier).addPreset(p);
        }
        Fluttertoast.showToast(msg: "Imported \${jsonData.length} presets");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: \$e");
    }
  }

  Widget _buildActiveToggle(CompilerState state) {

    return SwitchListTile(
      title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: const Text('Toggle to use built-in free API instead of custom presets', style: TextStyle(color: AppTheme.textSecondary)),
      // ignore: deprecated_member_use
      activeColor: AppTheme.primaryYellow,
      value: state.activePresetId == null,
      onChanged: (val) {
        if (val) {
          ref.read(compilerProvider.notifier).setActivePreset(null);
        } else if (state.presets.isNotEmpty) {
          ref.read(compilerProvider.notifier).setActivePreset(state.presets.first.id);
        }
      },
    );
  }

  Widget _buildPresetCard(CompilerPreset preset, bool isActive) {
    return Card(
      color: AppTheme.surfaceColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isActive ? AppTheme.primaryYellow : AppTheme.borderColor, width: isActive ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('\\${preset.httpMethod} \\${preset.endpointUrl}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              TextButton(
                onPressed: () => ref.read(compilerProvider.notifier).setActivePreset(preset.id),
                child: const Text('Set Active'),
              ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              tooltip: 'Duplicate Preset',
              onPressed: () {
                final duplicated = preset.copyWith(
                  id: const Uuid().v4(),
                  name: "\${preset.name} (Copy)",
                );
                ref.read(compilerProvider.notifier).addPreset(duplicated);
                Fluttertoast.showToast(msg: "Preset duplicated");
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => _showPresetDialog(preset),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                ref.read(compilerProvider.notifier).deletePreset(preset.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPresetDialog(CompilerPreset? existing) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PresetEditDialog(existing: existing, ref: ref),
    );
  }
}

class _PresetEditDialog extends StatefulWidget {
  final CompilerPreset? existing;
  final WidgetRef ref;

  const _PresetEditDialog({this.existing, required this.ref});

  @override
  State<_PresetEditDialog> createState() => _PresetEditDialogState();
}

class _PresetEditDialogState extends State<_PresetEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _outCtrl;
  late TextEditingController _errCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memCtrl;

  String _method = 'POST';
  String _authType = 'None';
  final Map<String, String> _headers = {};

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? 'New Preset');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? 'https://api.example.com/run');
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{\n  "code": "{code}"\n}');
    _outCtrl = TextEditingController(text: p?.stdoutPath ?? 'stdout');
    _errCtrl = TextEditingController(text: p?.stderrPath ?? 'stderr');
    _timeCtrl = TextEditingController(text: p?.timePath ?? '');
    _memCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _method = p.httpMethod;
      _authType = p.authType;
      _headers.addAll(p.headers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.existing == null ? 'Create Preset' : 'Edit Preset',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildField('Name', _nameCtrl),
              const SizedBox(height: 8),
              _buildField('Endpoint URL', _urlCtrl),
              const SizedBox(height: 8),

              const Text('HTTP Method', style: TextStyle(color: AppTheme.textSecondary)),
              DropdownButtonFormField<String>(
                initialValue: _method,
                dropdownColor: AppTheme.surfaceColor,
                style: const TextStyle(color: Colors.white),
                items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _method = v!),
              ),
              const SizedBox(height: 8),

              const Text('Auth Type', style: TextStyle(color: AppTheme.textSecondary)),
              DropdownButtonFormField<String>(
                initialValue: _authType,
                dropdownColor: AppTheme.surfaceColor,
                style: const TextStyle(color: Colors.white),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _authType = v!),
              ),
              if (_authType != 'None') ...[
                const SizedBox(height: 8),
                _buildField('Auth Value / Token', _authValueCtrl),
              ],
              const SizedBox(height: 16),

              const Text('Request Body (JSON with {code}, {stdin})', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyCtrl,
                maxLines: 8,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: const InputDecoration(hintText: '{\n  "script": "{code}"\n}'),
              ),
              const SizedBox(height: 16),

              const Text('Response Mapping (Dot Notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildField('STDOUT Path', _outCtrl),
              const SizedBox(height: 8),
              _buildField('STDERR Path', _errCtrl),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: _testConnection,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    child: const Text('Test Connection', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }

  void _testConnection() async {
    final testPreset = CompilerPreset(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: _headers,
      queryParams: {},
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _outCtrl.text,
      stderrPath: _errCtrl.text,
      errorPath: '',
      timePath: _timeCtrl.text,
      memoryPath: _memCtrl.text,
    );

    Fluttertoast.showToast(msg: "Testing connection...");
    final res = await ExecutionService.executeCustom(
      preset: testPreset,
      code: "void main() { print('Hello from Custom API'); }",
      stdin: "",
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Test Result', style: TextStyle(color: Colors.white)),
        content: Text('STDOUT: \\${res.stdout}\nSTDERR: \\${res.stderr}\nERROR: \\${res.error}',
          style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      )
    );
  }

  void _save() {
    final preset = CompilerPreset(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      headers: _headers,
      queryParams: {},
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _outCtrl.text,
      stderrPath: _errCtrl.text,
      errorPath: '',
      timePath: _timeCtrl.text,
      memoryPath: _memCtrl.text,
    );

    if (widget.existing == null) {
      widget.ref.read(compilerProvider.notifier).addPreset(preset);
    } else {
      widget.ref.read(compilerProvider.notifier).updatePreset(preset);
    }

    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset saved");
  }
}
