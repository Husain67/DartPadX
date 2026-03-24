import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';

class PresetEditorScreen extends StatefulWidget {
  final CompilerPreset preset;

  const PresetEditorScreen({super.key, required this.preset});

  @override
  State<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  late String _httpMethod;
  late String _authType;
  late Map<String, String> _headers;
  late Map<String, String> _queryParams;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.name);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    _stdoutPathCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrPathCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errorPathCtrl = TextEditingController(text: widget.preset.errorPath);
    _timePathCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memoryPathCtrl = TextEditingController(text: widget.preset.memoryPath);

    _httpMethod = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _headers = Map.from(widget.preset.headers);
    _queryParams = Map.from(widget.preset.queryParams);
  }

  void _savePreset() {
    if (_formKey.currentState!.validate()) {
      widget.preset.name = _nameCtrl.text;
      widget.preset.endpointUrl = _urlCtrl.text;
      widget.preset.requestBodyTemplate = _bodyCtrl.text;
      widget.preset.stdoutPath = _stdoutPathCtrl.text;
      widget.preset.stderrPath = _stderrPathCtrl.text;
      widget.preset.errorPath = _errorPathCtrl.text;
      widget.preset.executionTimePath = _timePathCtrl.text;
      widget.preset.memoryPath = _memoryPathCtrl.text;
      widget.preset.httpMethod = _httpMethod;
      widget.preset.authType = _authType;
      widget.preset.headers = _headers;
      widget.preset.queryParams = _queryParams;

      Hive.box<CompilerPreset>('presets').put(widget.preset.id, widget.preset);
      Fluttertoast.showToast(msg: "Preset saved");
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    Fluttertoast.showToast(msg: "Testing connection...");

    String code = "void main() { print('Hello from custom API'); }";
    String stdin = "";

    // execution_provider replaces "{code}" entirely.
    // So here we do the same, keeping JSON valid.
    String bodyStr = widget.preset.requestBodyTemplate
        .replaceAll('"{code}"', jsonEncode(code))
        .replaceAll('"{stdin}"', jsonEncode(stdin))
        .replaceAll('{code}', jsonEncode(code))
        .replaceAll('{stdin}', jsonEncode(stdin))
        .replaceAll('{language}', 'dart');

    Map<String, String> reqHeaders = Map.from(_headers);
    if (!reqHeaders.containsKey('Content-Type')) {
        reqHeaders['Content-Type'] = 'application/json';
    }

    if (_authType == 'Bearer Token') {
      final token = reqHeaders['Authorization'] ?? '';
      reqHeaders['Authorization'] = 'Bearer $token';
    }

    Uri uri = Uri.parse(_urlCtrl.text);
    if (_queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: _queryParams);
    }

    try {
      http.Response response;
      if (_httpMethod == 'GET') {
        response = await http.get(uri, headers: reqHeaders);
      } else if (_httpMethod == 'PUT') {
          response = await http.put(uri, headers: reqHeaders, body: bodyStr);
      } else {
        response = await http.post(uri, headers: reqHeaders, body: bodyStr);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.pureBlack,
          title: Text('Response (${response.statusCode})', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Text(response.body, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: AppTheme.primaryYellow)),
            ),
          ],
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection failed: $e");
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: multiLine ? 5 : 1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryYellow)),
        ),
        validator: (value) => value!.isEmpty && !multiLine && label.contains('Name') ? 'Required' : null,
      ),
    );
  }

  Widget _buildMapEditor(String title, Map<String, String> map) {
    // Convert to list to iterate safely and allow updates
    final entries = map.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryYellow),
              onPressed: () {
                setState(() {
                  map['NewKey${map.length}'] = 'Value';
                });
              },
            ),
          ],
        ),
        ...List.generate(entries.length, (index) {
          final entry = entries[index];
          final keyCtrl = TextEditingController(text: entry.key);
          final valCtrl = TextEditingController(text: entry.value);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        final newKey = keyCtrl.text;
                        final oldKey = entries[index].key;
                        if (newKey != oldKey && newKey.isNotEmpty) {
                          setState(() {
                            final val = map.remove(oldKey);
                            map[newKey] = val ?? '';
                          });
                        }
                      }
                    },
                    child: TextFormField(
                      controller: keyCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(isDense: true, enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: valCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(isDense: true, enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
                    onChanged: (val) {
                      map[entries[index].key] = val;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      map.remove(entries[index].key);
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
      backgroundColor: AppTheme.pureBlack,
      appBar: AppBar(
        title: const Text('Edit Preset'),
        backgroundColor: AppTheme.pureBlack,
        actions: [
          IconButton(icon: const Icon(Icons.play_circle_fill, color: AppTheme.primaryYellow), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save), onPressed: _savePreset),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('Platform Name', _nameCtrl),
              _buildTextField('Endpoint URL', _urlCtrl),

              DropdownButtonFormField<String>(
                value: _httpMethod,
                dropdownColor: AppTheme.pureBlack,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'HTTP Method', labelStyle: TextStyle(color: Colors.white54)),
                items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _httpMethod = val!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _authType,
                dropdownColor: AppTheme.pureBlack,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Auth Type', labelStyle: TextStyle(color: Colors.white54)),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _authType = val!),
              ),
              const SizedBox(height: 24),

              _buildMapEditor('Headers', _headers),
              _buildMapEditor('Query Params', _queryParams),

              const Text('Request Body Template (JSON)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Text('Use {code}, {stdin}, {language} placeholders', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              _buildTextField('JSON Body', _bodyCtrl, multiLine: true),

              const Text('Response Mapping (Dot Notation paths)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildTextField('stdout path (e.g. data.run.stdout)', _stdoutPathCtrl),
              _buildTextField('stderr path', _stderrPathCtrl),
              _buildTextField('error path', _errorPathCtrl),
              _buildTextField('executionTime path', _timePathCtrl),
              _buildTextField('memory path', _memoryPathCtrl),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
