import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../providers/compiler_provider.dart';
import '../models/preset_model.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _uuid = const Uuid();

  void _showToast(String msg) {
    Fluttertoast.showToast(msg: msg, backgroundColor: Colors.white24, textColor: Colors.white);
  }

  void _duplicatePreset(PresetModel preset) {
    final newPreset = preset.copyWith(
      id: _uuid.v4(),
      name: '${preset.name} (Copy)',
    );
    ref.read(compilerProvider.notifier).addPreset(newPreset);
    _showToast("Preset duplicated");
  }

  void _exportPresets() {
    final presets = ref.read(compilerProvider).presets;
    final jsonStr = jsonEncode(presets.map((p) => p.toJson()).toList());
    Clipboard.setData(ClipboardData(text: jsonStr));
    _showToast("Presets exported to clipboard!");
  }

  void _importPresets() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      try {
        final List<dynamic> jsonList = jsonDecode(data.text!);
        for (var item in jsonList) {
          final preset = PresetModel.fromJson(item as Map<String, dynamic>);
          ref.read(compilerProvider.notifier).addPreset(preset.copyWith(id: _uuid.v4()));
        }
        _showToast("Presets imported successfully!");
      } catch (e) {
        _showToast("Invalid JSON in clipboard.");
      }
    } else {
      _showToast("Clipboard is empty.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: "Export Presets",
            onPressed: _exportPresets,
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: "Import Presets",
            onPressed: _importPresets,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Disable this to use Custom Compiler API Presets', style: TextStyle(color: Colors.white54)),
                    value: compilerState.useDefaultOneCompiler,
                    activeColor: const Color(0xFFFACC15), // ignore: deprecated_member_use
                    onChanged: (val) {
                      ref.read(compilerProvider.notifier).setUseDefaultOneCompiler(val);
                    },
                  ),
                  const Divider(color: Colors.white24),
                  if (!compilerState.useDefaultOneCompiler) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
                          onPressed: () => _showPresetDialog(context, null),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...compilerState.presets.map((preset) {
                      final isActive = preset.id == compilerState.activePresetId;
                      return Card(
                        color: isActive ? const Color(0xFF1a1a1a) : Colors.black,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: isActive ? const Color(0xFFFACC15) : Colors.white10, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(preset.endpoint.isNotEmpty ? preset.endpoint : 'No endpoint set', style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.white70),
                                tooltip: "Duplicate",
                                onPressed: () => _duplicatePreset(preset),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70),
                                tooltip: "Edit",
                                onPressed: () => _showPresetDialog(context, preset),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: "Delete",
                                onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                              ),
                            ],
                          ),
                          onTap: () {
                            ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                          },
                        ),
                      );
                    }).toList(),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _testConnection(PresetModel preset) async {
    _showToast("Testing connection...");

    String testCode = "void main() { print('Hello from custom API'); }";
    String bodyStr = preset.bodyTemplate
        .replaceAll('{code}', testCode.replaceAll('\n', '\\n').replaceAll('"', '\\"'))
        .replaceAll('{stdin}', '')
        .replaceAll('{language}', 'dart');

    var uri = Uri.parse(preset.endpoint);
    if (preset.queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...preset.queryParams,
      });
    }

    try {
      http.Response response;
      if (preset.httpMethod.toUpperCase() == 'POST') {
        response = await http.post(uri, headers: preset.headers, body: bodyStr.isEmpty ? null : bodyStr);
      } else if (preset.httpMethod.toUpperCase() == 'PUT') {
        response = await http.put(uri, headers: preset.headers, body: bodyStr.isEmpty ? null : bodyStr);
      } else {
        response = await http.get(uri, headers: preset.headers);
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Test Result (Status: ${response.statusCode})', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Text(response.body, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFFFACC15))),
            ),
          ],
        ),
      );
    } catch (e) {
      _showToast("Error: $e");
    }
  }

  void _showPresetDialog(BuildContext context, PresetModel? preset) {
    final isNew = preset == null;
    final nameCtrl = TextEditingController(text: preset?.name ?? '');
    final endpointCtrl = TextEditingController(text: preset?.endpoint ?? '');
    final methodCtrl = TextEditingController(text: preset?.httpMethod ?? 'POST');
    final authTypeNotifier = ValueNotifier<String>(preset?.authType ?? 'None');
    final bodyCtrl = TextEditingController(text: preset?.bodyTemplate ?? '');
    final stdoutCtrl = TextEditingController(text: preset?.stdoutPath ?? '');
    final stderrCtrl = TextEditingController(text: preset?.stderrPath ?? '');
    final errorCtrl = TextEditingController(text: preset?.errorPath ?? '');

    // Dynamic lists for headers and query params
    final List<MapEntry<TextEditingController, TextEditingController>> headerCtrls =
      (preset?.headers ?? {}).entries.map((e) => MapEntry(TextEditingController(text: e.key), TextEditingController(text: e.value))).toList();
    final List<MapEntry<TextEditingController, TextEditingController>> queryCtrls =
      (preset?.queryParams ?? {}).entries.map((e) => MapEntry(TextEditingController(text: e.key), TextEditingController(text: e.value))).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isNew ? 'Add Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Platform Name', labelStyle: TextStyle(color: Colors.white54))),
                      TextField(
                        controller: endpointCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Endpoint URL',
                          labelStyle: const TextStyle(color: Colors.white54),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: endpointCtrl.text));
                              _showToast("URL copied");
                            },
                          ),
                        ),
                      ),
                      TextField(controller: methodCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'HTTP Method (POST/GET/PUT)', labelStyle: TextStyle(color: Colors.white54))),

                      const SizedBox(height: 16),
                      const Text('Auth Type:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      DropdownButton<String>(
                        value: authTypeNotifier.value,
                        dropdownColor: const Color(0xFF1a1a1a),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() { authTypeNotifier.value = val; });
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Headers', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFFFACC15)),
                            onPressed: () {
                              setState(() { headerCtrls.add(MapEntry(TextEditingController(), TextEditingController())); });
                            },
                          )
                        ],
                      ),
                      ...headerCtrls.asMap().entries.map((entry) {
                        int i = entry.key;
                        var ctrl = entry.value;
                        return Row(
                          children: [
                            Expanded(child: TextField(controller: ctrl.key, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.white24)))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: ctrl.value, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.white24)))),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, size: 16, color: Colors.redAccent),
                              onPressed: () { setState(() { headerCtrls.removeAt(i); }); },
                            )
                          ],
                        );
                      }).toList(),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Query Params', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16, color: Color(0xFFFACC15)),
                            onPressed: () {
                              setState(() { queryCtrls.add(MapEntry(TextEditingController(), TextEditingController())); });
                            },
                          )
                        ],
                      ),
                      ...queryCtrls.asMap().entries.map((entry) {
                        int i = entry.key;
                        var ctrl = entry.value;
                        return Row(
                          children: [
                            Expanded(child: TextField(controller: ctrl.key, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.white24)))),
                            const SizedBox(width: 8),
                            Expanded(child: TextField(controller: ctrl.value, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.white24)))),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, size: 16, color: Colors.redAccent),
                              onPressed: () { setState(() { queryCtrls.removeAt(i); }); },
                            )
                          ],
                        );
                      }).toList(),

                      const SizedBox(height: 16),
                      TextField(controller: bodyCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Body Template (JSON)', labelStyle: TextStyle(color: Colors.white54)), maxLines: 3),
                      TextField(controller: stdoutCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stdout Path (dot notation)', labelStyle: TextStyle(color: Colors.white54))),
                      TextField(controller: stderrCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Stderr Path (dot notation)', labelStyle: TextStyle(color: Colors.white54))),
                      TextField(controller: errorCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Error Path (dot notation)', labelStyle: TextStyle(color: Colors.white54))),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                          onPressed: () {
                            // Need to construct a temporary preset to test
                            Map<String, String> hdrs = {};
                            for (var c in headerCtrls) { if(c.key.text.isNotEmpty) hdrs[c.key.text] = c.value.text; }
                            Map<String, String> qrys = {};
                            for (var c in queryCtrls) { if(c.key.text.isNotEmpty) qrys[c.key.text] = c.value.text; }

                            final tempPreset = PresetModel(
                              id: 'temp',
                              name: 'temp',
                              endpoint: endpointCtrl.text,
                              httpMethod: methodCtrl.text.toUpperCase(),
                              authType: authTypeNotifier.value,
                              headers: hdrs,
                              queryParams: qrys,
                              bodyTemplate: bodyCtrl.text,
                            );
                            _testConnection(tempPreset);
                          },
                          child: const Text('Test Connection', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                TextButton(
                  onPressed: () {
                    Map<String, String> finalHeaders = {};
                    for (var c in headerCtrls) { if(c.key.text.isNotEmpty) finalHeaders[c.key.text] = c.value.text; }
                    Map<String, String> finalQueryParams = {};
                    for (var c in queryCtrls) { if(c.key.text.isNotEmpty) finalQueryParams[c.key.text] = c.value.text; }

                    final newPreset = PresetModel(
                      id: isNew ? _uuid.v4() : preset!.id,
                      name: nameCtrl.text,
                      endpoint: endpointCtrl.text,
                      httpMethod: methodCtrl.text.toUpperCase(),
                      authType: authTypeNotifier.value,
                      headers: finalHeaders,
                      queryParams: finalQueryParams,
                      bodyTemplate: bodyCtrl.text,
                      stdoutPath: stdoutCtrl.text,
                      stderrPath: stderrCtrl.text,
                      errorPath: errorCtrl.text,
                    );
                    if (isNew) {
                      ref.read(compilerProvider.notifier).addPreset(newPreset);
                    } else {
                      ref.read(compilerProvider.notifier).updatePreset(newPreset);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Color(0xFFFACC15))),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
