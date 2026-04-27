import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'preset_form.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Compiler Presets', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PresetForm(presetId: null)),
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: settingsState.presets.length,
        itemBuilder: (context, index) {
          final preset = settingsState.presets[index];
          final isActive = preset.id == settingsState.activePresetId;

          return Card(
            color: const Color(0xFF1a1a1a),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isActive ? const Color(0xFFFACC15) : const Color(0xFF333333),
                width: isActive ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(preset.endpointUrl.isEmpty ? 'No URL' : preset.endpointUrl, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () => ref.read(settingsProvider.notifier).duplicatePreset(preset.id),
                  ),
                  if (!preset.isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PresetForm(presetId: preset.id)),
                      ),
                    ),
                  if (!preset.isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset.id),
                    ),
                ],
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).setActivePreset(preset.id);
                Navigator.pop(context); // Go back after selecting
              },
            ),
          );
        },
      ),
    );
  }
}
