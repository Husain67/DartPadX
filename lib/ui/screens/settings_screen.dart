import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../../models/compiler_preset.dart';
import '../../providers/compiler_provider.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.darkBackgroundStart, AppTheme.darkBackgroundEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const TabBarView(
            children: [
              _CompilerPresetsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompilerPresetsTab extends ConsumerWidget {
  const _CompilerPresetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.presets.length + 1,
      itemBuilder: (context, index) {
        if (index == state.presets.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add New Preset', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentYellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                final newPreset = CompilerPreset(
                  id: const Uuid().v4(),
                  name: 'New Custom API',
                  endpoint: '',
                  httpMethod: 'POST',
                  authType: 'None',
                  headers: {},
                  queryParams: {},
                  bodyTemplate: '{}',
                  stdoutPath: '',
                  stderrPath: '',
                  errorPath: '',
                  executionTimePath: '',
                  memoryPath: '',
                );
                ref.read(compilerProvider.notifier).addPreset(newPreset);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _EditPresetScreen(preset: newPreset),
                  ),
                );
              },
            ),
          );
        }

        final preset = state.presets[index];
        final isActive = preset.id == state.activePresetId;

        return Card(
          color: AppTheme.pureBlack,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: isActive ? AppTheme.accentYellow : Colors.grey[800]!, width: isActive ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(preset.endpoint.isEmpty ? 'No endpoint configured' : preset.endpoint,
                           style: TextStyle(color: Colors.grey[400]),
                           maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  const Icon(Icons.check_circle, color: AppTheme.accentYellow),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _EditPresetScreen(preset: preset),
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              ref.read(compilerProvider.notifier).setActivePreset(preset.id);
            },
          ),
        );
      },
    );
  }
}

class _EditPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const _EditPresetScreen({required this.preset});

  @override
  ConsumerState<_EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<_EditPresetScreen> {
  late TextEditingController _nameController;
  late TextEditingController _endpointController;
  late TextEditingController _bodyController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;

  String _httpMethod = 'POST';
  String _authType = 'None';

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset.name);
    _endpointController = TextEditingController(text: widget.preset.endpoint);

    // Pretty print JSON body if possible
    String bodyText = widget.preset.bodyTemplate;
    try {
      final json = jsonDecode(bodyText);
      bodyText = const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {}
    _bodyController = TextEditingController(text: bodyText);

    _stdoutController = TextEditingController(text: widget.preset.stdoutPath);
    _stderrController = TextEditingController(text: widget.preset.stderrPath);
    _errorController = TextEditingController(text: widget.preset.errorPath);
    _timeController = TextEditingController(text: widget.preset.executionTimePath);
    _memoryController = TextEditingController(text: widget.preset.memoryPath);

    _httpMethod = widget.preset.httpMethod;
    _authType = widget.preset.authType;

    _headers = widget.preset.headers.entries.toList();
    _queryParams = widget.preset.queryParams.entries.toList();
  }

  void _save() {
    // Validate body json
    String bodyTemplate = _bodyController.text;
    try {
      jsonDecode(bodyTemplate.replaceAll('{code}', '""').replaceAll('{stdin}', '""').replaceAll('{language}', '""'));
    } catch (e) {
      Fluttertoast.showToast(msg: "Warning: Body Template might not be valid JSON", timeInSecForIosWeb: 3);
    }

    final updatedPreset = widget.preset.copyWith(
      name: _nameController.text,
      endpoint: _endpointController.text,
      httpMethod: _httpMethod,
      authType: _authType,
      headers: Map.fromEntries(_headers),
      queryParams: Map.fromEntries(_queryParams),
      bodyTemplate: bodyTemplate,
      stdoutPath: _stdoutController.text,
      stderrPath: _stderrController.text,
      errorPath: _errorController.text,
      executionTimePath: _timeController.text,
      memoryPath: _memoryController.text,
    );

    ref.read(compilerProvider.notifier).updatePreset(updatedPreset);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset saved");
  }

  void _delete() {
    if (widget.preset.isPreloaded) {
      Fluttertoast.showToast(msg: "Cannot delete preloaded preset");
      return;
    }
    ref.read(compilerProvider.notifier).deletePreset(widget.preset.id);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: "Preset deleted");
  }

  Widget _buildDynamicTable(String title, List<MapEntry<String, String>> list, Function(List<MapEntry<String, String>>) onUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.accentYellow),
              onPressed: () {
                setState(() {
                  list.add(const MapEntry('', ''));
                  onUpdate(list);
                });
              },
            ),
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int index = entry.key;
          MapEntry<String, String> kv = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: kv.key,
                    decoration: const InputDecoration(labelText: 'Key', filled: true, fillColor: AppTheme.pureBlack),
                    onChanged: (val) {
                      list[index] = MapEntry(val, kv.value);
                      onUpdate(list);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: kv.value,
                    decoration: const InputDecoration(labelText: 'Value', filled: true, fillColor: AppTheme.pureBlack),
                    onChanged: (val) {
                      list[index] = MapEntry(kv.key, val);
                      onUpdate(list);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      list.removeAt(index);
                      onUpdate(list);
                    });
                  },
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
          if (!widget.preset.isPreloaded)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _delete,
            ),
        ],
      ),
      body: Container(
        color: AppTheme.darkBackgroundStart,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Platform Name', filled: true, fillColor: AppTheme.pureBlack),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _endpointController,
                    decoration: const InputDecoration(labelText: 'Endpoint URL', filled: true, fillColor: AppTheme.pureBlack),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _endpointController.text));
                    Fluttertoast.showToast(msg: "Copied to clipboard");
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _httpMethod, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: 'HTTP Method', filled: true, fillColor: AppTheme.pureBlack),
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) { if (val != null) setState(() => _httpMethod = val); },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _authType, // ignore: deprecated_member_use
              decoration: const InputDecoration(labelText: 'Auth Type', filled: true, fillColor: AppTheme.pureBlack),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) { if (val != null) setState(() => _authType = val); },
            ),
            const SizedBox(height: 16),
            _buildDynamicTable('Headers', _headers, (val) => _headers = val),
            const SizedBox(height: 16),
            _buildDynamicTable('Query Params', _queryParams, (val) => _queryParams = val),
            const SizedBox(height: 16),
            const Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Use {code}, {stdin}, {language} placeholders.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(filled: true, fillColor: AppTheme.pureBlack),
              maxLines: 10,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 24),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('e.g. data.run.stdout', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stdoutController,
              decoration: const InputDecoration(labelText: 'stdout path', filled: true, fillColor: AppTheme.pureBlack),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stderrController,
              decoration: const InputDecoration(labelText: 'stderr path', filled: true, fillColor: AppTheme.pureBlack),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _errorController,
              decoration: const InputDecoration(labelText: 'error path (optional)', filled: true, fillColor: AppTheme.pureBlack),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'executionTime path', filled: true, fillColor: AppTheme.pureBlack),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoryController,
              decoration: const InputDecoration(labelText: 'memory path', filled: true, fillColor: AppTheme.pureBlack),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
