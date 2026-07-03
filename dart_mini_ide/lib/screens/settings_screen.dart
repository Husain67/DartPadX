import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dart_mini_ide/theme/app_theme.dart';
import 'package:dart_mini_ide/providers/settings_provider.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/screens/preset_editor_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compiler Settings'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Compiler Presets',
              style: TextStyle(color: AppTheme.primaryYellow, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...settings.presets.map((preset) => _PresetTile(preset: preset, isActive: preset.id == settings.activePresetId)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.toolbarButtonBg,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add New Preset'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: null)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetTile extends ConsumerWidget {
  final CompilerPreset preset;
  final bool isActive;

  const _PresetTile({required this.preset, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: isActive ? AppTheme.primaryYellow.withValues(alpha: 0.1) : AppTheme.backgroundStart,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isActive ? AppTheme.primaryYellow : Colors.grey[800]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(preset.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(preset.endpoint, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                onPressed: () => ref.read(settingsProvider.notifier).setActivePreset(preset.id),
                tooltip: 'Set as Active',
              )
            else
              const Icon(Icons.check_circle, color: AppTheme.primaryYellow),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)),
                );
              },
            ),
            if (preset.name != 'OneCompiler') // Prevent deleting the default
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => ref.read(settingsProvider.notifier).deletePreset(preset.id),
              ),
          ],
        ),
      ),
    );
  }
}
