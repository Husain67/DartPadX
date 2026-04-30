import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import '../../providers/compiler_provider.dart';
import '../../theme/app_theme.dart';
import 'preset_editor.dart';

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
            indicatorColor: AppTheme.accentYellow,
            labelColor: AppTheme.accentYellow,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: Container(
          decoration: AppTheme.backgroundGradient,
          child: const TabBarView(
            children: [
              _GeneralSettingsTab(),
              _PresetsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneralSettingsTab extends ConsumerWidget {
  const _GeneralSettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Examples Gallery',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Hello World'),
          tileColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Not implemented in this basic version, would add file to provider
            Fluttertoast.showToast(msg: "Example loaded (mock)");
          },
        ),
        // Add more examples here
      ],
    );
  }
}

class _PresetsTab extends ConsumerWidget {
  const _PresetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Bypass custom presets entirely', style: TextStyle(color: Colors.grey)),
          value: compilerState.useDefaultOneCompiler,
          activeTrackColor: AppTheme.accentYellow,
          activeThumbColor: Colors.black,
          onChanged: (val) {
            ref.read(compilerProvider.notifier).toggleUseDefault(val);
          },
        ),
        const Divider(color: Colors.grey),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Add New', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentYellow),
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const PresetEditor()));
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, color: Colors.black),
                label: const Text('Export JSON', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.whiteCream),
                onPressed: () async {
                    final jsonList = compilerState.presets.map((p) => p.toJson()).toList();
                    final jsonString = jsonEncode(jsonList);
                    final dir = await getApplicationDocumentsDirectory();
                    final file = File('${dir.path}/presets.json');
                    await file.writeAsString(jsonString);
                    Share.shareXFiles([XFile(file.path)], text: 'My Compiler Presets');
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: compilerState.presets.length,
            itemBuilder: (context, index) {
              final preset = compilerState.presets[index];
              final isSelected = preset.id == compilerState.selectedPresetId && !compilerState.useDefaultOneCompiler;

              return Card(
                color: isSelected ? AppTheme.surfaceColor.withValues(alpha: 0.8) : AppTheme.surfaceColor,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: isSelected ? AppTheme.accentYellow : Colors.transparent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(preset.url, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => PresetEditor(preset: preset)));
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
                    ref.read(compilerProvider.notifier).setSelectedPreset(preset.id);
                    if (compilerState.useDefaultOneCompiler) {
                      ref.read(compilerProvider.notifier).toggleUseDefault(false);
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
