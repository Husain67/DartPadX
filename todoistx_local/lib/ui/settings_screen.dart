import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../providers/settings_notifier.dart';
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';
import '../services/compiler_service.dart';

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
      appBar: AppBar(
        title: const Text('Settings & API'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import Presets',
            onPressed: _importPresets,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Presets',
            onPressed: () => _exportPresets(settings.presets),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler'),
              subtitle: const Text('Built-in reliable execution engine'),
              value: settings.useOneCompiler,
              activeColor: AppTheme.primaryAccent, // ignore: deprecated_member_use
              onChanged: (val) {
                ref.read(settingsProvider.notifier).setUseOneCompiler(val);
              },
            ),
            const Divider(color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Custom Compiler Presets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
                  onPressed: () => _editPreset(null),
                )
              ],
            ),
            const SizedBox(height: 16),
            ...settings.presets.map((preset) => _buildPresetCard(preset, settings.activePresetId == preset.id)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard(CompilerPreset preset, bool isActive) {
    final settings = ref.read(settingsProvider);

    return Card(
      color: isActive && !settings.useOneCompiler ? AppTheme.surfaceColor : Colors.black45,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isActive && !settings.useOneCompiler ? AppTheme.primaryAccent : Colors.grey.shade800,
          width: isActive && !settings.useOneCompiler ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(preset.platformName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!settings.useOneCompiler)
              IconButton(
                icon: Icon(isActive ? Icons.check_circle : Icons.radio_button_unchecked, color: isActive ? AppTheme.primaryAccent : Colors.grey),
                onPressed: () {
                  ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                },
              ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _editPreset(preset);
                if (val == 'duplicate') {
                  final duplicated = preset.copyWith(
                    platformName: '${preset.platformName} (Copy)',
                    isEditable: true,
                  );
                  ref.read(settingsProvider.notifier).savePreset(duplicated);
                }
                if (val == 'delete' && preset.isEditable) {
                  ref.read(settingsProvider.notifier).deletePreset(preset.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit / View')),
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                if (preset.isEditable)
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _editPreset(CompilerPreset? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorScreen(preset: existing),
      ),
    );
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    try {
      final jsonStr = jsonEncode(presets.map((p) => p.toJson()).toList());

      Directory? directory;
      if (Platform.isAndroid) {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        directory = dirs?.first;
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/dartmini_presets.json');
        await file.writeAsString(jsonStr);
        Fluttertoast.showToast(msg: "Exported to ${file.path}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: $e");
    }
  }

  Future<void> _importPresets() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final content = utf8.decode(result.files.single.bytes!);
        final List<dynamic> jsonList = jsonDecode(content);

        for (var item in jsonList) {
          final preset = CompilerPreset.fromJson(item as Map<String, dynamic>).copyWith(isEditable: true);
          ref.read(settingsProvider.notifier).savePreset(preset);
        }
        Fluttertoast.showToast(msg: "Presets imported successfully");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import error: $e");
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
  late TextEditingController nameCtrl;
  late TextEditingController urlCtrl;
  late TextEditingController bodyCtrl;

  late TextEditingController stdoutCtrl;
  late TextEditingController stderrCtrl;
  late TextEditingController errorCtrl;
  late TextEditingController timeCtrl;
  late TextEditingController memoryCtrl;

  String method = 'POST';
  String authType = 'None';

  List<MapEntry<String, String>> headersList = [];
  List<MapEntry<String, String>> paramsList = [];

  bool isTesting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    nameCtrl = TextEditingController(text: p?.platformName ?? '');
    urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{\n  "code": "{code}",\n  "stdin": "{stdin}"\n}');

    stdoutCtrl = TextEditingController(text: p?.responseMapping.stdoutPath ?? '');
    stderrCtrl = TextEditingController(text: p?.responseMapping.stderrPath ?? '');
    errorCtrl = TextEditingController(text: p?.responseMapping.errorPath ?? '');
    timeCtrl = TextEditingController(text: p?.responseMapping.executionTimePath ?? '');
    memoryCtrl = TextEditingController(text: p?.responseMapping.memoryPath ?? '');

    method = p?.httpMethod ?? 'POST';
    authType = p?.authType ?? 'None';

    if (p != null) {
      headersList = p.headers.entries.toList();
      paramsList = p.queryParams.entries.toList();
    }
  }

  void _save() {
    if (nameCtrl.text.isEmpty || urlCtrl.text.isEmpty) {
      Fluttertoast.showToast(msg: "Name and URL are required");
      return;
    }

    final newPreset = CompilerPreset(
      id: widget.preset?.id,
      platformName: nameCtrl.text,
      endpointUrl: urlCtrl.text,
      httpMethod: method,
      authType: authType,
      headers: Map.fromEntries(headersList),
      queryParams: Map.fromEntries(paramsList),
      requestBodyTemplate: bodyCtrl.text,
      isEditable: true,
      responseMapping: ResponseMapping(
        stdoutPath: stdoutCtrl.text,
        stderrPath: stderrCtrl.text,
        errorPath: errorCtrl.text,
        executionTimePath: timeCtrl.text,
        memoryPath: memoryCtrl.text,
      )
    );

    ref.read(settingsProvider.notifier).savePreset(newPreset);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset saved");
  }

  Future<void> _testConnection() async {
    setState(() => isTesting = true);

    final tempPreset = CompilerPreset(
      platformName: nameCtrl.text,
      endpointUrl: urlCtrl.text,
      httpMethod: method,
      authType: authType,
      headers: Map.fromEntries(headersList),
      queryParams: Map.fromEntries(paramsList),
      requestBodyTemplate: bodyCtrl.text,
      responseMapping: ResponseMapping(
        stdoutPath: stdoutCtrl.text,
        stderrPath: stderrCtrl.text,
        errorPath: errorCtrl.text,
        executionTimePath: timeCtrl.text,
        memoryPath: memoryCtrl.text,
      )
    );

    try {
      final res = await CompilerService.executeWithPreset(tempPreset, "print('Hello from custom API');", "");

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Test Result (Success)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stdout: ${res.stdout}', style: const TextStyle(color: Colors.greenAccent)),
              Text('Stderr: ${res.stderr}', style: const TextStyle(color: Colors.redAccent)),
              Text('Time: ${res.executionTime}'),
              Text('Memory: ${res.memory}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        )
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Test Result (Error)'),
          content: SingleChildScrollView(child: Text(e.toString(), style: const TextStyle(color: Colors.redAccent))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        )
      );
    } finally {
      setState(() => isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool readOnly = widget.preset != null && !widget.preset!.isEditable;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : (readOnly ? 'View Preset' : 'Edit Preset')),
        actions: [
          if (!readOnly)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
            )
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: nameCtrl,
              enabled: !readOnly,
              decoration: const InputDecoration(labelText: 'Platform Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: urlCtrl,
                    enabled: !readOnly,
                    decoration: const InputDecoration(labelText: 'Endpoint URL'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: urlCtrl.text));
                    Fluttertoast.showToast(msg: "URL copied");
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: method, // ignore: deprecated_member_use
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: readOnly ? null : (v) => setState(() => method = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: authType, // ignore: deprecated_member_use
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Query Param']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: readOnly ? null : (v) => setState(() => authType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDynamicTable('Headers', headersList, readOnly),
            const SizedBox(height: 16),
            _buildDynamicTable('Query Params / Auth Config', paramsList, readOnly),
            const SizedBox(height: 16),
            const Text('Request Body JSON Template (use {code}, {stdin}, {language})', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              enabled: !readOnly,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(hintText: '{\n  "code": "{code}"\n}'),
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildMappingField('Stdout Path', stdoutCtrl, readOnly),
            _buildMappingField('Stderr Path', stderrCtrl, readOnly),
            _buildMappingField('Error Path', errorCtrl, readOnly),
            _buildMappingField('Execution Time Path', timeCtrl, readOnly),
            _buildMappingField('Memory Path', memoryCtrl, readOnly),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              onPressed: isTesting ? null : _testConnection,
              child: isTesting ? const CircularProgressIndicator(color: Colors.black) : const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMappingField(String label, TextEditingController ctrl, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: ctrl,
        enabled: !readOnly,
        decoration: InputDecoration(labelText: label, hintText: 'e.g. data.run.stdout', isDense: true),
      ),
    );
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> list, bool readOnly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!readOnly)
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent, size: 20),
                onPressed: () {
                  setState(() => list.add(const MapEntry('', '')));
                },
              )
          ],
        ),
        if (list.isEmpty)
          const Text('None', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          MapEntry<String, String> item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.key,
                    enabled: !readOnly,
                    decoration: const InputDecoration(isDense: true, hintText: 'Key'),
                    onChanged: (v) => list[idx] = MapEntry(v, list[idx].value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.value,
                    enabled: !readOnly,
                    decoration: const InputDecoration(isDense: true, hintText: 'Value'),
                    onChanged: (v) => list[idx] = MapEntry(list[idx].key, v),
                  ),
                ),
                if (!readOnly)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                    onPressed: () => setState(() => list.removeAt(idx)),
                  )
              ],
            ),
          );
        }),
      ],
    );
  }
}
