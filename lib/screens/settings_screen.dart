import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Presets',
            onPressed: () async {
              final presets = ref.read(settingsProvider).presets;
              final jsonStr = jsonEncode(presets.map((p) => p.toMap()).toList());
              // Normally write to file, here just copy to clipboard for simplicity or save
              Clipboard.setData(ClipboardData(text: jsonStr));
              Fluttertoast.showToast(msg: "Exported to Clipboard");
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import Presets',
            onPressed: () async {
              final data = await Clipboard.getData('text/plain');
              if (data?.text != null) {
                try {
                  final List list = jsonDecode(data!.text!);
                  for (var map in list) {
                    final p = CompilerPreset.fromMap(map);
                    ref.read(settingsProvider.notifier).addPreset(p.copyWith(id: const Uuid().v4(), isReadOnly: false));
                  }
                  Fluttertoast.showToast(msg: "Imported Presets");
                } catch (e) {
                  Fluttertoast.showToast(msg: "Invalid JSON format");
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Bypass custom presets and use standard API'),
            value: settings.useDefaultOneCompiler,
            activeTrackColor: Theme.of(context).primaryColor,
            activeThumbColor: Colors.black,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleDefaultOneCompiler(val);
            },
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compiler Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
                onPressed: () => _showEditPresetDialog(null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...settings.presets.map((preset) => _buildPresetCard(preset, settings.activePresetId == preset.id)),
        ],
      ),
    );
  }

  Widget _buildPresetCard(CompilerPreset preset, bool isActive) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isActive ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('\${preset.method} \${preset.endpoint}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Set Active',
                onPressed: () {
                  ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                  if (ref.read(settingsProvider).useDefaultOneCompiler) {
                    ref.read(settingsProvider.notifier).toggleDefaultOneCompiler(false);
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditPresetDialog(preset),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Duplicate',
              onPressed: () => ref.read(settingsProvider.notifier).duplicatePreset(preset),
            ),
            if (!preset.isReadOnly)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(preset),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(CompilerPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: Text('Are you sure you want to delete "\${preset.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).deletePreset(preset.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditPresetDialog(CompilerPreset? preset) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditPresetScreen(preset: preset)),
    );
  }
}

class EditPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const EditPresetScreen({super.key, this.preset});

  @override
  ConsumerState<EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<EditPresetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _endpointController;
  late TextEditingController _bodyController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;

  String _method = 'POST';

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameController = TextEditingController(text: p?.name ?? '');
    _endpointController = TextEditingController(text: p?.endpoint ?? '');
    _bodyController = TextEditingController(text: p?.bodyTemplate ?? '{"code": "{code}", "stdin": "{stdin}"}');
    _stdoutController = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrController = TextEditingController(text: p?.stderrPath ?? '');
    _errorController = TextEditingController(text: p?.errorPath ?? '');
    _timeController = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryController = TextEditingController(text: p?.memoryPath ?? '');
    _method = p?.method ?? 'POST';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _bodyController.dispose();
    _stdoutController.dispose();
    _stderrController.dispose();
    _errorController.dispose();
    _timeController.dispose();
    _memoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? const Uuid().v4(),
        name: _nameController.text,
        endpoint: _endpointController.text,
        method: _method,
        bodyTemplate: _bodyController.text,
        stdoutPath: _stdoutController.text,
        stderrPath: _stderrController.text,
        errorPath: _errorController.text,
        executionTimePath: _timeController.text,
        memoryPath: _memoryController.text,
        isReadOnly: widget.preset?.isReadOnly ?? false,
        headers: widget.preset?.headers ?? {'Content-Type': 'application/json'},
      );

      if (widget.preset == null) {
        ref.read(settingsProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(settingsProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.preset?.isReadOnly ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          if (!isReadOnly)
            IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: isReadOnly
          ? const Center(child: Text('This preset is read-only (Built-in)'))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Platform Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _endpointController,
                    decoration: const InputDecoration(labelText: 'Endpoint URL'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _method,
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                  const SizedBox(height: 20),
                  const Text('JSON Body Template', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('Use {code} and {stdin} placeholders. Wrap {code} in quotes.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 4,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  const Text('Response Mapping (Dot notation e.g., data.run.stdout)', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'stdout path')),
                  TextFormField(controller: _stderrController, decoration: const InputDecoration(labelText: 'stderr path')),
                  TextFormField(controller: _errorController, decoration: const InputDecoration(labelText: 'error path')),
                  TextFormField(controller: _timeController, decoration: const InputDecoration(labelText: 'execution time path')),
                  TextFormField(controller: _memoryController, decoration: const InputDecoration(labelText: 'memory path')),
                ],
              ),
            ),
    );
  }
}
