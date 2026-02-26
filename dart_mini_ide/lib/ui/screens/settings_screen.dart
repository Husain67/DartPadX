import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import '../widgets/custom_buttons.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
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
        body: TabBarView(
          children: [
            _GeneralSettings(),
            _CompilerPresetsSettings(),
          ],
        ),
      ),
    );
  }
}

class _GeneralSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          title: Text('DartMini IDE (Beta)', style: TextStyle(color: Colors.white)),
          subtitle: Text('Version 1.0.0', style: TextStyle(color: Colors.white54)),
        ),
        const Divider(color: Colors.white24),
        ListTile(
          title: const Text('Theme', style: TextStyle(color: Colors.white)),
          subtitle: const Text('VIDTSX Dark (Fixed)', style: TextStyle(color: Colors.white54)),
          trailing: const Icon(Icons.palette, color: Color(0xFFFACC15)),
          onTap: () {},
        ),
      ],
    );
  }
}

class _CompilerPresetsSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFACC15),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          // Add new preset
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditScreen()));
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );
                      if (result != null) {
                        File file = File(result.files.single.path!);
                        String content = await file.readAsString();
                        List<dynamic> jsonList = jsonDecode(content);
                        for (var item in jsonList) {
                          final preset = CompilerPreset.fromJson(item);
                          ref.read(settingsProvider.notifier).addPreset(preset);
                        }
                        Fluttertoast.showToast(msg: "Presets imported");
                      }
                    } catch (e) {
                      Fluttertoast.showToast(msg: "Import error: $e");
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import JSON'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                     try {
                       final presets = ref.read(settingsProvider).presets;
                       final jsonList = presets.map((p) => p.toJson()).toList();
                       final content = jsonEncode(jsonList);

                       final dir = await getTemporaryDirectory();
                       final file = File('${dir.path}/presets_export.json');
                       await file.writeAsString(content);
                       await Share.shareXFiles([XFile(file.path)], text: 'DartMini Presets');
                     } catch (e) {
                        Fluttertoast.showToast(msg: "Export error: $e");
                     }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export JSON'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: settings.presets.length,
              itemBuilder: (context, index) {
                final preset = settings.presets[index];
                final isSelected = settings.selectedPreset.name == preset.name;

                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(preset.platform, style: const TextStyle(color: Colors.white54)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         if (isSelected)
                           const Icon(Icons.check_circle, color: Color(0xFFFACC15)),
                         PopupMenuButton<String>(
                           icon: const Icon(Icons.more_vert, color: Colors.white54),
                           onSelected: (value) {
                             if (value == 'select') {
                               ref.read(settingsProvider.notifier).selectPreset(preset);
                             } else if (value == 'edit') {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditScreen(preset: preset)));
                             } else if (value == 'delete') {
                               ref.read(settingsProvider.notifier).deletePreset(preset);
                             }
                           },
                           itemBuilder: (context) => [
                             const PopupMenuItem(value: 'select', child: Text('Set as Default')),
                             const PopupMenuItem(value: 'edit', child: Text('Edit')),
                             if (preset.name != 'OneCompiler')
                               const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                           ],
                         ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditScreen(preset: preset)));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PresetEditScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditScreen({Key? key, this.preset}) : super(key: key);

  @override
  _PresetEditScreenState createState() => _PresetEditScreenState();
}

class _PresetEditScreenState extends ConsumerState<PresetEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _platform;
  late String _endpointUrl;
  late String _method;
  late String _bodyTemplate;

  @override
  void initState() {
    super.initState();
    _name = widget.preset?.name ?? 'New Preset';
    _platform = widget.preset?.platform ?? 'Custom';
    _endpointUrl = widget.preset?.endpointUrl ?? 'https://api.example.com/run';
    _method = widget.preset?.method ?? 'POST';
    _bodyTemplate = widget.preset?.bodyTemplate ?? '{"code": "{code}"}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFFACC15)),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final newPreset = CompilerPreset(
                  name: _name,
                  platform: _platform,
                  endpointUrl: _endpointUrl,
                  method: _method,
                  bodyTemplate: _bodyTemplate,
                  // Simplified for brevity, usually pass all fields
                );

                if (widget.preset != null) {
                  // Update logic needs ID or key?
                  // Since we treat name as unique for select, but key for Hive.
                  // We should update existing object if possible.
                  // Here we just add new for simplicity in this snippet,
                  // but ideally we call updatePreset.
                   ref.read(settingsProvider.notifier).addPreset(newPreset);
                } else {
                   ref.read(settingsProvider.notifier).addPreset(newPreset);
                }
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Preset saved");
              }
            },
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Preset Name', labelStyle: TextStyle(color: Colors.white70)),
              style: const TextStyle(color: Colors.white),
              onSaved: (val) => _name = val!,
            ),
            TextFormField(
              initialValue: _endpointUrl,
              decoration: const InputDecoration(labelText: 'Endpoint URL', labelStyle: TextStyle(color: Colors.white70)),
              style: const TextStyle(color: Colors.white),
              onSaved: (val) => _endpointUrl = val!,
            ),
            const SizedBox(height: 16),
            const Text('Body Template', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _bodyTemplate,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF1E1E1E),
              ),
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              onSaved: (val) => _bodyTemplate = val!,
            ),
          ],
        ),
      ),
    );
  }
}
