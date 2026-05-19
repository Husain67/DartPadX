import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/compiler_preset.dart';
import '../../providers/settings_provider.dart';
import '../../app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  final bool isNew;

  const PresetEditorScreen({super.key, required this.preset, this.isNew = false});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late String endpointUrl;
  late String httpMethod;
  late String authType;
  late String authValue;
  late List<MapEntry<String, String>> headers;
  late List<MapEntry<String, String>> queryParams;
  late String bodyTemplate;
  late String stdoutPath;
  late String stderrPath;
  late String errorPath;
  late String executionTimePath;
  late String memoryPath;

  @override
  void initState() {
    super.initState();
    name = widget.preset.name;
    endpointUrl = widget.preset.endpointUrl;
    httpMethod = widget.preset.httpMethod;
    authType = widget.preset.authType;
    authValue = widget.preset.authValue;
    headers = widget.preset.headers.entries.toList();
    queryParams = widget.preset.queryParams.entries.toList();
    bodyTemplate = widget.preset.bodyTemplate;
    stdoutPath = widget.preset.stdoutPath;
    stderrPath = widget.preset.stderrPath;
    errorPath = widget.preset.errorPath;
    executionTimePath = widget.preset.executionTimePath;
    memoryPath = widget.preset.memoryPath;
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedPreset = widget.preset.copyWith(
        name: name,
        endpointUrl: endpointUrl,
        httpMethod: httpMethod,
        authType: authType,
        authValue: authValue,
        headers: Map.fromEntries(headers),
        queryParams: Map.fromEntries(queryParams),
        bodyTemplate: bodyTemplate,
        stdoutPath: stdoutPath,
        stderrPath: stderrPath,
        errorPath: errorPath,
        executionTimePath: executionTimePath,
        memoryPath: memoryPath,
      );

      if (widget.isNew) {
        ref.read(settingsProvider.notifier).addPreset(updatedPreset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(updatedPreset);
      }

      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    Fluttertoast.showToast(msg: "Testing connection...", backgroundColor: Colors.blue);

    // Create a mock preset from current form state
    _formKey.currentState!.save();
    final tempPreset = widget.preset.copyWith(
        name: name,
        endpointUrl: endpointUrl,
        httpMethod: httpMethod,
        authType: authType,
        authValue: authValue,
        headers: Map.fromEntries(headers),
        queryParams: Map.fromEntries(queryParams),
        bodyTemplate: bodyTemplate,
        stdoutPath: stdoutPath,
        stderrPath: stderrPath,
        errorPath: errorPath,
        executionTimePath: executionTimePath,
        memoryPath: memoryPath,
      );

    final code = "void main() { print('Hello from custom API'); }";
    final stdin = "";

    final urlStr = _replaceTokens(tempPreset.endpointUrl, tempPreset.authValue, code, stdin);
    final url = Uri.parse(urlStr);

    Map<String, String> finalHeaders = {};
    for (var entry in tempPreset.headers.entries) {
      finalHeaders[entry.key] = _replaceTokens(entry.value, tempPreset.authValue, code, stdin);
    }

    if (tempPreset.authType == 'Bearer Token') {
      finalHeaders['Authorization'] = 'Bearer ${tempPreset.authValue}';
    } else if (tempPreset.authType == 'Basic Auth') {
      final basicAuth = base64Encode(utf8.encode(tempPreset.authValue));
      finalHeaders['Authorization'] = 'Basic $basicAuth';
    }

    var uriWithParams = url;
    if (tempPreset.queryParams.isNotEmpty) {
      Map<String, String> finalParams = {};
      for (var entry in tempPreset.queryParams.entries) {
        finalParams[entry.key] = _replaceTokens(entry.value, tempPreset.authValue, code, stdin);
      }
      uriWithParams = url.replace(queryParameters: finalParams);
    }

    String finalBody = _replaceTokens(tempPreset.bodyTemplate, tempPreset.authValue, code, stdin);

    try {
      http.Response response;
      if (tempPreset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uriWithParams, headers: finalHeaders, body: finalBody);
      } else if (tempPreset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uriWithParams, headers: finalHeaders, body: finalBody);
      } else {
        response = await http.get(uriWithParams, headers: finalHeaders);
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Response ${response.statusCode}'),
          content: SingleChildScrollView(
            child: Text(response.body, style: const TextStyle(fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppTheme.primaryYellow)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppTheme.primaryYellow)),
            ),
          ],
        ),
      );
    }
  }

  String _replaceTokens(String template, String auth, String code, String stdin) {
    if (template.isEmpty) return template;
    final safeCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');
    final safeStdin = jsonEncode(stdin).replaceAll(RegExp(r'^"|"$'), '');

    return template
        .replaceAll('{authValue}', auth)
        .replaceAll('{code}', safeCode)
        .replaceAll('{stdin}', safeStdin)
        .replaceAll('{language}', 'dart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: AppTheme.primaryYellow),
            onPressed: _testConnection,
            tooltip: 'Test Connection',
          ),
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryYellow),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('General'),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Platform Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => name = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: endpointUrl,
                decoration: InputDecoration(
                  labelText: 'Endpoint URL',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () { Clipboard.setData(ClipboardData(text: endpointUrl)); Fluttertoast.showToast(msg: 'Copied endpoint URL'); },
                  ),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => endpointUrl = val!,
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: httpMethod,
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['GET', 'POST', 'PUT']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => httpMethod = val!),
                onSaved: (val) => httpMethod = val!,
              ),

              _buildSectionTitle('Authentication'),
              DropdownButtonFormField<String>(
                initialValue: authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (val) => setState(() => authType = val!),
                onSaved: (val) => authType = val!,
              ),
              if (authType != 'None') ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: authValue,
                  decoration: const InputDecoration(labelText: 'Auth Value (Token/Key)'),
                  onSaved: (val) => authValue = val ?? '',
                ),
              ],

              _buildSectionTitle('Dynamic Headers'),
              ..._buildDynamicList(headers),
              ElevatedButton.icon(
                onPressed: () => setState(() => headers.add(const MapEntry('', ''))),
                icon: const Icon(Icons.add),
                label: const Text('Add Header'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.backgroundGradientEnd),
              ),

              _buildSectionTitle('Dynamic Query Params'),
              ..._buildDynamicList(queryParams),
              ElevatedButton.icon(
                onPressed: () => setState(() => queryParams.add(const MapEntry('', ''))),
                icon: const Icon(Icons.add),
                label: const Text('Add Param'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.backgroundGradientEnd),
              ),

              _buildSectionTitle('Request Body Template'),
              const Text('Use {code}, {stdin}, {language}, {authValue}', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: bodyTemplate,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '{\n  "code": "{code}"\n}',
                ),
                maxLines: 10,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                onSaved: (val) => bodyTemplate = val ?? '',
              ),

              _buildSectionTitle('Response Mapping (Dot Notation)'),
              TextFormField(initialValue: stdoutPath, decoration: const InputDecoration(labelText: 'stdout path'), onSaved: (val) => stdoutPath = val ?? ''),
              TextFormField(initialValue: stderrPath, decoration: const InputDecoration(labelText: 'stderr path'), onSaved: (val) => stderrPath = val ?? ''),
              TextFormField(initialValue: errorPath, decoration: const InputDecoration(labelText: 'error path'), onSaved: (val) => errorPath = val ?? ''),
              TextFormField(initialValue: executionTimePath, decoration: const InputDecoration(labelText: 'executionTime path'), onSaved: (val) => executionTimePath = val ?? ''),
              TextFormField(initialValue: memoryPath, decoration: const InputDecoration(labelText: 'memory path'), onSaved: (val) => memoryPath = val ?? ''),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  List<Widget> _buildDynamicList(List<MapEntry<String, String>> list) {
    return list.asMap().entries.map((entry) {
      int idx = entry.key;
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: entry.value.key,
              decoration: const InputDecoration(hintText: 'Key'),
              onChanged: (val) => list[idx] = MapEntry(val, list[idx].value),
              onSaved: (val) => list[idx] = MapEntry(val ?? '', list[idx].value),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: entry.value.value,
              decoration: const InputDecoration(hintText: 'Value'),
              onChanged: (val) => list[idx] = MapEntry(list[idx].key, val),
              onSaved: (val) => list[idx] = MapEntry(list[idx].key, val ?? ''),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: () => setState(() => list.removeAt(idx)),
          )
        ],
      );
    }).toList();
  }
}
