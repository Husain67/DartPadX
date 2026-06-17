// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, unnecessary_to_list_in_spreads, unused_local_variable
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = ref.read(settingsProvider).oneCompilerApiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.appBarColor,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'General'),
                  Tab(text: 'Compiler Presets'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGeneralTab(state),
                    _buildPresetsTab(state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(SettingsState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'OneCompiler API Key',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _apiKeyController,
          decoration: InputDecoration(
            hintText: 'Enter your API key',
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                ref.read(settingsProvider.notifier).saveApiKey(_apiKeyController.text);
                Fluttertoast.showToast(msg: 'API Key saved');
              },
            ),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 24),
        const Text(
          'Active Compiler Preset',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: state.activePresetId,
              items: state.presets.map((preset) {
                return DropdownMenuItem(
                  value: preset.id,
                  child: Text(preset.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).setActivePreset(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsTab(SettingsState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Preset'),
                  onPressed: () => _showEditPresetDialog(null),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.file_upload, color: Colors.blue),
                tooltip: 'Export Presets',
                onPressed: () => _exportPresets(state.presets),
              ),
              IconButton(
                icon: const Icon(Icons.file_download, color: Colors.green),
                tooltip: 'Import Presets',
                onPressed: _importPresets,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.presets.length,
            itemBuilder: (context, index) {
              final preset = state.presets[index];
              final isActive = preset.id == state.activePresetId;

              return ListTile(
                title: Text(preset.name, style: TextStyle(color: isActive ? AppTheme.primaryAccent : Colors.white)),
                subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!preset.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditPresetDialog(preset),
                      ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.green),
                      onPressed: () => _duplicatePreset(preset),
                    ),
                    if (!preset.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset.id),
                      ),
                  ],
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                  Fluttertoast.showToast(msg: 'Set \${preset.name} as active');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _duplicatePreset(CompilerPreset preset) {
    final newPreset = preset.copyWith(
      id: const Uuid().v4(),
      name: '\${preset.name} (Copy)',
      isReadOnly: false,
    );
    ref.read(settingsProvider.notifier).addOrUpdatePreset(newPreset);
    Fluttertoast.showToast(msg: 'Preset duplicated');
  }

  void _showEditPresetDialog(CompilerPreset? preset) {
    showDialog(
      context: context,
      builder: (context) => EditPresetDialog(preset: preset),
    );
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    try {
      final jsonList = presets.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('\${dir.path}/presets.json');
      await file.writeAsString(jsonString);
      Fluttertoast.showToast(msg: 'Presets exported to \${file.path}');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error exporting: \$e');
    }
  }

  Future<void> _importPresets() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        for (var item in jsonList) {
          final preset = CompilerPreset.fromJson(item);
          // Always make imported ones editable
          final newPreset = preset.copyWith(id: const Uuid().v4(), isReadOnly: false);
          ref.read(settingsProvider.notifier).addOrUpdatePreset(newPreset);
        }
        Fluttertoast.showToast(msg: 'Presets imported');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error importing: \$e');
    }
  }
}

class EditPresetDialog extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const EditPresetDialog({super.key, this.preset});

  @override
  ConsumerState<EditPresetDialog> createState() => _EditPresetDialogState();
}

