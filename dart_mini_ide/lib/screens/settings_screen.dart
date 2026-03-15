import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import '../models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFACC15),
            labelColor: Color(0xFFFACC15),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF050505), Color(0xFF1A1A1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: TabBarView(
            children: [
              const GeneralSettingsTab(),
              const CompilerPresetsTab(), // Made this const and updated child class
            ],
          ),
        ),
      ),
    );
  }
}

class GeneralSettingsTab extends StatelessWidget {
  const GeneralSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('App Info', style: TextStyle(color: Color(0xFFFACC15), fontSize: 18, fontWeight: FontWeight.bold)),
        ListTile(
          title: Text('Version', style: TextStyle(color: Colors.white)),
          subtitle: Text('1.0.0+1 (beta)', style: TextStyle(color: Colors.white54)),
        ),
        ListTile(
          title: Text('Developer', style: TextStyle(color: Colors.white)),
          subtitle: Text('DartMini IDE', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}

class CompilerPresetsTab extends ConsumerStatefulWidget {
  const CompilerPresetsTab({super.key}); // Added const constructor and key

  @override
  ConsumerState<CompilerPresetsTab> createState() => _CompilerPresetsTabState();
}

class _CompilerPresetsTabState extends ConsumerState<CompilerPresetsTab> {
  void _editPreset(CompilerPreset preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPresetScreen(preset: preset),
      ),
    );
  }

  void _addPreset() {
    final uuid = const Uuid().v4();
    final newPreset = CompilerPreset(
      id: uuid,
      platformName: 'New Platform',
      endpointUrl: '',
      httpMethod: 'POST',
      authType: 'None',
      headers: {},
      queryParams: {},
      requestBodyTemplate: '{}',
      stdoutPath: '',
      stderrPath: '',
      errorPath: '',
      executionTimePath: '',
      memoryPath: '',
    );
    ref.read(compilerPresetsProvider.notifier).addPreset(newPreset);
    _editPreset(newPreset);
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(compilerPresetsProvider);
    final activeId = ref.watch(activeCompilerPresetIdProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compiler APIs', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _addPreset,
                icon: const Icon(Icons.add, color: Colors.black, size: 16),
                label: const Text('Add New', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isActive = preset.id == activeId;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? const Color(0xFFFACC15) : Colors.white12),
                ),
                child: ListTile(
                  title: Text(
                    preset.platformName,
                    style: TextStyle(
                      color: isActive ? const Color(0xFFFACC15) : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isActive)
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white54),
                          onPressed: () => ref.read(activeCompilerPresetIdProvider.notifier).setActive(preset.id),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _editPreset(preset),
                      ),
                      if (presets.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => ref.read(compilerPresetsProvider.notifier).deletePreset(preset.id),
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
}

class EditPresetScreen extends ConsumerStatefulWidget {
  final CompilerPreset preset;

  const EditPresetScreen({super.key, required this.preset});

  @override
  ConsumerState<EditPresetScreen> createState() => _EditPresetScreenState();
}

class _EditPresetScreenState extends ConsumerState<EditPresetScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController urlCtrl;
  late TextEditingController bodyCtrl;
  late TextEditingController stdoutCtrl;
  late TextEditingController stderrCtrl;
  late String method;
  late String auth;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.preset.platformName);
    urlCtrl = TextEditingController(text: widget.preset.endpointUrl);
    bodyCtrl = TextEditingController(text: widget.preset.requestBodyTemplate);
    stdoutCtrl = TextEditingController(text: widget.preset.stdoutPath);
    stderrCtrl = TextEditingController(text: widget.preset.stderrPath);
    method = widget.preset.httpMethod;
    auth = widget.preset.authType;
  }

  void _save() {
    final updated = widget.preset.copyWith(
      platformName: nameCtrl.text,
      endpointUrl: urlCtrl.text,
      requestBodyTemplate: bodyCtrl.text,
      stdoutPath: stdoutCtrl.text,
      stderrPath: stderrCtrl.text,
      httpMethod: method,
      authType: auth,
    );
    ref.read(compilerPresetsProvider.notifier).updatePreset(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Preset', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildField('Platform Name', nameCtrl),
          _buildField('Endpoint URL', urlCtrl, maxLines: 2),

          const SizedBox(height: 16),
          const Text('HTTP Method', style: TextStyle(color: Colors.white70)),
          DropdownButton<String>(
            value: method,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'GET', child: Text('GET')),
              DropdownMenuItem(value: 'POST', child: Text('POST')),
              DropdownMenuItem(value: 'PUT', child: Text('PUT')),
            ],
            onChanged: (v) => setState(() => method = v!),
          ),

          const SizedBox(height: 16),
          _buildField('Request Body Template (JSON)', bodyCtrl, maxLines: 6),
          const Text('Use {code} and {stdin} placeholders', style: TextStyle(color: Colors.white54, fontSize: 12)),

          const SizedBox(height: 16),
          const Text('Response Mapping (Dot Notation)', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
          _buildField('Stdout Path', stdoutCtrl),
          _buildField('Stderr Path', stderrCtrl),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}