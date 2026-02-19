import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/compiler_preset.dart';
import '../utils/constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Compiler Configuration', style: TextStyle(color: AppColors.primaryAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          RadioListTile<CompilerPreset?>(
            title: const Text('Default (OneCompiler)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Ready-to-use dart compiler', style: TextStyle(color: Colors.white54)),
            value: null,
            groupValue: settings.activePreset,
            onChanged: (value) => notifier.setActivePreset(value),
            activeColor: AppColors.primaryAccent,
            tileColor: settings.activePreset == null ? Colors.white10 : null,
          ),
          const Divider(color: Colors.white24),
          if (settings.presets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("No custom presets yet.", style: TextStyle(color: Colors.white30)),
            ),
          ...settings.presets.map((preset) {
            return ListTile(
              title: Text(preset.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(preset.endpoint, style: const TextStyle(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis),
              leading: Radio<CompilerPreset?>(
                value: preset,
                groupValue: settings.activePreset,
                onChanged: (value) => notifier.setActivePreset(value),
                activeColor: AppColors.primaryAccent,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white54),
                onPressed: () => _showEditPresetDialog(context, preset),
              ),
              tileColor: settings.activePreset == preset ? Colors.white10 : null,
            );
          }),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Preset'),
              onPressed: () => _showEditPresetDialog(context, null),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditPresetDialog(BuildContext context, CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => PresetEditorScreen(preset: preset)));
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
  late TextEditingController _endpointController;
  late TextEditingController _methodController;
  late TextEditingController _bodyTemplateController;

  // Maps for headers and mapping
  late Map<String, String> _headers;
  late Map<String, String> _mapping;
  late Map<String, String> _queryParams;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _endpointController = TextEditingController(text: widget.preset?.endpoint ?? '');
    _methodController = TextEditingController(text: widget.preset?.method ?? 'POST');
    _bodyTemplateController = TextEditingController(text: widget.preset?.bodyTemplate ?? '{\n  "code": "{code}",\n  "stdin": "{stdin}"\n}');

    _headers = Map.from(widget.preset?.headers ?? {'Content-Type': 'application/json'});
    _mapping = Map.from(widget.preset?.responseMapping ?? {
      'stdout': 'stdout',
      'stderr': 'stderr',
      'executionTime': 'executionTime',
      'error': 'error'
    });
    _queryParams = Map.from(widget.preset?.queryParams ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
           IconButton(onPressed: _save, icon: const Icon(Icons.save, color: AppColors.primaryAccent))
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Info'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Preset Name'),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endpointController,
                decoration: const InputDecoration(labelText: 'Endpoint URL'),
                style: const TextStyle(color: Colors.white),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: ['POST', 'GET', 'PUT'].contains(_methodController.text) ? _methodController.text : 'POST',
                items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _methodController.text = v!),
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Request Body Template'),
              const Text('Placeholders: {code}, {stdin}, {language}', style: TextStyle(color: Colors.white30, fontSize: 12)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyTemplateController,
                decoration: const InputDecoration(
                  hintText: 'JSON Body Template',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                maxLines: 8,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Headers'),
              _buildMapEditor(_headers, 'Header', 'Value'),

              const SizedBox(height: 24),
              _buildSectionTitle('Query Params'),
              _buildMapEditor(_queryParams, 'Param', 'Value'),

              const SizedBox(height: 24),
              _buildSectionTitle('Response Mapping (JSON Path)'),
              const Text('Dot notation: e.g. "output.stdout"', style: TextStyle(color: Colors.white30, fontSize: 12)),
              const SizedBox(height: 8),
              _buildMappingField('stdout'),
              _buildMappingField('stderr'),
              _buildMappingField('executionTime'),
              _buildMappingField('memory'),
              _buildMappingField('error'),

              const SizedBox(height: 32),
              if (widget.preset != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                    onPressed: () {
                      ref.read(settingsProvider.notifier).deletePreset(widget.preset!);
                      Navigator.pop(context);
                    },
                    child: const Text('Delete Preset', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(color: AppColors.primaryAccent, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMappingField(String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(key, style: const TextStyle(color: Colors.white70))),
          Expanded(
            child: TextFormField(
              initialValue: _mapping[key],
              onChanged: (v) => _mapping[key] = v,
              decoration: InputDecoration(hintText: 'path.to.$key'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapEditor(Map<String, String> map, String keyLabel, String valueLabel) {
    return Column(
      children: [
        ...map.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(child: Text('${e.key}: ${e.value}', style: const TextStyle(color: Colors.white70, overflow: TextOverflow.ellipsis))),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.white30),
                onPressed: () => setState(() => map.remove(e.key)),
              ),
            ],
          ),
        )),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: Text('Add $keyLabel'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white),
          onPressed: () => _showAddEntryDialog(map, keyLabel, valueLabel),
        ),
      ],
    );
  }

  void _showAddEntryDialog(Map<String, String> map, String keyLabel, String valueLabel) {
    String k = '', v = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $keyLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(onChanged: (val) => k = val, decoration: InputDecoration(labelText: keyLabel)),
            const SizedBox(height: 8),
            TextField(onChanged: (val) => v = val, decoration: InputDecoration(labelText: valueLabel)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (k.isNotEmpty) {
              setState(() => map[k] = v);
            }
            Navigator.pop(context);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        name: _nameController.text,
        endpoint: _endpointController.text,
        method: _methodController.text,
        authType: 'None',
        headers: _headers,
        queryParams: _queryParams,
        bodyTemplate: _bodyTemplateController.text,
        responseMapping: _mapping,
      );

      if (widget.preset != null) {
        widget.preset!.name = newPreset.name;
        widget.preset!.endpoint = newPreset.endpoint;
        widget.preset!.method = newPreset.method;
        widget.preset!.authType = newPreset.authType;
        widget.preset!.headers = newPreset.headers;
        widget.preset!.queryParams = newPreset.queryParams;
        widget.preset!.bodyTemplate = newPreset.bodyTemplate;
        widget.preset!.responseMapping = newPreset.responseMapping;
        widget.preset!.save();
      } else {
        ref.read(settingsProvider.notifier).savePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }
}
