import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import '../core/theme.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Compilers'),
      ),
      body: Container(
        decoration: DartMiniTheme.backgroundGradient,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                indicatorColor: DartMiniTheme.primaryAccent,
                labelColor: DartMiniTheme.primaryAccent,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'General'),
                  Tab(text: 'Compiler Presets'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildGeneralTab(ref),
                    _buildCompilersTab(ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Switch between OneCompiler and Custom Presets'),
          value: compilerState.useDefaultCompiler,
          // ignore: deprecated_member_use
          activeColor: DartMiniTheme.primaryAccent,
          onChanged: (val) {
            ref.read(compilerProvider.notifier).setUseDefaultCompiler(val);
          },
        ),
      ],
    );
  }

  Widget _buildCompilersTab(WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showPresetDialog(context, ref, null),
                icon: const Icon(Icons.add),
                label: const Text('Add New Preset'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: state.presets.length,
                itemBuilder: (context, index) {
                  final preset = state.presets[index];
                  final isActive = state.activePresetId == preset.id;

                  return Card(
                    color: DartMiniTheme.surfaceColor,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isActive ? DartMiniTheme.primaryAccent : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white54),
                            onPressed: () => _showPresetDialog(context, ref, preset),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.blueAccent),
                            onPressed: () {
                              final newPreset = preset.copyWith(
                                id: const Uuid().v4(),
                                name: '${preset.name} (Copy)'
                              );
                              ref.read(compilerProvider.notifier).addPreset(newPreset);
                              Fluttertoast.showToast(msg: 'Preset Duplicated');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              ref.read(compilerProvider.notifier).deletePreset(preset.id);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                        ref.read(compilerProvider.notifier).setUseDefaultCompiler(false);
                        Fluttertoast.showToast(msg: 'Selected ${preset.name}');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
    );
  }

  void _showPresetDialog(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
    showDialog(
      context: context,
      builder: (ctx) => _PresetEditDialog(preset: preset),
    );
  }
}

class _PresetEditDialog extends ConsumerStatefulWidget {
  final CompilerPreset? preset;

  const _PresetEditDialog({this.preset});

  @override
  ConsumerState<_PresetEditDialog> createState() => _PresetEditDialogState();
}

class _PresetEditDialogState extends ConsumerState<_PresetEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _bodyController;
  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;
  String _method = 'POST';
  String _authType = 'None';
  final List<MapEntry<String, String>> _headers = [];
  final List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _urlController = TextEditingController(text: widget.preset?.endpointUrl ?? '');
    _bodyController = TextEditingController(text: widget.preset?.requestBodyTemplate ?? '{}');
    _stdoutController = TextEditingController(text: widget.preset?.responseStdoutPath ?? '');
    _stderrController = TextEditingController(text: widget.preset?.responseStderrPath ?? '');
    _errorController = TextEditingController(text: widget.preset?.responseErrorPath ?? '');
    _timeController = TextEditingController(text: widget.preset?.responseExecutionTimePath ?? '');
    _memoryController = TextEditingController(text: widget.preset?.responseMemoryPath ?? '');
    _method = widget.preset?.httpMethod ?? 'POST';
    _authType = widget.preset?.authType ?? 'None';
    if (widget.preset != null) {
      _headers.addAll(widget.preset!.headers.entries);
      _queryParams.addAll(widget.preset!.queryParams.entries);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Platform Name'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(labelText: 'Endpoint URL'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _urlController.text));
                      Fluttertoast.showToast(msg: 'Copied URL');
                    },
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _method,
                      items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _method = val!),
                      decoration: const InputDecoration(labelText: 'HTTP Method'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _authType,
                      items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _authType = val!),
                      decoration: const InputDecoration(labelText: 'Auth Type'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._headers.asMap().entries.map((e) => _buildKeyValueRow(e.key, _headers, e.value)),
              TextButton.icon(onPressed: () => setState(() => _headers.add(const MapEntry('', ''))), icon: const Icon(Icons.add), label: const Text('Add Header')),
              const SizedBox(height: 16),
              const Text('Query Params', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._queryParams.asMap().entries.map((e) => _buildKeyValueRow(e.key, _queryParams, e.value)),
              TextButton.icon(onPressed: () => setState(() => _queryParams.add(const MapEntry('', ''))), icon: const Icon(Icons.add), label: const Text('Add Param')),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Request Body Template', helperText: 'Use {code}, {stdin}, {language}'),
              ),
              const SizedBox(height: 16),
              const Text('Response Mapping (dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: _stdoutController, decoration: const InputDecoration(labelText: 'stdout path')),
              TextField(controller: _stderrController, decoration: const InputDecoration(labelText: 'stderr path')),
              TextField(controller: _errorController, decoration: const InputDecoration(labelText: 'error path')),
              TextField(controller: _timeController, decoration: const InputDecoration(labelText: 'executionTime path')),
              TextField(controller: _memoryController, decoration: const InputDecoration(labelText: 'memory path')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Fluttertoast.showToast(msg: 'Test Connection would execute print("Hello") here.');
                    },
                    child: const Text('Test Connection', style: TextStyle(color: Colors.blueAccent)),
                  ),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          final newPreset = CompilerPreset(
                            id: widget.preset?.id ?? const Uuid().v4(),
                            name: _nameController.text,
                            endpointUrl: _urlController.text,
                            httpMethod: _method,
                            authType: _authType,
                            headers: Map.fromEntries(_headers.where((e) => e.key.isNotEmpty)),
                            queryParams: Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty)),
                            requestBodyTemplate: _bodyController.text,
                            responseStdoutPath: _stdoutController.text,
                            responseStderrPath: _stderrController.text,
                            responseErrorPath: _errorController.text,
                            responseExecutionTimePath: _timeController.text,
                            responseMemoryPath: _memoryController.text,
                          );

                          if (widget.preset == null) {
                            ref.read(compilerProvider.notifier).addPreset(newPreset);
                          } else {
                            ref.read(compilerProvider.notifier).updatePreset(newPreset);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      )
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyValueRow(int index, List<MapEntry<String, String>> list, MapEntry<String, String> entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: TextFormField(
            initialValue: entry.key,
            onChanged: (val) => setState(() => list[index] = MapEntry(val, entry.value)),
            decoration: const InputDecoration(labelText: 'Key', isDense: true),
          )),
          const SizedBox(width: 8),
          Expanded(child: TextFormField(
            initialValue: entry.value,
            onChanged: (val) => setState(() => list[index] = MapEntry(entry.key, val)),
            decoration: const InputDecoration(labelText: 'Value', isDense: true),
          )),
          IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: () => setState(() => list.removeAt(index)))
        ],
      ),
    );
  }
}
