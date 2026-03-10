import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../providers/settings_provider.dart';
import '../providers/execution_provider.dart';
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../providers/file_provider.dart'; // For Examples

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAccent,
          labelColor: AppTheme.primaryAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Compiler Presets'),
            Tab(text: 'Examples Gallery'),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.mainGradient,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCompilerPresetsTab(context, ref),
            _buildExamplesTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCompilerPresetsTab(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: const Text('Toggle OFF to use custom selected preset.', style: TextStyle(color: Colors.white54)),
          value: settings.useDefaultOneCompiler,
          activeColor: AppTheme.primaryAccent,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).toggleUseDefault(val);
          },
        ),
        const Divider(color: Colors.white24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom Presets', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download, color: AppTheme.primaryAccent),
                    tooltip: 'Export Presets',
                    onPressed: () => _exportPresets(settings.presets),
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload, color: AppTheme.primaryAccent),
                    tooltip: 'Import Presets',
                    onPressed: () => _importPresets(),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showPresetEditor(context, null),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: settings.presets.length,
            itemBuilder: (context, index) {
              final preset = settings.presets[index];
              final isSelected = preset.id == settings.selectedPresetId;
              final isDefaultProtected = preset.id == 'onecompiler_default';

              return Card(
                color: isSelected && !settings.useDefaultOneCompiler ? AppTheme.backgroundEnd.withOpacity(0.8) : Colors.black45,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: isSelected && !settings.useDefaultOneCompiler
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryAccent)
                      : const Icon(Icons.api, color: Colors.white54),
                  title: Text(preset.platformName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white70),
                        tooltip: 'Duplicate',
                        onPressed: () => ref.read(settingsProvider.notifier).duplicatePreset(preset),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        tooltip: 'Edit',
                        onPressed: () => _showPresetEditor(context, preset),
                      ),
                      if (!isDefaultProtected)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Delete',
                          onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset.id),
                        ),
                    ],
                  ),
                  onTap: () {
                    if (!settings.useDefaultOneCompiler) {
                      ref.read(settingsProvider.notifier).selectPreset(preset.id);
                    } else {
                      Fluttertoast.showToast(msg: "Turn OFF 'Use Default' to select a custom preset.");
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamplesTab(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: AppConstants.defaultExamples.length,
      itemBuilder: (context, index) {
        final example = AppConstants.defaultExamples[index];
        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: const Icon(Icons.code, color: AppTheme.primaryAccent),
            title: Text(example.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Tap to load into editor', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            onTap: () {
              ref.read(fileProvider.notifier).loadExample(example);
              Fluttertoast.showToast(msg: "\${example.name} loaded");
              Navigator.pop(context); // Go back to editor
            },
          ),
        );
      },
    );
  }

  void _exportPresets(List<CompilerPreset> presets) async {
    try {
      final String jsonStr = jsonEncode(presets.map((e) => e.toJson()).toList());
      final directory = await getApplicationDocumentsDirectory();
      final file = File('\${directory.path}/dart_mini_presets.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], text: 'Exported Custom Presets');
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: \$e");
    }
  }

  void _importPresets() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        List<dynamic> parsed = jsonDecode(contents);
        List<CompilerPreset> presets = parsed.map((e) => CompilerPreset.fromJson(e)).toList();
        ref.read(settingsProvider.notifier).replaceAllPresets(presets);
        Fluttertoast.showToast(msg: "Presets imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: Invalid JSON format");
    }
  }

  void _showPresetEditor(BuildContext context, CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PresetEditorScreen(preset: preset)));
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
  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  String _httpMethod = 'POST';
  String _authType = 'None';

  Map<String, String> _headers = {};
  Map<String, String> _queryParams = {};

  final List<String> _httpMethods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.platformName ?? '');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? 'https://');
    _bodyTemplateCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{ "code": {code} }');
    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? 'stdout');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? 'stderr');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? 'error');
    _timePathCtrl = TextEditingController(text: p?.timePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _httpMethod = p.httpMethod;
      _authType = p.authType;
      _headers = Map.from(p.headers);
      _queryParams = Map.from(p.queryParams);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _timePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        platformName: _nameCtrl.text.trim(),
        endpointUrl: _urlCtrl.text.trim(),
        httpMethod: _httpMethod,
        authType: _authType,
        headers: _headers,
        queryParams: _queryParams,
        requestBodyTemplate: _bodyTemplateCtrl.text,
        stdoutPath: _stdoutPathCtrl.text.trim(),
        stderrPath: _stderrPathCtrl.text.trim(),
        errorPath: _errorPathCtrl.text.trim(),
        timePath: _timePathCtrl.text.trim(),
        memoryPath: _memoryPathCtrl.text.trim(),
      );

      if (widget.preset == null) {
        ref.read(settingsProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(newPreset);
      }

      Navigator.pop(context);
    }
  }

  void _testConnection() async {
     if (_formKey.currentState!.validate()) {
        final tempPreset = CompilerPreset(
            id: 'temp',
            platformName: 'temp',
            endpointUrl: _urlCtrl.text.trim(),
            httpMethod: _httpMethod,
            authType: _authType,
            headers: _headers,
            queryParams: _queryParams,
            requestBodyTemplate: _bodyTemplateCtrl.text,
            stdoutPath: _stdoutPathCtrl.text.trim(),
            stderrPath: _stderrPathCtrl.text.trim(),
            errorPath: _errorPathCtrl.text.trim(),
            timePath: _timePathCtrl.text.trim(),
            memoryPath: _memoryPathCtrl.text.trim(),
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.backgroundEnd,
            title: const Text('Testing Connection...'),
            content: Consumer(builder: (context, ref, child) {
               final execState = ref.watch(executionProvider);
               if (execState.isRunning) {
                  return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
               }
               return SingleChildScrollView(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     if (execState.stderr.isNotEmpty && execState.stderr != 'Testing connection...')
                       Text(execState.stderr, style: const TextStyle(color: Colors.red)),
                     const SizedBox(height: 10),
                     Text(execState.stdout, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                   ],
                 ),
               );
            }),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                   ref.read(executionProvider.notifier).clearOutput();
                   Navigator.of(context).pop();
                }
              )
            ],
          )
        );

        await ref.read(executionProvider.notifier).testConnection(tempPreset);
     }
  }

  void _editMap(String title, Map<String, String> map, Function(Map<String, String>) onUpdate) {
    showDialog(
      context: context,
      builder: (context) {
        String k = '';
        String v = '';
        return AlertDialog(
          backgroundColor: AppTheme.backgroundEnd,
          title: Text('Add \$title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Key'), onChanged: (val) => k = val),
              const SizedBox(height: 8),
              TextField(decoration: const InputDecoration(labelText: 'Value'), onChanged: (val) => v = val),
            ],
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (k.isNotEmpty) {
                  setState(() {
                    map[k] = v;
                    onUpdate(map);
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow, color: AppTheme.primaryAccent),
            tooltip: 'Test Connection',
            onPressed: _testConnection,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.mainGradient,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle('Basic Info'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Platform Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: InputDecoration(
                  labelText: 'Endpoint URL',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                       // Using flutter/services.dart for Clipboard
                       Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                       Fluttertoast.showToast(msg: 'Copied to clipboard');
                    },
                  )
                ),
                validator: (val) => val == null || !val.startsWith('http') ? 'Must be a valid URL' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'HTTP Method'),
                      value: _httpMethod,
                      dropdownColor: AppTheme.backgroundEnd,
                      items: _httpMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => _httpMethod = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Auth Type'),
                      value: _authType,
                      dropdownColor: AppTheme.backgroundEnd,
                      items: _authTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                      onChanged: (val) => setState(() => _authType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Headers & Params'),
              _buildMapEditor('Headers', _headers, (m) => _headers = m),
              const SizedBox(height: 12),
              _buildMapEditor('Query Params', _queryParams, (m) => _queryParams = m),
              const SizedBox(height: 24),

              _buildSectionTitle('Request Body Template'),
              const Text(
                'Use placeholders: {code}, {stdin}, {language}',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyTemplateCtrl,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: const InputDecoration(hintText: 'e.g. { "source": {code} }'),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Response Mapping (Dot Notation)'),
              const Text('e.g., result.run_status.output', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              _buildMapField('Stdout Path', _stdoutPathCtrl),
              _buildMapField('Stderr Path', _stderrPathCtrl),
              _buildMapField('Error Path', _errorPathCtrl),
              _buildMapField('Execution Time Path', _timePathCtrl),
              _buildMapField('Memory Path', _memoryPathCtrl),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildMapField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }

  Widget _buildMapEditor(String title, Map<String, String> map, Function(Map<String, String>) onUpdate) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent), onPressed: () => _editMap(title, map, onUpdate)),
            ],
          ),
          if (map.isEmpty) const Text('None', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
          ...map.entries.map((e) => Row(
            children: [
              Expanded(child: Text('\${e.key}: \${e.value}', style: const TextStyle(fontSize: 13))),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 16),
                onPressed: () {
                  setState(() {
                    map.remove(e.key);
                    onUpdate(map);
                  });
                },
              )
            ],
          )).toList(),
        ],
      ),
    );
  }
}
