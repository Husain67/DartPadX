import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/preset_model.dart';
import '../providers/compiler_provider.dart';
import '../providers/file_provider.dart';
import 'theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryAccent,
            tabs: [
              Tab(text: 'Compiler Presets'),
              Tab(text: 'Examples Gallery'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CompilerPresetsTab(),
            ExamplesGalleryTab(),
          ],
        ),
      ),
    );
  }
}

class CompilerPresetsTab extends ConsumerWidget {
  const CompilerPresetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compState = ref.watch(compilerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('If off, it uses the selected Custom Preset below.'),
          value: compState.useOneCompiler,
          // ignore: deprecated_member_use
          activeColor: AppTheme.primaryAccent,
          onChanged: (val) {
            ref.read(compilerProvider.notifier).setUseOneCompiler(val);
          },
        ),
        const Divider(color: Colors.white24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Custom Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  tooltip: 'Export Presets',
                  onPressed: () {
                    final jsonStr = jsonEncode(compState.presets.map((p) => {
                      'id': p.id,
                      'name': p.name,
                      'endpoint': p.endpoint,
                      'method': p.method,
                      'authType': p.authType,
                      'authValue': p.authValue,
                      'authKey': p.authKey,
                      'headers': p.headers,
                      'queryParams': p.queryParams,
                      'bodyTemplate': p.bodyTemplate,
                      'stdoutPath': p.stdoutPath,
                      'stderrPath': p.stderrPath,
                      'errorPath': p.errorPath,
                      'executionTimePath': p.executionTimePath,
                      'memoryPath': p.memoryPath,
                    }).toList());
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    Fluttertoast.showToast(msg: "Presets exported to clipboard");
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.file_upload, color: Colors.white),
                  tooltip: 'Import Presets',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      try {
                        List<dynamic> parsed = jsonDecode(data!.text!);
                        List<PresetModel> imported = parsed.map((m) => PresetModel(
                          id: m['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          name: m['name'] ?? 'Imported',
                          endpoint: m['endpoint'] ?? '',
                          method: m['method'] ?? 'POST',
                          authType: m['authType'] ?? 'None',
                          authValue: m['authValue'] ?? '',
                          authKey: m['authKey'] ?? '',
                          headers: Map<String, String>.from(m['headers'] ?? {}),
                          queryParams: Map<String, String>.from(m['queryParams'] ?? {}),
                          bodyTemplate: m['bodyTemplate'] ?? '{}',
                          stdoutPath: m['stdoutPath'] ?? '',
                          stderrPath: m['stderrPath'] ?? '',
                          errorPath: m['errorPath'] ?? '',
                          executionTimePath: m['executionTimePath'] ?? '',
                          memoryPath: m['memoryPath'] ?? '',
                        )).toList();
                        ref.read(compilerProvider.notifier).importPresets(imported);
                        Fluttertoast.showToast(msg: "Imported \${imported.length} presets");
                      } catch (e) {
                        Fluttertoast.showToast(msg: "Invalid JSON format");
                      }
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, color: AppTheme.primaryAccent),
                  label: const Text('Add', style: TextStyle(color: AppTheme.primaryAccent)),
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
                  },
                )
              ],
            )
          ],
        ),
        ...compState.presets.map((preset) {
          final isSelected = compState.activePresetId == preset.id;
          return Card(
            color: isSelected ? Colors.white10 : Colors.black26,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: isSelected ? AppTheme.primaryAccent : Colors.transparent, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(preset.name),
              subtitle: Text(preset.endpoint, style: const TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white54),
                    tooltip: 'Duplicate',
                    onPressed: () {
                      final dupe = PresetModel(
                        id: "\${preset.id}_copy_\${DateTime.now().millisecondsSinceEpoch}",
                        name: "\${preset.name} (Copy)",
                        endpoint: preset.endpoint,
                        method: preset.method,
                        authType: preset.authType,
                        authValue: preset.authValue,
                        authKey: preset.authKey,
                        headers: Map.from(preset.headers),
                        queryParams: Map.from(preset.queryParams),
                        bodyTemplate: preset.bodyTemplate,
                        stdoutPath: preset.stdoutPath,
                        stderrPath: preset.stderrPath,
                        errorPath: preset.errorPath,
                        executionTimePath: preset.executionTimePath,
                        memoryPath: preset.memoryPath,
                      );
                      ref.read(compilerProvider.notifier).savePreset(dupe);
                      Fluttertoast.showToast(msg: "Preset duplicated");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                    }
                  ),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                    ref.read(compilerProvider.notifier).deletePreset(preset.id);
                  }),
                ],
              ),
              onTap: () {
                ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                ref.read(compilerProvider.notifier).setUseOneCompiler(false);
              },
            ),
          );
        }),
      ],
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final PresetModel? preset;
  const PresetEditorScreen({super.key, this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController endpointCtrl;
  late String method;
  late String authType;
  late TextEditingController authKeyCtrl;
  late TextEditingController authValueCtrl;
  late TextEditingController bodyCtrl;
  late TextEditingController stdoutCtrl;
  late TextEditingController stderrCtrl;
  late TextEditingController errorCtrl;
  late TextEditingController execTimeCtrl;
  late TextEditingController memoryCtrl;

  List<MapEntry<String, String>> headersList = [];
  List<MapEntry<String, String>> paramsList = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    nameCtrl = TextEditingController(text: p?.name ?? '');
    endpointCtrl = TextEditingController(text: p?.endpoint ?? '');
    method = p?.method ?? 'POST';
    authType = p?.authType ?? 'None';
    authKeyCtrl = TextEditingController(text: p?.authKey ?? '');
    authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    bodyCtrl = TextEditingController(text: p?.bodyTemplate ?? '{\\n  "code": "{code}",\\n  "stdin": "{stdin}"\\n}');
    stdoutCtrl = TextEditingController(text: p?.stdoutPath ?? 'stdout');
    stderrCtrl = TextEditingController(text: p?.stderrPath ?? 'stderr');
    errorCtrl = TextEditingController(text: p?.errorPath ?? 'error');
    execTimeCtrl = TextEditingController(text: p?.executionTimePath ?? 'executionTime');
    memoryCtrl = TextEditingController(text: p?.memoryPath ?? 'memory');

    if (p != null) {
      headersList = p.headers.entries.toList();
      paramsList = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    endpointCtrl.dispose();
    authKeyCtrl.dispose();
    authValueCtrl.dispose();
    bodyCtrl.dispose();
    stdoutCtrl.dispose();
    stderrCtrl.dispose();
    errorCtrl.dispose();
    execTimeCtrl.dispose();
    memoryCtrl.dispose();
    super.dispose();
  }

  PresetModel _buildCurrentModel() {
    return PresetModel(
      id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: nameCtrl.text,
      endpoint: endpointCtrl.text,
      method: method,
      authType: authType,
      authKey: authKeyCtrl.text,
      authValue: authValueCtrl.text,
      headers: Map.fromEntries(headersList),
      queryParams: Map.fromEntries(paramsList),
      bodyTemplate: bodyCtrl.text,
      stdoutPath: stdoutCtrl.text,
      stderrPath: stderrCtrl.text,
      errorPath: errorCtrl.text,
      executionTimePath: execTimeCtrl.text,
      memoryPath: memoryCtrl.text,
    );
  }

  void _testConnection() async {
    final model = _buildCurrentModel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent)),
    );
    final result = await ref.read(compilerProvider.notifier).testConnection(model);
    if (!mounted) return;
    Navigator.pop(context); // pop loading

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Connection Result'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Success: \${result["success"]}'),
              if (result.containsKey('statusCode')) Text('Status: \${result["statusCode"]}'),
              if (result.containsKey('time')) Text('HTTP Time: \${result["time"]}'),
              const Divider(),
              if (result.containsKey('rawBody')) ...[
                const Text('Raw Body:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(result['rawBody'], style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                const Divider(),
              ],
              const Text('Parsed Output:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('stdout: \${result["stdout"]}'),
              Text('stderr: \${result["stderr"]}'),
              Text('error: \${result["error"]}'),
              Text('executionTime: \${result["parsedTime"]}'),
              Text('memory: \${result["parsedMemory"]}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      )
    );
  }

  void _save() {
    ref.read(compilerProvider.notifier).savePreset(_buildCurrentModel());
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset saved");
  }

  Widget _buildMapList(String title, List<MapEntry<String, String>> list, VoidCallback onUpdate) {
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
                list.add(const MapEntry('new_key', 'new_value'));
                onUpdate();
              }
            )
          ],
        ),
        ...list.asMap().entries.map((e) {
          int idx = e.key;
          MapEntry<String, String> entry = e.value;
          return Row(
            children: [
              Expanded(child: TextFormField(
                initialValue: entry.key,
                onChanged: (val) { list[idx] = MapEntry(val, entry.value); onUpdate(); },
                decoration: const InputDecoration(isDense: true, hintText: 'Key'),
              )),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(
                initialValue: entry.value,
                onChanged: (val) { list[idx] = MapEntry(entry.key, val); onUpdate(); },
                decoration: const InputDecoration(isDense: true, hintText: 'Value'),
              )),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  list.removeAt(idx);
                  onUpdate();
                }
              )
            ],
          );
        })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Platform Name')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: endpointCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL'))),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: endpointCtrl.text));
                    Fluttertoast.showToast(msg: "URL copied");
                  }
                )
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => method = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => authType = v!),
            ),
            if (authType != 'None') ...[
              const SizedBox(height: 16),
              if (authType == 'API-Key Header' || authType == 'Query Param')
                TextField(controller: authKeyCtrl, decoration: const InputDecoration(labelText: 'Auth Key (Header/Param Name)')),
              TextField(controller: authValueCtrl, decoration: const InputDecoration(labelText: 'Auth Value (Token/Secret)')),
            ],
            const SizedBox(height: 16),
            const Divider(),
            _buildMapList('Dynamic Headers', headersList, () => setState((){})),
            const Divider(),
            _buildMapList('Dynamic Query Params', paramsList, () => setState((){})),
            const Divider(),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(border: OutlineInputBorder())
            ),
            const Divider(),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: TextField(controller: stdoutCtrl, decoration: const InputDecoration(labelText: 'stdout path', isDense: true)))]),
            Row(children: [Expanded(child: TextField(controller: stderrCtrl, decoration: const InputDecoration(labelText: 'stderr path', isDense: true)))]),
            Row(children: [Expanded(child: TextField(controller: errorCtrl, decoration: const InputDecoration(labelText: 'error path', isDense: true)))]),
            Row(children: [Expanded(child: TextField(controller: execTimeCtrl, decoration: const InputDecoration(labelText: 'executionTime path', isDense: true)))]),
            Row(children: [Expanded(child: TextField(controller: memoryCtrl, decoration: const InputDecoration(labelText: 'memory path', isDense: true)))]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent, foregroundColor: Colors.black),
                onPressed: _testConnection,
                child: const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}


class ExamplesGalleryTab extends ConsumerWidget {
  const ExamplesGalleryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = {
      'Hello World': "void main() {\\n  print('Hello, World!');\\n}",
      'List & Loops': "void main() {\\n  List<int> numbers = [1, 2, 3, 4, 5];\\n  for (var n in numbers) {\\n    print('Number: \$n');\\n  }\\n}",
      'Async/Await': "Future<void> main() async {\\n  print('Fetching data...');\\n  await Future.delayed(const Duration(seconds: 2));\\n  print('Done!');\\n}",
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: examples.entries.map((e) => Card(
        color: Colors.white10,
        child: ListTile(
          title: Text(e.key),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            ref.read(fileProvider.notifier).addNewFile("\${e.key.replaceAll(' ', '_').toLowerCase()}.dart", e.value);
            Navigator.pop(context);
            Fluttertoast.showToast(msg: "Example loaded");
          },
        ),
      )).toList(),
    );
  }
}
