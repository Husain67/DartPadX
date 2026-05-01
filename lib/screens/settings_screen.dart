import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';
import '../providers/preset_provider.dart';
import '../screens/preset_editor_screen.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final presetsState = ref.watch(presetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white)),
            activeTrackColor: const Color(0xFFFACC15),
            activeThumbColor: Colors.black,
            value: settings.useDefaultOneCompiler,
            onChanged: (val) => ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(val),
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compiler Presets', style: TextStyle(color: Color(0xFFFACC15), fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PresetEditorScreen()),
                      );
                    },
                    tooltip: 'New Preset',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: () {
                      final json = ref.read(presetProvider.notifier).exportPresets();
                      Clipboard.setData(ClipboardData(text: json));
                      Fluttertoast.showToast(msg: "Exported to clipboard");
                    },
                    tooltip: 'Export',
                  ),
                  IconButton(
                    icon: const Icon(Icons.upload, color: Colors.white),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null && data.text != null) {
                        ref.read(presetProvider.notifier).importPresets(data.text!);
                        Fluttertoast.showToast(msg: "Imported from clipboard");
                      }
                    },
                    tooltip: 'Import',
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          ...presetsState.presets.map((preset) {
            final isActive = !settings.useDefaultOneCompiler && preset.id == presetsState.activePresetId;
            return Card(
              color: const Color(0xFF1a1a1a),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isActive ? const Color(0xFFFACC15) : Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(preset.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(preset.url, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  ref.read(settingsProvider.notifier).setUseDefaultOneCompiler(false);
                  ref.read(presetProvider.notifier).setActivePreset(preset.id);
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white54),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white54),
                      onPressed: () => ref.read(presetProvider.notifier).duplicatePreset(preset),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => ref.read(presetProvider.notifier).deletePreset(preset.id),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
