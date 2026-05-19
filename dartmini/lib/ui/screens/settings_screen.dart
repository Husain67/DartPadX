import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_theme.dart';
import '../../providers/settings_provider.dart';
import '../../models/compiler_preset.dart';
import 'preset_editor_screen.dart';
import 'examples_gallery.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryYellow,
          labelColor: AppTheme.primaryYellow,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Compiler Presets'),
            Tab(text: 'Example Gallery'),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: TabBarView(
          controller: _tabController,
          children: [
            _CompilerPresetsTab(),
            const ExamplesGallery(),
          ],
        ),
      ),
    );
  }
}

class _CompilerPresetsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Use embedded key and endpoint'),
          activeTrackColor: AppTheme.primaryYellow.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.primaryYellow,
          value: settings.useDefaultOneCompiler,
          onChanged: (val) {
            ref.read(settingsProvider.notifier).toggleDefaultOneCompiler(val);
          },
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Custom Presets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.download, color: AppTheme.primaryYellow),
                  onPressed: () {
                    // Export all presets
                    final jsonList = settings.presets.map((p) => {
                      'id': p.id,
                      'name': p.name,
                      'endpointUrl': p.endpointUrl,
                      'httpMethod': p.httpMethod,
                      'authType': p.authType,
                      'authValue': p.authValue,
                      'headers': p.headers,
                      'queryParams': p.queryParams,
                      'bodyTemplate': p.bodyTemplate,
                      'stdoutPath': p.stdoutPath,
                      'stderrPath': p.stderrPath,
                      'errorPath': p.errorPath,
                      'executionTimePath': p.executionTimePath,
                      'memoryPath': p.memoryPath,
                    }).toList();
                    final jsonStr = jsonEncode(jsonList);
                    final bytes = utf8.encode(jsonStr);
                    final base64Str = base64.encode(bytes);
                    // ignore: deprecated_member_use
                    Share.share('DartMini Presets:\ndartmini://presets?data=$base64Str');
                  },
                  tooltip: 'Export Presets',
                ),
                IconButton(
                  icon: const Icon(Icons.upload, color: AppTheme.primaryYellow),
                  onPressed: () {
                     Fluttertoast.showToast(msg: "Import presets via deep-link coming soon!", backgroundColor: Colors.orange);
                  },
                  tooltip: 'Import Presets',
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primaryYellow),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PresetEditorScreen(
                          preset: CompilerPreset(name: 'New Preset', endpointUrl: ''),
                          isNew: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          ],
        ),
        if (!settings.useDefaultOneCompiler && settings.activePresetId == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Warning: Default disabled but no custom preset selected!',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        const SizedBox(height: 8),
        ...settings.presets.map((preset) {
          final isSelected = preset.id == settings.activePresetId && !settings.useDefaultOneCompiler;
          return Card(
            color: isSelected ? AppTheme.primaryYellow.withValues(alpha: 0.1) : AppTheme.backgroundGradientEnd,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isSelected ? AppTheme.primaryYellow : Colors.grey.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PresetEditorScreen(preset: preset),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                    onPressed: () {
                      final dup = preset.copyWith(name: '${preset.name} (Copy)');
                      ref.read(settingsProvider.notifier).addPreset(dup);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    onPressed: () {
                      ref.read(settingsProvider.notifier).deletePreset(preset.id);
                    },
                  ),
                ],
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).toggleDefaultOneCompiler(false);
                ref.read(settingsProvider.notifier).setActivePreset(preset.id);
              },
            ),
          );
        }),
      ],
    );
  }
}
