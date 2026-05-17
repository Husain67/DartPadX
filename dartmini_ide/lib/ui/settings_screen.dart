import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import '../providers/compiler_preset_provider.dart';
import '../models/compiler_preset.dart';
import 'preset_editor.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';


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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFACC15),
          labelColor: const Color(0xFFFACC15),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Compiler Presets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(),
          _buildPresetsTab(),
        ],
      ),
    );
  }


  Future<void> _exportPresets() async {
    final presets = ref.read(compilerPresetProvider);
    final list = presets.map((p) => {
      'name': p.name, 'endpointUrl': p.endpointUrl, 'httpMethod': p.httpMethod,
      'authType': p.authType, 'authValue': p.authValue, 'authKey': p.authKey,
      'headers': p.headers, 'queryParams': p.queryParams, 'requestBodyTemplate': p.requestBodyTemplate,
      'stdoutPath': p.stdoutPath, 'stderrPath': p.stderrPath, 'errorPath': p.errorPath,
      'executionTimePath': p.executionTimePath, 'memoryPath': p.memoryPath,
    }).toList();

    final jsonStr = jsonEncode(list);
    Clipboard.setData(ClipboardData(text: jsonStr));
    Fluttertoast.showToast(msg: "Exported to clipboard as JSON");
  }

  Future<void> _importPresets() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      try {
        final List<dynamic> list = jsonDecode(data.text!);
        for (var item in list) {
          final map = item as Map<String, dynamic>;
          final p = CompilerPreset(
            name: map['name'] ?? 'Imported Preset',
            endpointUrl: map['endpointUrl'] ?? '',
            httpMethod: map['httpMethod'] ?? 'POST',
            authType: map['authType'] ?? 'None',
            authValue: map['authValue'] ?? '',
            authKey: map['authKey'] ?? '',
            headers: Map<String, String>.from(map['headers'] ?? {}),
            queryParams: Map<String, String>.from(map['queryParams'] ?? {}),
            requestBodyTemplate: map['requestBodyTemplate'] ?? '',
            stdoutPath: map['stdoutPath'] ?? '',
            stderrPath: map['stderrPath'] ?? '',
            errorPath: map['errorPath'] ?? '',
            executionTimePath: map['executionTimePath'] ?? '',
            memoryPath: map['memoryPath'] ?? '',
          );
          ref.read(compilerPresetProvider.notifier).addPreset(p);
        }
        Fluttertoast.showToast(msg: "Imported successfully");
      } catch (e) {
        Fluttertoast.showToast(msg: "Invalid JSON format");
      }
    }
  }

  Widget _buildGeneralTab() {
    final settings = ref.watch(settingsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Disables custom compiler presets globally', style: TextStyle(color: Colors.white54)),
          activeTrackColor: const Color(0xFFFACC15),
          value: settings.useDefaultOneCompiler,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(val);
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
          onPressed: _exportPresets,
          child: const Text('Export All Presets to Clipboard', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E)),
          onPressed: _importPresets,
          child: const Text('Import Presets from Clipboard JSON', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildPresetsTab() {
    final presets = ref.watch(compilerPresetProvider);
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isActive = !settings.useDefaultOneCompiler && settings.activePresetId == preset.id;

              return ListTile(
                title: Text(preset.name, style: TextStyle(color: isActive ? const Color(0xFFFACC15) : Colors.white)),
                subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive) const Icon(Icons.check_circle, color: Color(0xFFFACC15), size: 20),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white54),
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditor(preset: preset)));
                      },
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
                  ref.read(settingsProvider.notifier).setActivePresetId(preset.id);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E1E),
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () {
               final newPreset = CompilerPreset(name: 'New Custom Preset', endpointUrl: '');
               ref.read(compilerPresetProvider.notifier).addPreset(newPreset);
               Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditor(preset: newPreset)));
            },
            child: const Text('Add Custom Preset', style: TextStyle(color: Colors.white)),
          ),
        )
      ],
    );
  }
}
