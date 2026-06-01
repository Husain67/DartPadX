import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/preset_model.dart';
import '../providers/compiler_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);
    final isDefaultMode = compilerState.useDefaultCompiler;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Settings'),
        actions: [
           IconButton(
             icon: const Icon(Icons.add),
             onPressed: () => _showPresetDialog(context, ref, null),
           )
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler (Recommended)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Provides highly stable Dart 3 execution.'),
            value: isDefaultMode,
            activeTrackColor: AppTheme.primaryAccent.withValues(alpha: 0.5),
            // ignore: deprecated_member_use
            activeColor: AppTheme.primaryAccent,
            onChanged: (val) => ref.read(compilerProvider.notifier).toggleUseDefault(val),
          ),
          const Divider(),
          if (!isDefaultMode) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Custom Compiler Presets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: compilerState.presets.length,
                itemBuilder: (ctx, i) {
                  final preset = compilerState.presets[i];
                  final isSelected = compilerState.activePreset?.id == preset.id;

                  return ListTile(
                    leading: Radio<String>(
                      value: preset.id,
                      // ignore: deprecated_member_use
                      groupValue: compilerState.activePreset?.id,
                      // ignore: deprecated_member_use
                      onChanged: (val) {
                         ref.read(compilerProvider.notifier).setActivePreset(preset);
                      },
                      // ignore: deprecated_member_use
            activeColor: AppTheme.primaryAccent,
                    ),
                    title: Text(preset.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showPresetDialog(context, ref, preset),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                             final dup = PresetModel(
                                name: '${preset.name} Copy',
                                endpointUrl: preset.endpointUrl,
                                httpMethod: preset.httpMethod,
                                authType: preset.authType,
                                headers: Map.from(preset.headers),
                                queryParams: Map.from(preset.queryParams),
                                requestBodyTemplate: preset.requestBodyTemplate,
                                stdoutPath: preset.stdoutPath,
                                stderrPath: preset.stderrPath,
                                errorPath: preset.errorPath,
                                executionTimePath: preset.executionTimePath,
                                memoryPath: preset.memoryPath,
                                isDefault: false,
                             );
                             ref.read(compilerProvider.notifier).addOrUpdatePreset(dup);
                          },
                        ),
                        if (!preset.isDefault)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, ref, preset),
                          ),
                      ],
                    ),
                    onTap: () {
                      ref.read(compilerProvider.notifier).setActivePreset(preset);
                    },
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PresetModel preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Preset?'),
        content: Text('Are you sure you want to delete "${preset.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(compilerProvider.notifier).deletePreset(preset.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPresetDialog(BuildContext context, WidgetRef ref, PresetModel? existing) {
    showDialog(
      context: context,

      builder: (ctx) => PresetEditorDialog(preset: existing),
    ).then((updated) {
       if (updated != null && updated is PresetModel) {
          ref.read(compilerProvider.notifier).addOrUpdatePreset(updated);
       }
    });
  }
}

class PresetEditorDialog extends StatefulWidget {
  final PresetModel? preset;
  const PresetEditorDialog({super.key, this.preset});

  @override
  State<PresetEditorDialog> createState() => _PresetEditorDialogState();
}

class _PresetEditorDialogState extends State<PresetEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _endpointUrl;
  late String _httpMethod;
  late String _authType;
  late String _requestBodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _name = p?.name ?? '';
    _endpointUrl = p?.endpointUrl ?? '';
    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _requestBodyTemplate = p?.requestBodyTemplate ?? '{\n  "code": "{code}",\n  "stdin": "{stdin}"\n}';
    _stdoutPath = p?.stdoutPath ?? 'stdout';
    _stderrPath = p?.stderrPath ?? 'stderr';
    _errorPath = p?.errorPath ?? 'error';
    _executionTimePath = p?.executionTimePath ?? '';
    _memoryPath = p?.memoryPath ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: _name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        onSaved: (v) => _name = v!,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _endpointUrl,
                        decoration: const InputDecoration(labelText: 'Endpoint URL'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        onSaved: (v) => _endpointUrl = v!,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _httpMethod,
                        decoration: const InputDecoration(labelText: 'HTTP Method'),
                        items: ['GET', 'POST', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _httpMethod = v!),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _authType,
                        decoration: const InputDecoration(labelText: 'Auth Type'),
                        items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _authType = v!),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _requestBodyTemplate,
                        decoration: const InputDecoration(labelText: 'JSON Request Body Template', hintText: 'Use {code} and {stdin}'),
                        maxLines: 5,
                        onSaved: (v) => _requestBodyTemplate = v!,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _stdoutPath,
                        decoration: const InputDecoration(labelText: 'Stdout JSON Path'),
                        onSaved: (v) => _stdoutPath = v!,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _stderrPath,
                        decoration: const InputDecoration(labelText: 'Stderr JSON Path'),
                        onSaved: (v) => _stderrPath = v!,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                   ElevatedButton(
                     onPressed: () {
                       if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          final p = PresetModel(
                            id: widget.preset?.id,
                            name: _name,
                            endpointUrl: _endpointUrl,
                            httpMethod: _httpMethod,
                            authType: _authType,
                            headers: widget.preset?.headers ?? {},
                            queryParams: widget.preset?.queryParams ?? {},
                            requestBodyTemplate: _requestBodyTemplate,
                            stdoutPath: _stdoutPath,
                            stderrPath: _stderrPath,
                            errorPath: _errorPath,
                            executionTimePath: _executionTimePath,
                            memoryPath: _memoryPath,
                            isDefault: widget.preset?.isDefault ?? false,
                          );
                          Navigator.pop(context, p);
                       }
                     },
                     child: const Text('Save'),
                   ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
