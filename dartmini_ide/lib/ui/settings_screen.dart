import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(compilerSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Settings'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Bypass custom presets and use built-in configuration.'),
            value: settingsState.useDefaultOneCompiler,
            activeColor: const Color(0xFFFACC15), // ignore: deprecated_member_use
            onChanged: (val) {
              ref.read(compilerSettingsProvider.notifier).toggleUseDefault(val);
            },
          ),
          ListTile(
            title: const Text('Export Presets'),
            leading: const Icon(Icons.file_upload),
            onTap: () {
              ref.read(compilerSettingsProvider.notifier).exportPresets();
            },
          ),
          ListTile(
            title: const Text('Import Presets'),
            leading: const Icon(Icons.file_download),
            onTap: () {
              ref.read(compilerSettingsProvider.notifier).importPresets();
            },
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: settingsState.presets.length,
              itemBuilder: (context, index) {
                final preset = settingsState.presets[index];
                final isSelected = preset.id == settingsState.activePresetId && !settingsState.useDefaultOneCompiler;
                return ListTile(
                  title: Text(preset.name),
                  subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openPresetEditor(context, preset, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ref.read(compilerSettingsProvider.notifier).deletePreset(index);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                     ref.read(compilerSettingsProvider.notifier).setActivePreset(preset.id);
                     if (settingsState.useDefaultOneCompiler) {
                        ref.read(compilerSettingsProvider.notifier).toggleUseDefault(false);
                     }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFACC15),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _openPresetEditor(context, null, null),
      ),
    );
  }

  void _openPresetEditor(BuildContext context, CompilerPreset? preset, int? index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresetEditorScreen(preset: preset, index: index),
      ),
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  final int? index;
  const PresetEditorScreen({super.key, this.preset, this.index});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _url;
  late String _method;
  late String _bodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;

  @override
  void initState() {
    super.initState();
    _name = widget.preset?.name ?? '';
    _url = widget.preset?.url ?? '';
    _method = widget.preset?.method ?? 'POST';
    _bodyTemplate = widget.preset?.bodyTemplate ?? '{"code": "{code}"}';
    _stdoutPath = widget.preset?.stdoutPath ?? 'stdout';
    _stderrPath = widget.preset?.stderrPath ?? 'stderr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final newPreset = CompilerPreset(
                  id: widget.preset?.id ?? const Uuid().v4(),
                  name: _name,
                  url: _url,
                  method: _method,
                  authType: widget.preset?.authType ?? 'None',
                  headers: widget.preset?.headers ?? {},
                  queryParams: widget.preset?.queryParams ?? {},
                  bodyTemplate: _bodyTemplate,
                  stdoutPath: _stdoutPath,
                  stderrPath: _stderrPath,
                  errorPath: widget.preset?.errorPath ?? '',
                  executionTimePath: widget.preset?.executionTimePath ?? '',
                  memoryPath: widget.preset?.memoryPath ?? '',
                );

                if (widget.index != null) {
                  ref.read(compilerSettingsProvider.notifier).updatePreset(widget.index!, newPreset);
                } else {
                  ref.read(compilerSettingsProvider.notifier).addPreset(newPreset);
                }
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _url,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _url = v!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _method = v!),
              onSaved: (v) => _method = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _bodyTemplate,
              decoration: const InputDecoration(
                labelText: 'Request Body Template (JSON)',
                helperText: 'Use placeholders: {code}, {stdin}, {language}',
              ),
              maxLines: 5,
              onSaved: (v) => _bodyTemplate = v!,
            ),
            const SizedBox(height: 16),
            const Text('Response Mapping', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: _stdoutPath,
              decoration: const InputDecoration(labelText: 'Stdout Path (e.g., data.output)'),
              onSaved: (v) => _stdoutPath = v!,
            ),
            TextFormField(
              initialValue: _stderrPath,
              decoration: const InputDecoration(labelText: 'Stderr Path'),
              onSaved: (v) => _stderrPath = v!,
            ),
          ],
        ),
      ),
    );
  }
}
