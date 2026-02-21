import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';
import 'package:dart_mini_ide/features/settings/providers/settings_provider.dart';
import 'package:dart_mini_ide/features/settings/widgets/preset_editor.dart';
import 'package:dart_mini_ide/features/settings/screens/examples_screen.dart';
import 'package:dart_mini_ide/core/models/compiler_preset.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    String getActivePresetName() {
      if (settingsState.activePresetId == null) return 'Using Default OneCompiler';
      try {
        final p = settingsState.presets.firstWhere((p) => p.id == settingsState.activePresetId);
        return 'Using Custom Preset: ${p.name}';
      } catch (_) {
        return 'Preset not found (Using Default)';
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Compiler Backend'),
            subtitle: Text(getActivePresetName()),
          ),
          RadioListTile<String?>(
            title: const Text('Default (OneCompiler)'),
            value: null,
            groupValue: settingsState.activePresetId,
            onChanged: (value) => notifier.setActivePreset(value),
            activeColor: AppColors.accent,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.library_books, color: AppColors.accent),
            title: const Text('Examples Gallery'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamplesScreen()));
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Custom Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.accent),
                  onPressed: () {
                    final newPreset = CompilerPreset(
                      id: const Uuid().v4(),
                      name: 'New Preset',
                      url: 'https://api.example.com/execute',
                      method: 'POST',
                      authType: 'None',
                      headers: {'Content-Type': 'application/json'},
                      queryParams: {},
                      requestBodyTemplate: '{\n  "code": "{code}",\n  "language": "{language}"\n}',
                      responseMapping: {'stdout': 'output', 'stderr': 'error'},
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: newPreset, isNew: true)));
                  },
                ),
              ],
            ),
          ),
          if (settingsState.presets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No custom presets added.', style: TextStyle(color: Colors.grey)),
            ),
          ...settingsState.presets.map((preset) {
            return ListTile(
              title: Text(preset.name),
              subtitle: Text(preset.url, maxLines: 1, overflow: TextOverflow.ellipsis),
              leading: Radio<String?>(
                value: preset.id,
                groupValue: settingsState.activePresetId,
                onChanged: (value) => notifier.setActivePreset(value),
                activeColor: AppColors.accent,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      notifier.deletePreset(preset.id);
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
