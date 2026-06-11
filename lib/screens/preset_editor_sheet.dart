import 'test_connection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';


// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

class PresetEditorSheet extends ConsumerStatefulWidget {
  final CompilerPreset? preset; // Null means create new
  const PresetEditorSheet({super.key, this.preset});

  @override
  ConsumerState<PresetEditorSheet> createState() => _PresetEditorSheetState();
}

class _PresetEditorSheetState extends ConsumerState<PresetEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _endpointCtrl;
  late TextEditingController _methodCtrl;
  late TextEditingController _authTypeCtrl;
  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errorPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memoryPathCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _endpointCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _methodCtrl = TextEditingController(text: p?.httpMethod ?? 'POST');
    _authTypeCtrl = TextEditingController(text: p?.authType ?? 'None');
    _bodyTemplateCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{"code": "{code}"}');
    _stdoutPathCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrPathCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorPathCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timePathCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryPathCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _endpointCtrl.dispose();
    _methodCtrl.dispose();
    _authTypeCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errorPathCtrl.dispose();
    _timePathCtrl.dispose();
    _memoryPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? '', // handled in provider if empty
        name: _nameCtrl.text,
        endpointUrl: _endpointCtrl.text,
        httpMethod: _methodCtrl.text,
        authType: _authTypeCtrl.text,
        headers: Map.fromEntries(_headers.where((e) => e.key.isNotEmpty)),
        queryParams: Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty)),
        requestBodyTemplate: _bodyTemplateCtrl.text,
        stdoutPath: _stdoutPathCtrl.text,
        stderrPath: _stderrPathCtrl.text,
        errorPath: _errorPathCtrl.text,
        executionTimePath: _timePathCtrl.text,
        memoryPath: _memoryPathCtrl.text,
      );

      if (widget.preset == null) {
        ref.read(compilerProvider.notifier).addPreset(newPreset);
      } else {
        ref.read(compilerProvider.notifier).updatePreset(newPreset);
      }
      Navigator.pop(context);
    }
  }

  Widget _buildKeyValueList(String title, List<MapEntry<String, String>> list, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            IconButton(icon: Icon(Icons.add, color: AppTheme.primaryYellow), onPressed: onAdd),
          ],
        ),
        ...list.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          return Padding(
            key: ValueKey('${title}_$idx'),
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: entry.key,
                    decoration: InputDecoration(hintText: 'Key', isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      list[idx] = MapEntry(val, entry.value);
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.value,
                    decoration: InputDecoration(hintText: 'Value', isDense: true, border: OutlineInputBorder()),
                    onChanged: (val) {
                      list[idx] = MapEntry(entry.key, val);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      list.removeAt(idx);
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
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.preset == null ? 'Add Preset' : 'Edit Preset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        if (widget.preset != null && widget.preset!.name != 'OneCompiler') // Prevent deleting default
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              ref.read(compilerProvider.notifier).deletePreset(widget.preset!.id);
                              Navigator.pop(context);
                            },
                          ),
                        IconButton(
                          icon: Icon(Icons.play_circle_fill, color: Colors.greenAccent),
                          tooltip: 'Test Connection',
                          onPressed: () {
                             if (_formKey.currentState!.validate()) {
                               final tempPreset = CompilerPreset(
                                  id: widget.preset?.id ?? '',
                                  name: _nameCtrl.text,
                                  endpointUrl: _endpointCtrl.text,
                                  httpMethod: _methodCtrl.text,
                                  authType: _authTypeCtrl.text,
                                  headers: Map.fromEntries(_headers.where((e) => e.key.isNotEmpty)),
                                  queryParams: Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty)),
                                  requestBodyTemplate: _bodyTemplateCtrl.text,
                                  stdoutPath: _stdoutPathCtrl.text,
                                  stderrPath: _stderrPathCtrl.text,
                                  errorPath: _errorPathCtrl.text,
                                  executionTimePath: _timePathCtrl.text,
                                  memoryPath: _memoryPathCtrl.text,
                               );

                               showDialog(
                                 context: context,
                                 builder: (ctx) => TestConnectionDialog(preset: tempPreset),
                               );
                             }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.save, color: AppTheme.primaryYellow),
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(labelText: 'Platform Name', border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _endpointCtrl,
                        decoration: InputDecoration(labelText: 'Endpoint URL', border: OutlineInputBorder()),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _methodCtrl,
                              decoration: InputDecoration(labelText: 'HTTP Method', border: OutlineInputBorder()),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _authTypeCtrl,
                              decoration: InputDecoration(labelText: 'Auth Type', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      _buildKeyValueList('Headers', _headers, () => setState(() => _headers.add(MapEntry('', '')))),
                      SizedBox(height: 16),
                      _buildKeyValueList('Query Params', _queryParams, () => setState(() => _queryParams.add(MapEntry('', '')))),
                      SizedBox(height: 24),
                      Text('Request Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _bodyTemplateCtrl,
                        maxLines: 5,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Use {code} and {stdin} placeholders',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 8),
                      TextFormField(controller: _stdoutPathCtrl, decoration: InputDecoration(labelText: 'Stdout Path', isDense: true, border: OutlineInputBorder())),
                      SizedBox(height: 8),
                      TextFormField(controller: _stderrPathCtrl, decoration: InputDecoration(labelText: 'Stderr Path', isDense: true, border: OutlineInputBorder())),
                      SizedBox(height: 8),
                      TextFormField(controller: _errorPathCtrl, decoration: InputDecoration(labelText: 'Error Path', isDense: true, border: OutlineInputBorder())),
                      SizedBox(height: 8),
                      TextFormField(controller: _timePathCtrl, decoration: InputDecoration(labelText: 'Execution Time Path', isDense: true, border: OutlineInputBorder())),
                      SizedBox(height: 8),
                      TextFormField(controller: _memoryPathCtrl, decoration: InputDecoration(labelText: 'Memory Path', isDense: true, border: OutlineInputBorder())),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
