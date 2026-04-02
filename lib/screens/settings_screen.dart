import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _exportPresets() async {
    final jsonStr = ref.read(compilerProvider.notifier).exportPresetsToJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    Fluttertoast.showToast(msg: 'Exported JSON copied to clipboard');
  }

  void _importPresets() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      try {
        ref.read(compilerProvider.notifier).importPresetsFromJson(data.text!);
        Fluttertoast.showToast(msg: 'Presets imported successfully');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Invalid JSON format');
      }
    } else {
      Fluttertoast.showToast(msg: 'Clipboard is empty');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Settings'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'export') _exportPresets();
              if (val == 'import') _importPresets();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export Presets (Copy JSON)')),
              const PopupMenuItem(value: 'import', child: Text('Import Presets (Paste JSON)')),
            ],
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler API'),
            subtitle: const Text('Toggle off to use Custom API Preset'),
            value: state.useDefaultOneCompiler,
            onChanged: (val) {
              ref.read(compilerProvider.notifier).setUseDefault(val);
            },
            activeTrackColor: AppColors.primaryAccent.withValues(alpha: 0.5),
            activeColor: AppColors.primaryAccent,
          ),
          const Divider(),
          const Text('Custom Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...state.presets.map((preset) {
            final isActive = preset.id == state.activePresetId && !state.useDefaultOneCompiler;
            return Card(
              color: isActive ? AppColors.surface.withValues(alpha: 0.8) : AppColors.backgroundStart,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isActive ? AppColors.primaryAccent : Colors.white10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(preset.name),
                subtitle: Text(preset.endpoint, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        final copy = CompilerPreset.fromJson(preset.toJson());
                        copy.id = const Uuid().v4();
                        copy.name = '${preset.name} (Copy)';
                        ref.read(compilerProvider.notifier).addPreset(copy);
                        Fluttertoast.showToast(msg: 'Preset Duplicated');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editPreset(context, ref, preset),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                      onPressed: () {
                         ref.read(compilerProvider.notifier).deletePreset(preset.id);
                      },
                    )
                  ],
                ),
                onTap: () {
                  ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  ref.read(compilerProvider.notifier).setUseDefault(false);
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
               final newP = CompilerPreset(id: const Uuid().v4(), name: 'New Preset', endpoint: 'https://');
               ref.read(compilerProvider.notifier).addPreset(newP);
               _editPreset(context, ref, newP);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Preset'),
          )
        ],
      ),
    );
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditPresetScreen(preset: preset)));
  }
}


class EditPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  const EditPresetScreen({super.key, required this.preset});

  @override
  ConsumerState<EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<EditPresetScreen> {
  late CompilerPreset _p;

  @override
  void initState() {
    super.initState();
    // clone to edit locally
    _p = CompilerPreset.fromJson(widget.preset.toJson());
  }

  void _save() {
    ref.read(compilerProvider.notifier).updatePreset(_p);
    Navigator.pop(context);
    Fluttertoast.showToast(msg: 'Saved Preset');
  }

  void _testConnection() async {
    ref.read(compilerProvider.notifier).updatePreset(_p); // save temp
    ref.read(compilerProvider.notifier).setActivePreset(_p.id);
    ref.read(compilerProvider.notifier).setUseDefault(false);

    Fluttertoast.showToast(msg: 'Testing connection...');
    await ref.read(compilerProvider.notifier).executeCode("void main() { print('Hello from custom API'); }");

    final state = ref.read(compilerProvider);
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Test Connection Result'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Parsed Stdout:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(state.stdout, style: const TextStyle(color: AppColors.success)),
                const SizedBox(height: 8),
                const Text('Parsed Stderr:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(state.stderr, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 8),
                Text('Time: ${state.executionTime} | Mem: ${state.memory}'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             TextFormField(
              initialValue: _p.name,
              decoration: const InputDecoration(labelText: 'Platform Name'),
              onChanged: (val) => _p.name = val,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _p.endpoint,
              decoration: const InputDecoration(labelText: 'Endpoint URL'),
              onChanged: (val) => _p.endpoint = val,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _p.method,
              decoration: const InputDecoration(labelText: 'HTTP Method'),
              items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _p.method = val!),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _p.authType,
              decoration: const InputDecoration(labelText: 'Auth Type'),
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _p.authType = val!),
            ),
            if (_p.authType != 'None') ...[
               if (_p.authType != 'Bearer Token' && _p.authType != 'Basic Auth')
                  TextFormField(
                    initialValue: _p.authKey,
                    decoration: const InputDecoration(labelText: 'Auth Key (e.g. X-API-Key)'),
                    onChanged: (val) => _p.authKey = val,
                  ),
               TextFormField(
                  initialValue: _p.authValue,
                  decoration: const InputDecoration(labelText: 'Auth Value / Token'),
                  onChanged: (val) => _p.authValue = val,
               ),
            ],

            // Dynamic Headers
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dynamic Headers', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => setState(() => _p.headers['New_Header'] = 'Value'),
                )
              ],
            ),
            ..._p.headers.keys.toList().map((k) {
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: k,
                      decoration: const InputDecoration(hintText: 'Key'),
                      onChanged: (val) {
                        final v = _p.headers.remove(k);
                        if (v != null) _p.headers[val] = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: _p.headers[k],
                      decoration: const InputDecoration(hintText: 'Value'),
                      onChanged: (val) => _p.headers[k] = val,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error),
                    onPressed: () => setState(() => _p.headers.remove(k)),
                  )
                ],
              );
            }),

            // Dynamic Query Params
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => setState(() => _p.queryParams['New_Param'] = 'Value'),
                )
              ],
            ),
            ..._p.queryParams.keys.toList().map((k) {
              return Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: k,
                      decoration: const InputDecoration(hintText: 'Key'),
                      onChanged: (val) {
                        final v = _p.queryParams.remove(k);
                        if (v != null) _p.queryParams[val] = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: _p.queryParams[k],
                      decoration: const InputDecoration(hintText: 'Value'),
                      onChanged: (val) => _p.queryParams[k] = val,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error),
                    onPressed: () => setState(() => _p.queryParams.remove(k)),
                  )
                ],
              );
            }),

            const Divider(height: 32),
            const Text('Request Body Template JSON', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('{code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _p.bodyTemplate,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (val) => _p.bodyTemplate = val,
            ),
            const Divider(height: 32),
            const Text('Response Mapping (Dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: _p.stdoutPath,
              decoration: const InputDecoration(labelText: 'stdout path (e.g. run.stdout)'),
              onChanged: (val) => _p.stdoutPath = val,
            ),
            TextFormField(
              initialValue: _p.stderrPath,
              decoration: const InputDecoration(labelText: 'stderr path'),
              onChanged: (val) => _p.stderrPath = val,
            ),
            TextFormField(
              initialValue: _p.errorPath,
              decoration: const InputDecoration(labelText: 'error path'),
              onChanged: (val) => _p.errorPath = val,
            ),
            TextFormField(
              initialValue: _p.executionTimePath,
              decoration: const InputDecoration(labelText: 'executionTime path'),
              onChanged: (val) => _p.executionTimePath = val,
            ),
            TextFormField(
              initialValue: _p.memoryPath,
              decoration: const InputDecoration(labelText: 'memory path'),
              onChanged: (val) => _p.memoryPath = val,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.network_check),
              label: const Text('Test Connection'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
