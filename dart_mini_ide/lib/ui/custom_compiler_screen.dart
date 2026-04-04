import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';

class CustomCompilerScreen extends ConsumerStatefulWidget {
  const CustomCompilerScreen({super.key});

  @override
  ConsumerState<CustomCompilerScreen> createState() => _CustomCompilerScreenState();
}

class _CustomCompilerScreenState extends ConsumerState<CustomCompilerScreen> {
  final _formKey = GlobalKey<FormState>();
  late CompilerPreset _editingPreset;
  bool _isNew = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreset();
  }

  void _loadCurrentPreset() {
    final state = ref.read(compilerProvider);
    if (state.selectedPreset != null) {
      _editingPreset = state.selectedPreset!.copyWith();
    } else {
      _createNewPreset();
    }
  }

  void _createNewPreset() {
    _isNew = true;
    _editingPreset = CompilerPreset(
      id: const Uuid().v4(),
      platformName: 'New Preset',
      endpointUrl: 'https://',
    );
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_isNew) {
        ref.read(compilerProvider.notifier).addPreset(_editingPreset);
        _isNew = false;
      } else {
        ref.read(compilerProvider.notifier).updatePreset(_editingPreset);
      }
      Fluttertoast.showToast(msg: "Preset saved");
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isTesting = true);

    try {
        final preset = _editingPreset;
        var uri = Uri.parse(preset.endpointUrl);

        if (preset.queryParams.isNotEmpty || preset.authType == 'Query Param') {
          final params = Map<String, String>.from(preset.queryParams);
          if (preset.authType == 'Query Param' && preset.authKey.isNotEmpty) {
            params[preset.authKey] = preset.authValue;
          }
          uri = uri.replace(queryParameters: params);
        }

        final headers = Map<String, String>.from(preset.headers);
        if (preset.authType == 'API-Key Header' && preset.authKey.isNotEmpty) {
          headers[preset.authKey] = preset.authValue;
        } else if (preset.authType == 'Bearer Token') {
          headers['Authorization'] = 'Bearer ${preset.authValue}';
        } else if (preset.authType == 'Basic Auth') {
          final encoded = base64Encode(utf8.encode(preset.authValue));
          headers['Authorization'] = 'Basic $encoded';
        }

        String bodyStr = preset.requestBodyTemplate;
        const code = "void main() { print('Hello from custom API'); }";
        final escapedCode = jsonEncode(code).replaceAll(RegExp(r'^"|"$'), '');

        bodyStr = bodyStr.replaceAll('{code}', escapedCode);
        bodyStr = bodyStr.replaceAll('{stdin}', '');
        bodyStr = bodyStr.replaceAll('{language}', preset.defaultLanguage);

        http.Response response;
        if (preset.httpMethod == 'GET') {
          response = await http.get(uri, headers: headers);
        } else if (preset.httpMethod == 'PUT') {
          response = await http.put(uri, headers: headers, body: bodyStr);
        } else {
          response = await http.post(uri, headers: headers, body: bodyStr);
        }

        _showTestResult(response.statusCode, response.body);
    } catch (e) {
        _showTestResult(500, 'Connection Error: $e');
    } finally {
        if (mounted) setState(() => _isTesting = false);
    }
  }

  void _showTestResult(int statusCode, String body) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              backgroundColor: AppTheme.bgLight,
              title: Text('Test Result (Status: $statusCode)'),
              content: SingleChildScrollView(
                  child: SelectableText(body, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
              actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: AppTheme.accentYellow))
                  )
              ],
          )
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Compilers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _createNewPreset();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreset,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.all(8),
            color: AppTheme.bgDark,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.presets.length,
              itemBuilder: (context, index) {
                final p = state.presets[index];
                final isSelected = p.id == (_isNew ? '' : _editingPreset.id);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(p.platformName),
                    selected: isSelected,
                    selectedColor: AppTheme.accentYellow,
                    backgroundColor: AppTheme.bgLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(compilerProvider.notifier).selectPreset(p.id);
                        setState(() {
                          _isNew = false;
                          _editingPreset = p.copyWith();
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          const Text('Configuration', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold, fontSize: 18)),
                          if (!_isNew) ...[
                              IconButton(
                                  icon: const Icon(Icons.copy, size: 20),
                                  tooltip: 'Duplicate Preset',
                                  onPressed: () {
                                      ref.read(compilerProvider.notifier).duplicatePreset(_editingPreset);
                                      Fluttertoast.showToast(msg: "Preset duplicated");
                                  },
                              ),
                              IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  tooltip: 'Delete Preset',
                                  onPressed: () {
                                      ref.read(compilerProvider.notifier).deletePreset(_editingPreset.id);
                                      setState(() { _loadCurrentPreset(); });
                                  },
                              )
                          ]
                      ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _editingPreset.platformName,
                    decoration: const InputDecoration(labelText: 'Platform Name'),
                    onSaved: (v) => _editingPreset.platformName = v ?? '',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _editingPreset.endpointUrl,
                    decoration: InputDecoration(
                        labelText: 'Endpoint URL',
                        suffixIcon: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                                Clipboard.setData(ClipboardData(text: _editingPreset.endpointUrl));
                                Fluttertoast.showToast(msg: "URL Copied");
                            },
                        )
                    ),
                    onSaved: (v) => _editingPreset.endpointUrl = v ?? '',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _editingPreset.httpMethod,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => _editingPreset.httpMethod = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _editingPreset.authType,
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _editingPreset.authType = v!),
                  ),
                  if (_editingPreset.authType != 'None' && _editingPreset.authType != 'Bearer Token' && _editingPreset.authType != 'Basic Auth') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _editingPreset.authKey,
                      decoration: const InputDecoration(labelText: 'Auth Key (Header Name / Query Param)'),
                      onSaved: (v) => _editingPreset.authKey = v ?? '',
                    ),
                  ],
                  if (_editingPreset.authType != 'None') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _editingPreset.authValue,
                      decoration: const InputDecoration(labelText: 'Auth Value (Token/Key)'),
                      onSaved: (v) => _editingPreset.authValue = v ?? '',
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Request Body Template (JSON)', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold)),
                  const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _editingPreset.requestBodyTemplate,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: const InputDecoration(hintText: '{"code": "{code}"}'),
                    onSaved: (v) => _editingPreset.requestBodyTemplate = v ?? '',
                  ),
                  const SizedBox(height: 24),
                  const Text('Response Mapping (Dot Notation)', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextFormField(initialValue: _editingPreset.stdoutPath, decoration: const InputDecoration(labelText: 'stdout path'), onSaved: (v) => _editingPreset.stdoutPath = v ?? '')),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(initialValue: _editingPreset.stderrPath, decoration: const InputDecoration(labelText: 'stderr path'), onSaved: (v) => _editingPreset.stderrPath = v ?? '')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextFormField(initialValue: _editingPreset.errorPath, decoration: const InputDecoration(labelText: 'error path'), onSaved: (v) => _editingPreset.errorPath = v ?? '')),
                      const SizedBox(width: 8),
                      Expanded(child: TextFormField(initialValue: _editingPreset.executionTimePath, decoration: const InputDecoration(labelText: 'time path'), onSaved: (v) => _editingPreset.executionTimePath = v ?? '')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                          icon: _isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.wifi_tethering),
                          label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                          onPressed: _isTesting ? null : _testConnection,
                      )
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
