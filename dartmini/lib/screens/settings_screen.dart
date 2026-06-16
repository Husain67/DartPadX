import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/compiler_provider.dart';
import 'preset_editor_screen.dart';
import '../models/compiler_preset.dart';

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
        backgroundColor: const Color(0xFF050505),
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
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
        body: const TabBarView(
          children: [
            _GeneralTab(),
            _PresetsTab(),
          ],
        ),
      ),
    );
  }
}

class _GeneralTab extends ConsumerWidget {
  const _GeneralTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Turn off to use selected custom preset', style: TextStyle(color: Colors.white54)),
          value: state.useDefaultOneCompiler,
          // ignore: deprecated_member_use
          activeColor: const Color(0xFFFACC15),
          onChanged: (val) => ref.read(compilerProvider.notifier).setUseDefaultOneCompiler(val),
        ),
      ],
    );
  }
}

class _PresetsTab extends ConsumerWidget {
  const _PresetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: state.presets.length,
            itemBuilder: (context, index) {
              final preset = state.presets[index];
              final isSelected = preset.id == state.activePresetId && !state.useDefaultOneCompiler;
              return ListTile(
                title: Text(preset.name, style: TextStyle(color: isSelected ? const Color(0xFFFACC15) : Colors.white)),
                subtitle: Text(preset.endpointUrl, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) const Icon(Icons.check, color: Color(0xFFFACC15)),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white54),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white54),
                      onPressed: () {
                        final copy = preset.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString(), name: '${preset.name} (Copy)');
                        ref.read(compilerProvider.notifier).addOrUpdatePreset(copy);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => ref.read(compilerProvider.notifier).deletePreset(preset.id),
                    ),
                  ],
                ),
                onTap: () {
                  ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                  if (state.useDefaultOneCompiler) {
                    ref.read(compilerProvider.notifier).setUseDefaultOneCompiler(false);
                  }
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
            },
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Add New Preset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }
}
