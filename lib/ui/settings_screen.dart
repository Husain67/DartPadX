import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return AppTheme.gradientBackground(
      Scaffold(
        appBar: AppBar(
          title: const Text('Compiler Presets & Settings'),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: 'Import Presets',
              onPressed: () => _importPresets(ref),
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export Presets',
              onPressed: () => _exportPresets(ref),
            ),
          ],
        ),
        body: const PresetList(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showPresetEditor(null);
          },
          label: const Text('New Preset', style: TextStyle(color: Colors.black)),
          icon: const Icon(Icons.add, color: Colors.black),
          backgroundColor: AppTheme.accentColor,
        ),
      ),
    );
  }

  void _showPresetEditor(CompilerPreset? preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresetEditorScreen(preset: preset),
      ),
    );
  }

  Future<void> _exportPresets(WidgetRef ref) async {
    final presets = ref.read(compilerProvider).presets;
    final jsonList = presets.map((p) => p.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final path = '${directory.path}/dartmini_presets.json';
        final file = File(path);
        await file.writeAsString(jsonString);
        Fluttertoast.showToast(msg: "Exported to $path");

        // Option to share immediately
        await Share.shareFiles([path], text: 'DartMini Presets Export');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: $e");
    }
  }

  Future<void> _importPresets(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String content = utf8.decode(result.files.single.bytes!);
        List<dynamic> jsonList = jsonDecode(content);

        for (var item in jsonList) {
          final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
          // Avoid overwriting defaults unless specifically matching
          preset.id = const Uuid().v4();
          preset.name = '${preset.name} (Imported)';
          ref.read(compilerProvider.notifier).savePreset(preset);
        }
        Fluttertoast.showToast(msg: "Imported ${jsonList.length} presets");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Import failed: $e");
    }
  }
}

class PresetList extends ConsumerWidget {
  const PresetList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);
    final presets = state.presets;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        final isActive = state.activePresetId == preset.id;

        return Card(
          color: isActive ? Colors.black45 : Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isActive ? AppTheme.accentColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(preset.endpointUrl),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isActive)
                  TextButton(
                    onPressed: () {
                      ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                    },
                    child: const Text('Set Active'),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PresetEditorScreen(preset: preset),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () {
                    final newPreset = preset.copyWith(
                      id: const Uuid().v4(),
                      name: '${preset.name} (Copy)',
                    );
                    ref.read(compilerProvider.notifier).savePreset(newPreset);
                  },
                ),
                if (preset.id != 'default_onecompiler')
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
      },
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

  late String id;
  late String name;
  late String endpointUrl;
  late String httpMethod;
  late String authType;
  String? authToken;
  late Map<String, String> headers;
  late Map<String, String> queryParams;
  late String requestBodyTemplate;
  late String stdoutPath;
  late String stderrPath;
  late String errorPath;
  late String executionTimePath;
  late String memoryPath;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    id = p?.id ?? const Uuid().v4();
    name = p?.name ?? 'New Custom API';
    endpointUrl = p?.endpointUrl ?? 'https://api.example.com/execute';
    httpMethod = p?.httpMethod ?? 'POST';
    authType = p?.authType ?? 'None';
    authToken = p?.authToken;
    headers = p != null ? Map.from(p.headers) : {'Content-Type': 'application/json'};
    queryParams = p != null ? Map.from(p.queryParams) : {};
    requestBodyTemplate = p?.requestBodyTemplate ?? '{"code": "{code}", "language": "dart"}';
    stdoutPath = p?.stdoutPath ?? 'stdout';
    stderrPath = p?.stderrPath ?? 'stderr';
    errorPath = p?.errorPath ?? 'error';
    executionTimePath = p?.executionTimePath ?? '';
    memoryPath = p?.memoryPath ?? '';
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newPreset = CompilerPreset(
        id: id,
        name: name,
        endpointUrl: endpointUrl,
        httpMethod: httpMethod,
        authType: authType,
        authToken: authToken,
        headers: headers,
        queryParams: queryParams,
        requestBodyTemplate: requestBodyTemplate,
        stdoutPath: stdoutPath,
        stderrPath: stderrPath,
        errorPath: errorPath,
        executionTimePath: executionTimePath,
        memoryPath: memoryPath,
      );
      ref.read(compilerProvider.notifier).savePreset(newPreset);
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    // Save state locally before testing to use the current filled info
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final testPreset = CompilerPreset(
      id: 'test',
      name: 'test',
      endpointUrl: endpointUrl,
      httpMethod: httpMethod,
      authType: authType,
      authToken: authToken,
      headers: headers,
      queryParams: queryParams,
      requestBodyTemplate: requestBodyTemplate,
      stdoutPath: stdoutPath,
      stderrPath: stderrPath,
      errorPath: errorPath,
      executionTimePath: executionTimePath,
      memoryPath: memoryPath,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text("Testing connection...")])),
    );

    final output = await ref.read(compilerProvider.notifier).testPresetExecution(testPreset);

    Navigator.pop(context); // close loading

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Parsed Stdout: ${output.stdout}', style: const TextStyle(color: Colors.green)),
              Text('Parsed Stderr: ${output.stderr}', style: const TextStyle(color: Colors.red)),
              Text('Parsed Error: ${output.error}', style: const TextStyle(color: Colors.orange)),
              const Divider(),
              const Text('Raw Response:', style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(output.rawResponse, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppTheme.gradientBackground(
      Scaffold(
        appBar: AppBar(
          title: Text(widget.preset == null ? 'Create Preset' : 'Edit Preset'),
          actions: [
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.green),
              tooltip: 'Test Connection',
              onPressed: _testConnection,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _save,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('General'),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Platform Name'),
                onSaved: (v) => name = v ?? '',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: endpointUrl,
                decoration: InputDecoration(
                  labelText: 'Endpoint URL',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: endpointUrl));
                      Fluttertoast.showToast(msg: 'URL copied');
                    },
                  ),
                ),
                onSaved: (v) => endpointUrl = v ?? '',
                onChanged: (v) => endpointUrl = v,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: httpMethod,
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => httpMethod = v!),
              ),

              _buildSectionTitle('Authentication'),
              DropdownButtonFormField<String>(
                value: authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => authType = v!),
              ),
              if (authType != 'None') ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: authToken,
                  decoration: const InputDecoration(labelText: 'Auth Token / Key'),
                  onSaved: (v) => authToken = v,
                ),
              ],

              _buildSectionTitle('Request Template (JSON)'),
              const Text(
                'Available placeholders: {code}, {stdin}, {filename}, {language}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: requestBodyTemplate,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                decoration: const InputDecoration(hintText: 'Enter JSON body template'),
                onSaved: (v) => requestBodyTemplate = v ?? '',
              ),

              _buildSectionTitle('Response Mapping (Dot Notation)'),
              TextFormField(
                initialValue: stdoutPath,
                decoration: const InputDecoration(labelText: 'Stdout Path (e.g., data.output)'),
                onSaved: (v) => stdoutPath = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: stderrPath,
                decoration: const InputDecoration(labelText: 'Stderr Path'),
                onSaved: (v) => stderrPath = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: errorPath,
                decoration: const InputDecoration(labelText: 'Error Path'),
                onSaved: (v) => errorPath = v ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: executionTimePath,
                decoration: const InputDecoration(labelText: 'Execution Time Path'),
                onSaved: (v) => executionTimePath = v ?? '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
      ),
    );
  }
}
