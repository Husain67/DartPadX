import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/compiler_preset.dart';
import '../theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/execution_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            indicatorColor: AppTheme.primaryAccent,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: Container(
          color: AppTheme.backgroundStart,
          child: TabBarView(
            children: [
              _buildGeneralTab(context),
              _buildPresetsTab(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTab(BuildContext context) {
    return const Center(
      child: Text('General Settings (Theme, Editor Config) coming soon.', style: TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildPresetsTab(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compiler APIs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('New', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryAccent),
                onPressed: () {
                  final newPreset = CompilerPreset(
                    id: const Uuid().v4(),
                    name: 'New Custom API',
                    url: 'https://api.example.com/execute',
                  );
                  notifier.addPreset(newPreset);
                  _openPresetEditor(context, ref, newPreset);
                },
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: settingsState.presets.length,
            itemBuilder: (context, index) {
              final preset = settingsState.presets[index];

              return Card(
                color: AppTheme.backgroundEnd,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Radio<String>(
                    // ignore: deprecated_member_use
                    value: preset.id,
                    // ignore: deprecated_member_use
                    groupValue: settingsState.activePresetId,
                    activeColor: AppTheme.primaryAccent,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) notifier.setActivePreset(val);
                    },
                  ),
                  title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _openPresetEditor(context, ref, preset),
                      ),
                      if (settingsState.presets.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => notifier.deletePreset(preset.id),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openPresetEditor(BuildContext context, WidgetRef ref, CompilerPreset preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;
  const PresetEditorScreen({super.key, required this.preset});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late CompilerPreset _currentPreset;
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _authCredsCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPreset = widget.preset.copyWith();
    _nameCtrl.text = _currentPreset.name;
    _urlCtrl.text = _currentPreset.url;
    _authCredsCtrl.text = _currentPreset.authCredentials;
    _bodyCtrl.text = _currentPreset.bodyTemplate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _authCredsCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    _currentPreset.name = _nameCtrl.text;
    _currentPreset.url = _urlCtrl.text;
    _currentPreset.authCredentials = _authCredsCtrl.text;
    _currentPreset.bodyTemplate = _bodyCtrl.text;

    ref.read(settingsProvider.notifier).updatePreset(_currentPreset);
    Navigator.pop(context);
  }

  Future<void> _testConnection() async {
    Fluttertoast.showToast(msg: "Testing connection...");

    // Create a temporary updated preset from current fields
    final testPreset = _currentPreset.copyWith(
      name: _nameCtrl.text,
      url: _urlCtrl.text,
      authCredentials: _authCredsCtrl.text,
      bodyTemplate: _bodyCtrl.text,
    );

    final result = await ExecutionService.execute(
      code: "void main() { print('Hello from custom API'); }",
      preset: testPreset,
      stdin: "",
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Result'),
        content: SingleChildScrollView(
          child: Text(const JsonEncoder.withIndent('  ').convert(result)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow, color: AppTheme.primaryAccent), onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: Container(
         color: AppTheme.backgroundStart,
         padding: const EdgeInsets.all(16),
         child: Form(
           child: ListView(
             children: [
               TextFormField(
                 controller: _nameCtrl,
                 decoration: const InputDecoration(labelText: 'Platform Name'),
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _urlCtrl,
                 decoration: const InputDecoration(labelText: 'Endpoint URL'),
                 maxLines: null,
               ),
               const SizedBox(height: 16),
               DropdownButtonFormField<String>(
                 // ignore: deprecated_member_use
                 value: _currentPreset.method,
                 decoration: const InputDecoration(labelText: 'HTTP Method'),
                 items: ['POST', 'GET', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                 onChanged: (val) {
                   if (val != null) setState(() => _currentPreset.method = val);
                 },
               ),
               const SizedBox(height: 16),
               DropdownButtonFormField<String>(
                 // ignore: deprecated_member_use
                 value: _currentPreset.authType,
                 decoration: const InputDecoration(labelText: 'Auth Type'),
                 items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                 onChanged: (val) {
                   if (val != null) setState(() => _currentPreset.authType = val);
                 },
               ),
               if (_currentPreset.authType != 'None') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _authCredsCtrl,
                    decoration: const InputDecoration(labelText: 'Auth Credentials / Token'),
                    obscureText: true,
                  ),
               ],
               const SizedBox(height: 24),
               const Text('Request Body (JSON Template)', style: TextStyle(fontWeight: FontWeight.bold)),
               const Text('Use {code}, {stdin}, {language}', style: TextStyle(color: Colors.grey, fontSize: 12)),
               const SizedBox(height: 8),
               TextFormField(
                 controller: _bodyCtrl,
                 decoration: const InputDecoration(
                   border: OutlineInputBorder(),
                   filled: true,
                   fillColor: AppTheme.backgroundEnd,
                 ),
                 maxLines: 8,
                 style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
               ),
               // Dynamic headers/params and response mapping editors could be added here
             ],
           ),
         ),
      ),
    );
  }
}