class _EditPresetDialogState extends ConsumerState<EditPresetDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String url;
  late String method;
  late String authType;
  late String bodyTemplate;
  late String stdoutPath;
  late String stderrPath;
  late String errorPath;
  late String executionTimePath;
  late String memoryPath;

  List<MapEntry<String, String>> headersList = [];
  List<MapEntry<String, String>> paramsList = [];

  bool isTesting = false;

  @override
  void initState() {
    super.initState();
    name = widget.preset?.name ?? 'New Preset';
    url = widget.preset?.url ?? '';
    method = widget.preset?.method ?? 'POST';
    authType = widget.preset?.authType ?? 'None';
    bodyTemplate = widget.preset?.bodyTemplate ?? '{}';
    stdoutPath = widget.preset?.stdoutPath ?? '';
    stderrPath = widget.preset?.stderrPath ?? '';
    errorPath = widget.preset?.errorPath ?? '';
    executionTimePath = widget.preset?.executionTimePath ?? '';
    memoryPath = widget.preset?.memoryPath ?? '';

    if (widget.preset != null) {
      headersList = widget.preset!.headers.entries.toList();
      paramsList = widget.preset!.queryParams.entries.toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                widget.preset == null ? 'Add Preset' : 'Edit Preset',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                onSaved: (v) => name = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: url,
                decoration: const InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
                onSaved: (v) => url = v ?? '',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: method,
                decoration: const InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => method = v ?? 'POST'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: authType,
                decoration: const InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => authType = v ?? 'None'),
              ),
              const SizedBox(height: 16),
              _buildDynamicTable('Headers', headersList),
              const SizedBox(height: 16),
              _buildDynamicTable('Query Params', paramsList),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: bodyTemplate,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Body Template (JSON)', border: OutlineInputBorder()),
                onSaved: (v) => bodyTemplate = v ?? '',
              ),
              const SizedBox(height: 16),
              const Text('Response Mapping Paths (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: stdoutPath,
                decoration: const InputDecoration(labelText: 'Stdout Path (e.g. data.output)', border: OutlineInputBorder(), isDense: true),
                onSaved: (v) => stdoutPath = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: stderrPath,
                decoration: const InputDecoration(labelText: 'Stderr Path', border: OutlineInputBorder(), isDense: true),
                onSaved: (v) => stderrPath = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: errorPath,
                decoration: const InputDecoration(labelText: 'Error Path', border: OutlineInputBorder(), isDense: true),
                onSaved: (v) => errorPath = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: executionTimePath,
                decoration: const InputDecoration(labelText: 'Execution Time Path', border: OutlineInputBorder(), isDense: true),
                onSaved: (v) => executionTimePath = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: memoryPath,
                decoration: const InputDecoration(labelText: 'Memory Path', border: OutlineInputBorder(), isDense: true),
                onSaved: (v) => memoryPath = v ?? '',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    icon: isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.network_check),
                    label: const Text('Test', style: TextStyle(color: Colors.white)),
                    onPressed: isTesting ? null : _testConnection,
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent, foregroundColor: Colors.black),
                        onPressed: () {
                          _formKey.currentState?.save();

                          Map<String, String> headers = {};
                          for (var h in headersList) {
                            if (h.key.isNotEmpty) headers[h.key] = h.value;
                          }
                          Map<String, String> params = {};
                          for (var p in paramsList) {
                            if (p.key.isNotEmpty) params[p.key] = p.value;
                          }

                          final newPreset = CompilerPreset(
                            id: widget.preset?.id ?? const Uuid().v4(),
                            name: name,
                            url: url,
                            method: method,
                            authType: authType,
                            headers: headers,
                            queryParams: params,
                            bodyTemplate: bodyTemplate,
                            stdoutPath: stdoutPath,
                            stderrPath: stderrPath,
                            errorPath: errorPath,
                            executionTimePath: executionTimePath,
                            memoryPath: memoryPath,
                            isReadOnly: false,
                          );
                          ref.read(settingsProvider.notifier).addOrUpdatePreset(newPreset);
                          Navigator.pop(context);
                          Fluttertoast.showToast(msg: 'Preset saved');
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent),
              onPressed: () {
                setState(() {
                  list.add(const MapEntry('', ''));
                });
              },
            ),
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int index = entry.key;
          MapEntry<String, String> item = entry.value;
          return Padding(
            key: ValueKey('\${title}_\$index'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.key,
                    decoration: const InputDecoration(hintText: 'Key', isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => list[index] = MapEntry(v, list[index].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.value,
                    decoration: const InputDecoration(hintText: 'Value', isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => list[index] = MapEntry(list[index].key, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      list.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _testConnection() async {
    _formKey.currentState?.save();
    setState(() => isTesting = true);

    try {
      Map<String, String> headers = {};
      for (var h in headersList) {
        if (h.key.isNotEmpty) headers[h.key] = h.value;
      }
      if (authType == 'API-Key Header' && widget.preset?.id == 'preset_onecompiler_default') {
         headers['X-RapidAPI-Key'] = ref.read(settingsProvider).oneCompilerApiKey;
      }

      String bodyStr = bodyTemplate;
      String testCode = "void main() { print('Hello from custom API'); }";
      bodyStr = bodyStr.replaceAll('{code}', jsonEncode(testCode).substring(1, jsonEncode(testCode).length - 1));
      bodyStr = bodyStr.replaceAll('{stdin}', '');

      http.Response response;
      if (method.toUpperCase() == 'POST') {
        response = await http.post(Uri.parse(url), headers: headers, body: bodyStr);
      } else {
        response = await http.get(Uri.parse(url), headers: headers);
      }

            showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: Text('Test Result (\${response.statusCode})'),
          content: SingleChildScrollView(
            child: Text(response.body, style: const TextStyle(fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Test Failed: \$e');
    } finally {
      setState(() => isTesting = false);
    }
  }
}
