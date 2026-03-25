import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/compiler_presets_provider.dart';
import '../providers/file_provider.dart';
import '../models/code_file.dart';
import '../models/compiler_preset.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'compiler_preset_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Container(
        decoration: AppTheme.mainBackgroundDecoration,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildExamplesSection(context, ref),
            const SizedBox(height: 24),
            _buildCompilerSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context, WidgetRef ref) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Examples Gallery',
              style: TextStyle(
                color: AppTheme.accentYellow,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...AppConstants.examples.map((ex) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(ex['title']!),
                  trailing: const Icon(Icons.download, color: AppTheme.accentYellow),
                  onTap: () {
                    final newId = DateTime.now().millisecondsSinceEpoch.toString();
                    ref.read(fileProvider.notifier).openFile(CodeFile(
                          id: newId,
                          name: '\${ex['title']!.replaceAll(' ', '_').toLowerCase()}.dart',
                          content: ex['code']!,
                        ));
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Example loaded');
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCompilerSection(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerPresetsProvider);

    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Compiler API Settings',
                  style: TextStyle(
                    color: AppTheme.accentYellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: state.useDefault,
                  onChanged: (val) {
                    ref.read(compilerPresetsProvider.notifier).toggleUseDefault(val);
                  },
                  activeColor: AppTheme.accentYellow,
                ),
              ],
            ),
            Text(
              state.useDefault
                  ? 'Using built-in OneCompiler fallback.'
                  : 'Using custom preset.',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            if (!state.useDefault) ...[
              const Text('Select Preset:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: state.selectedPresetId,
                items: state.presets.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(compilerPresetsProvider.notifier).selectPreset(val);
                  }
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompilerPresetEditor(
                          preset: CompilerPreset(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: 'New Custom Preset',
                            url: 'https://',
                          ),
                          isNew: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New'),
                ),
                if (!state.useDefault && state.activePreset != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompilerPresetEditor(
                            preset: state.activePreset!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final jsonStr = ref.read(compilerPresetsProvider.notifier).exportPresetsJson();
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    Fluttertoast.showToast(msg: 'Presets exported to clipboard');
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Export JSON'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      try {
                        ref.read(compilerPresetsProvider.notifier).importPresetsJson(data!.text!);
                        Fluttertoast.showToast(msg: 'Presets imported successfully');
                      } catch (e) {
                        Fluttertoast.showToast(msg: 'Invalid JSON format');
                      }
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Import JSON'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
