import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';

import '../core/theme.dart';
import '../models/compiler_preset.dart';
import 'package:flutter/services.dart';

import '../providers/settings_provider.dart';
import '../providers/execution_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentYellow,
          labelColor: AppTheme.accentYellow,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Custom Compilers'),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildCustomCompilersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Turn off to use a custom compiler preset', style: TextStyle(color: Colors.white54)),
          value: settings.useDefaultOneCompiler,
          activeTrackColor: AppTheme.accentYellow,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).toggleUseDefault(val);
          },
        ),
        const Divider(color: Colors.white24),
        ListTile(
          leading: const Icon(Icons.download, color: AppTheme.accentYellow),
          title: const Text('Export Presets', style: TextStyle(color: Colors.white)),
          onTap: () async {
            final presets = settings.presets.map((p) => p.toJson()).toList();
            final jsonStr = jsonEncode(presets);
            final dir = await getApplicationDocumentsDirectory();
            // ignore: unused_local_variable
            final file = File('${dir.path}/compiler_presets.json');
            await file.writeAsString(jsonStr);
            await Share.shareXFiles([XFile(file.path)], text: 'Exported Presets');
          },
        ),
        ListTile(
          leading: const Icon(Icons.upload, color: AppTheme.accentYellow),
          title: const Text('Import Presets', style: TextStyle(color: Colors.white)),
          onTap: () async {
            try {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
              );

              if (result != null && result.files.single.path != null) {
                File file = File(result.files.single.path!);
                String content = await file.readAsString();
                List<dynamic> parsed = jsonDecode(content);
                List<CompilerPreset> imported = parsed.map((e) => CompilerPreset.fromJson(e)).toList();
                ref.read(settingsProvider.notifier).importPresets(imported);
                Fluttertoast.showToast(msg: 'Presets imported successfully');
              }
            } catch (e) {
              Fluttertoast.showToast(msg: 'Failed to import presets: Invalid JSON');
            }
          },
        ),
      ],
    );
  }

  Widget _buildCustomCompilersTab() {
    final settings = ref.watch(settingsProvider);
    final presets = settings.presets;

    return Column(
      children: [
        if (settings.useDefaultOneCompiler)
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.errorRed.withOpacity(0.2),
            child: const Row(
              children: [
                Icon(Icons.warning, color: AppTheme.errorRed),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom compilers are disabled. Turn off "Use Default OneCompiler API" in General settings to enable them.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PresetEditorScreen(
                    preset: CompilerPreset(
                      id: const Uuid().v4(),
                      platformName: 'New Preset',
                      endpointUrl: 'https://',
                      httpMethod: 'POST',
                      authType: 'None',
                      authValue: '',
                      dynamicHeaders: {'Content-Type': 'application/json'},
                      dynamicQueryParams: {},
                      requestBodyTemplate: '{"code": "{code}"}',
                      stdoutPath: '',
                      stderrPath: '',
                      errorPath: '',
                      executionTimePath: '',
                      memoryPath: '',
                    ),
                    isNew: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Preset'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isSelected = preset.id == settings.selectedPresetId && !settings.useDefaultOneCompiler;

              return Card(
                color: isSelected ? Colors.white12 : Colors.transparent,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isSelected ? AppTheme.accentYellow : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(preset.platformName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                        onPressed: () {
                          ref.read(settingsProvider.notifier).duplicatePreset(preset.id);
                          Fluttertoast.showToast(msg: 'Preset duplicated');
                        },
                        tooltip: 'Duplicate',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PresetEditorScreen(preset: preset, isNew: false),
                            ),
                          );
                        },
                        tooltip: 'Edit',
                      ),
                      if (presets.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.errorRed, size: 20),
                          onPressed: () {
                            ref.read(settingsProvider.notifier).deletePreset(preset.id);
                          },
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                  onTap: () {
                    if (!settings.useDefaultOneCompiler) {
                      ref.read(settingsProvider.notifier).selectPreset(preset.id);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  final bool isNew;

  const PresetEditorScreen({super.key, required this.preset, required this.isNew});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  late String _method;
  late String _authType;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;

  late TextEditingController _stdoutPathCtrl;
  late TextEditingController _stderrPathCtrl;
  late TextEditingController _errPathCtrl;
  late TextEditingController _timePathCtrl;
  late TextEditingController _memPathCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _params = [];

  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.preset.platformName);
    _urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    _method = widget.preset.httpMethod;
    _authType = widget.preset.authType;
    _authValueCtrl = TextEditingController(text: widget.preset.authValue);
    _bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);

    _stdoutPathCtrl = TextEditingController(text: widget.preset.stdoutPath);
    _stderrPathCtrl = TextEditingController(text: widget.preset.stderrPath);
    _errPathCtrl = TextEditingController(text: widget.preset.errorPath);
    _timePathCtrl = TextEditingController(text: widget.preset.executionTimePath);
    _memPathCtrl = TextEditingController(text: widget.preset.memoryPath);

    _headers = widget.preset.dynamicHeaders.entries.toList();
    _params = widget.preset.dynamicQueryParams.entries.toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyCtrl.dispose();
    _stdoutPathCtrl.dispose();
    _stderrPathCtrl.dispose();
    _errPathCtrl.dispose();
    _timePathCtrl.dispose();
    _memPathCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updatedPreset = widget.preset.copyWith(
      platformName: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memPathCtrl.text,
      dynamicHeaders: Map.fromEntries(_headers),
      dynamicQueryParams: Map.fromEntries(_params),
    );

    if (widget.isNew) {
      ref.read(settingsProvider.notifier).addPreset(updatedPreset);
    } else {
      ref.read(settingsProvider.notifier).updatePreset(updatedPreset);
    }

    Navigator.pop(context);
    Fluttertoast.showToast(msg: 'Preset saved');
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    final testPreset = widget.preset.copyWith(
      platformName: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authValue: _authValueCtrl.text,
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutPathCtrl.text,
      stderrPath: _stderrPathCtrl.text,
      errorPath: _errPathCtrl.text,
      executionTimePath: _timePathCtrl.text,
      memoryPath: _memPathCtrl.text,
      dynamicHeaders: Map.fromEntries(_headers),
      dynamicQueryParams: Map.fromEntries(_params),
    );

    final api = ref.read(apiServiceProvider);
    final result = await api.executeCustomAPI("print('Hello from custom API');", testPreset);

    setState(() => _isTesting = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Test Result', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Raw Response:', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold)),
              Text(result.rawResponse, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(height: 16),
              const Text('Parsed Output:', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold)),
              Text('Stdout: ${result.stdout}', style: const TextStyle(color: AppTheme.successGreen, fontSize: 12)),
              Text('Stderr: ${result.stderr}', style: const TextStyle(color: AppTheme.errorRed, fontSize: 12)),
              Text('Time: ${result.executionTime}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Memory: ${result.memory}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: Form(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Basic Info'),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Platform Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _urlCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Endpoint URL'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppTheme.accentYellow),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                      Fluttertoast.showToast(msg: 'URL copied');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _method,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'HTTP Method'),
                items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _method = v!),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Authentication'),
              DropdownButtonFormField<String>(
                initialValue: _authType,
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _authType = v!),
              ),
              if (_authType != 'None') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authValueCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _authType == 'API-Key Header' ? 'Key:Value' : 'Value',
                    hintText: _authType == 'API-Key Header' ? 'X-API-Key: my_token_123' : 'my_token_123',
                    hintStyle: const TextStyle(color: Colors.white38),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _buildSectionTitle('Headers & Query Params'),
              _buildKeyValueEditor('Headers', _headers),
              const SizedBox(height: 12),
              _buildKeyValueEditor('Query Params', _params),

              const SizedBox(height: 24),
              _buildSectionTitle('Request Body Template'),
              const Text(
                'Use placeholders: {code}, {language}, {stdin}',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                maxLines: 5,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  hintText: '{"code": "{code}", "lang": "dart"}',
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Response Mapping (Dot Notation)'),
              const Text(
                'Map JSON paths to extract outputs (e.g., data.run.stdout)',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _buildPathField('Stdout Path', _stdoutPathCtrl),
              _buildPathField('Stderr Path', _stderrPathCtrl),
              _buildPathField('Error Path', _errPathCtrl),
              _buildPathField('Execution Time Path', _timePathCtrl),
              _buildPathField('Memory Path', _memPathCtrl),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.science),
                label: const Text('Test Connection'),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(color: AppTheme.accentYellow, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPathField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }

  Widget _buildKeyValueEditor(String title, List<MapEntry<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.accentYellow, size: 20),
              onPressed: () {
                setState(() {
                  items.add(const MapEntry('', ''));
                });
              },
            ),
          ],
        ),
        if (items.isEmpty)
          const Text('No items', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ...items.asMap().entries.map((e) {
          int idx = e.key;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: TextEditingController(text: items[idx].key),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(hintText: 'Key', isDense: true, contentPadding: EdgeInsets.all(8)),
                  onChanged: (v) => items[idx] = MapEntry(v, items[idx].value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: TextEditingController(text: items[idx].value),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(hintText: 'Value', isDense: true, contentPadding: EdgeInsets.all(8)),
                  onChanged: (v) => items[idx] = MapEntry(items[idx].key, v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: AppTheme.errorRed, size: 20),
                onPressed: () {
                  setState(() => items.removeAt(idx));
                },
              )
            ],
          );
        }),
      ],
    );
  }
}
