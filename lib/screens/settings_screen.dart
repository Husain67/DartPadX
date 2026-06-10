import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});


  Future<void> _exportPresets(BuildContext context, WidgetRef ref) async {
    final presets = ref.read(compilerProvider).presets;
    final jsonList = presets.map((p) => {
      'id': p.id,
      'platformName': p.platformName,
      'endpointUrl': p.endpointUrl,
      'httpMethod': p.httpMethod,
      'authType': p.authType,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'requestBodyTemplate': p.requestBodyTemplate,
      'responseStdoutPath': p.responseStdoutPath,
      'responseStderrPath': p.responseStderrPath,
      'responseErrorPath': p.responseErrorPath,
      'responseTimePath': p.responseTimePath,
      'responseMemoryPath': p.responseMemoryPath,
      'isReadOnly': p.isReadOnly,
    }).toList();

    final jsonStr = jsonEncode(jsonList);
    // Simple copy to clipboard for MVP since file_picker save is complex on all platforms

    Clipboard.setData(ClipboardData(text: jsonStr));
    Fluttertoast.showToast(msg: "Presets JSON copied to clipboard!");
  }

  Future<void> _importPresets(BuildContext context, WidgetRef ref) async {

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.isEmpty) {
      Fluttertoast.showToast(msg: "Clipboard is empty");
      return;
    }
    try {
      final List<dynamic> jsonList = jsonDecode(data.text!);
      for (var item in jsonList) {
         final p = CompilerPreset(
            id: item['id'] ?? UniqueKey().toString(),
            platformName: item['platformName'] ?? 'Imported',
            endpointUrl: item['endpointUrl'] ?? '',
            httpMethod: item['httpMethod'] ?? 'POST',
            authType: item['authType'] ?? 'None',
            headers: (item['headers'] as Map?)?.cast<String, String>() ?? {},
            queryParams: (item['queryParams'] as Map?)?.cast<String, String>() ?? {},
            requestBodyTemplate: item['requestBodyTemplate'] ?? '',
            responseStdoutPath: item['responseStdoutPath'] ?? '',
            responseStderrPath: item['responseStderrPath'] ?? '',
            responseErrorPath: item['responseErrorPath'] ?? '',
            responseTimePath: item['responseTimePath'] ?? '',
            responseMemoryPath: item['responseMemoryPath'] ?? '',
            isReadOnly: false, // Imported are never read-only
         );
         ref.read(compilerProvider.notifier).addPreset(p);
      }
      Fluttertoast.showToast(msg: "Imported ${jsonList.length} presets!");
    } catch (e) {
      Fluttertoast.showToast(msg: "Invalid JSON format");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _importPresets(context, ref),
            tooltip: 'Import JSON',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportPresets(context, ref),
            tooltip: 'Export JSON',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Toggle to use custom presets below', style: TextStyle(color: Colors.grey)),
              value: compilerState.useDefaultOneCompiler,
              activeColor: AppTheme.primaryAccent,
              onChanged: (val) {
                ref.read(compilerProvider.notifier).toggleUseDefault(val);
              },
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: Opacity(
                opacity: compilerState.useDefaultOneCompiler ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: compilerState.useDefaultOneCompiler,
                  child: ListView.builder(
                    itemCount: compilerState.presets.length,
                    itemBuilder: (context, index) {
                      final preset = compilerState.presets[index];
                      final isActive = preset.id == compilerState.activePresetId;

                      return Card(
                        color: isActive ? Colors.white10 : Colors.transparent,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: isActive ? AppTheme.primaryAccent : Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(preset.platformName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.white54),
                                onPressed: () => ref.read(compilerProvider.notifier).duplicatePreset(preset),
                                tooltip: 'Duplicate',
                              ),
                              if (!preset.isReadOnly)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                                  tooltip: 'Delete',
                                ),
                              Radio<String>(
                                value: preset.id,
                                groupValue: compilerState.activePresetId,
                                activeColor: AppTheme.primaryAccent,
                                onChanged: (val) {
                                  if (val != null) {
                                    ref.read(compilerProvider.notifier).setActivePreset(val);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!preset.isReadOnly) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                            } else {
                              Fluttertoast.showToast(msg: "This preset is read-only. Duplicate it to edit.");
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _bodyTemplateController;
  late String _httpMethod;
  late String _authType;

  // Paths
  late TextEditingController _stdoutPath;
  late TextEditingController _stderrPath;
  late TextEditingController _errorPath;
  late TextEditingController _timePath;
  late TextEditingController _memoryPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.platformName);
    _urlController = TextEditingController(text: widget.preset.endpointUrl);
    _bodyTemplateController = TextEditingController(text: widget.preset.requestBodyTemplate);
    _httpMethod = widget.preset.httpMethod;
    _authType = widget.preset.authType;

    _stdoutPath = TextEditingController(text: widget.preset.responseStdoutPath);
    _stderrPath = TextEditingController(text: widget.preset.responseStderrPath);
    _errorPath = TextEditingController(text: widget.preset.responseErrorPath);
    _timePath = TextEditingController(text: widget.preset.responseTimePath);
    _memoryPath = TextEditingController(text: widget.preset.responseMemoryPath);
  }

  void _save() {
    final updated = widget.preset.copyWith(
      platformName: _nameController.text,
      endpointUrl: _urlController.text,
      httpMethod: _httpMethod,
      authType: _authType,
      requestBodyTemplate: _bodyTemplateController.text,
      responseStdoutPath: _stdoutPath.text,
      responseStderrPath: _stderrPath.text,
      responseErrorPath: _errorPath.text,
      responseTimePath: _timePath.text,
      responseMemoryPath: _memoryPath.text,
    );
    ref.read(compilerProvider.notifier).updatePreset(updated);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset saved");
  }

  Future<void> _testConnection() async {
    Fluttertoast.showToast(msg: "Testing connection...");
    // Minimal mock test implementation just for UI feedback
    try {
      final uri = Uri.parse(_urlController.text);
      final req = http.Request(_httpMethod, uri);
      final res = await req.send();
      Fluttertoast.showToast(msg: "Status: \${res.statusCode}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: \$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_circle_fill), onPressed: _testConnection, tooltip: 'Test'),
          IconButton(icon: const Icon(Icons.save), onPressed: _save, tooltip: 'Save'),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField('Platform Name', _nameController),
            _buildTextField('Endpoint URL', _urlController, maxLines: 2),
            DropdownButtonFormField<String>(
              value: _httpMethod,
              dropdownColor: AppTheme.surfaceColor,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.grey)),
              items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _httpMethod = val!),
            ),
            DropdownButtonFormField<String>(
              value: _authType,
              dropdownColor: AppTheme.surfaceColor,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.grey)),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _authType = val!),
            ),
            const SizedBox(height: 16),
            const Text('Request Body Template JSON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            _buildTextField('', _bodyTemplateController, maxLines: 8, fontFam: 'monospace'),
            const SizedBox(height: 16),
            const Text('Response JSON Paths (Dot notation)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            _buildTextField('Stdout Path', _stdoutPath),
            _buildTextField('Stderr Path', _stderrPath),
            _buildTextField('Error Path', _errorPath),
            _buildTextField('Time Path', _timePath),
            _buildTextField('Memory Path', _memoryPath),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? fontFam}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white, fontFamily: fontFam),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryAccent)),
        ),
      ),
    );
  }
}
