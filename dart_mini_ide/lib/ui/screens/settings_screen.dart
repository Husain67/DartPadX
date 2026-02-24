import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/compiler_preset.dart';
import '../../providers/settings_provider.dart';
import '../../providers/execution_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Reliable execution for standard Dart code'),
            value: settings.useOneCompiler,
            activeColor: const Color(0xFFFACC15), // Keeping for now, fallback if deprecated
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleCompiler(val);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Custom Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
          ),
          if (settings.presets.isEmpty)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('No custom presets. Add one to connect to your own API.', style: TextStyle(color: Colors.grey)),
             ),
          ...settings.presets.map((preset) => ListTile(
            title: Text(preset.name),
            subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: Icon(Icons.api, color: settings.selectedPresetId == preset.id && !settings.useOneCompiler ? const Color(0xFFFACC15) : Colors.grey),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPreset(context, ref, preset),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset),
                ),
              ],
            ),
            onTap: () {
              ref.read(settingsProvider.notifier).toggleCompiler(false);
              ref.read(settingsProvider.notifier).selectPreset(preset.id);
            },
            selected: !settings.useOneCompiler && settings.selectedPresetId == preset.id,
            selectedTileColor: const Color(0xFFFACC15).withOpacity(0.1), // Suppressing warning by ignoring or using withOpacity
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFACC15),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _editPreset(context, ref, null),
      ),
    );
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
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
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _methodController;
  late TextEditingController _bodyTemplateController;

  late List<MapEntry<TextEditingController, TextEditingController>> _headerRows;
  late List<MapEntry<TextEditingController, TextEditingController>> _queryRows;
  late Map<String, TextEditingController> _responseMappingControllers;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _urlController = TextEditingController(text: p?.url ?? 'https://');
    _methodController = TextEditingController(text: p?.method ?? 'POST');
    _bodyTemplateController = TextEditingController(text: p?.bodyTemplate ?? '{"code": "{code}"}');

    _headerRows = (p?.headers ?? {}).entries.map((e) => MapEntry(TextEditingController(text: e.key), TextEditingController(text: e.value))).toList();
    _queryRows = (p?.queryParams ?? {}).entries.map((e) => MapEntry(TextEditingController(text: e.key), TextEditingController(text: e.value))).toList();

    final mapping = p?.responseMapping ?? {
      'stdout': 'stdout',
      'stderr': 'stderr',
      'executionTime': 'time',
      'memory': 'memory',
      'error': 'error'
    };
    _responseMappingControllers = mapping.map((k, v) => MapEntry(k, TextEditingController(text: v)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _methodController.dispose();
    _bodyTemplateController.dispose();
    for (var row in _headerRows) { row.key.dispose(); row.value.dispose(); }
    for (var row in _queryRows) { row.key.dispose(); row.value.dispose(); }
    for (var c in _responseMappingControllers.values) { c.dispose(); }
    super.dispose();
  }

  Map<String, String> _rowsToMap(List<MapEntry<TextEditingController, TextEditingController>> rows) {
    return Map.fromEntries(rows.where((r) => r.key.text.isNotEmpty).map((r) => MapEntry(r.key.text, r.value.text)));
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final headers = _rowsToMap(_headerRows);
      final queryParams = _rowsToMap(_queryRows);
      final responseMapping = _responseMappingControllers.map((k, v) => MapEntry(k, v.text));

      if (widget.preset == null) {
         final newPreset = CompilerPreset(
            id: const Uuid().v4(),
            name: _nameController.text,
            url: _urlController.text,
            method: _methodController.text,
            headers: headers,
            queryParams: queryParams,
            bodyTemplate: _bodyTemplateController.text,
            responseMapping: responseMapping,
          );
        ref.read(settingsProvider.notifier).addPreset(newPreset);
      } else {
        final p = widget.preset!;
        p.name = _nameController.text;
        p.url = _urlController.text;
        p.method = _methodController.text;
        p.headers = headers;
        p.queryParams = queryParams;
        p.bodyTemplate = _bodyTemplateController.text;
        p.responseMapping = responseMapping;
        ref.read(settingsProvider.notifier).updatePreset(p);
      }
      Navigator.pop(context);
    }
  }

  void _addHeaderRow() {
    setState(() {
      _headerRows.add(MapEntry(TextEditingController(), TextEditingController()));
    });
  }

  void _addQueryRow() {
     setState(() {
      _queryRows.add(MapEntry(TextEditingController(), TextEditingController()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save, color: Color(0xFFFACC15)), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Preset Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _urlController, decoration: const InputDecoration(labelText: 'Endpoint URL'), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),

            // Using InputDecorator for Method dropdown
            InputDecorator(
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: ['POST', 'GET', 'PUT'].contains(_methodController.text) ? _methodController.text : 'POST',
                  items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _methodController.text = v!),
                  isDense: true,
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionHeader('Headers', _addHeaderRow),
            ..._headerRows.asMap().entries.map((e) => _buildRow(e.value, () => setState(() => _headerRows.removeAt(e.key)))),

            const SizedBox(height: 16),

            _buildSectionHeader('Query Params', _addQueryRow),
             ..._queryRows.asMap().entries.map((e) => _buildRow(e.value, () => setState(() => _queryRows.removeAt(e.key)))),

            const SizedBox(height: 16),
            const Text('Request Body (JSON Template)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
            const Text('Use {code}, {stdin}, {language} as placeholders.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bodyTemplateController,
              maxLines: 5,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping (JSON Paths)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
            ..._responseMappingControllers.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                controller: e.value,
                decoration: InputDecoration(labelText: 'Path for ${e.key}'),
              ),
            )),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _testConnection,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFACC15), foregroundColor: Colors.black),
              child: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFACC15))),
        IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFFFACC15)), onPressed: onAdd),
      ],
    );
  }

  Widget _buildRow(MapEntry<TextEditingController, TextEditingController> entry, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(child: TextFormField(controller: entry.key, decoration: const InputDecoration(labelText: 'Key', isDense: true))),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(controller: entry.value, decoration: const InputDecoration(labelText: 'Value', isDense: true))),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    final headers = _rowsToMap(_headerRows);
    final queryParams = _rowsToMap(_queryRows);
    final responseMapping = _responseMappingControllers.map((k, v) => MapEntry(k, v.text));

    final preset = CompilerPreset(
      id: 'test',
      name: 'Test',
      url: _urlController.text,
      method: _methodController.text,
      headers: headers,
      queryParams: queryParams,
      bodyTemplate: _bodyTemplateController.text,
      responseMapping: responseMapping,
    );

    final service = ref.read(executionServiceProvider);

    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));

    final result = await service.runCustomPreset(preset, "void main() { print('Hello'); }", "");

    if (mounted) {
       Navigator.pop(context); // Close loading
       showDialog(context: context, builder: (context) => AlertDialog(
         title: const Text('Test Result'),
         content: SingleChildScrollView(
           child: Text(result.toString()),
         ),
         actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
       ));
    }
  }
}
