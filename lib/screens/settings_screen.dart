import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/compiler_provider.dart';
import 'preset_editor_sheet.dart';

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPresetEditor([preset]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PresetEditorSheet(preset: preset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundStart,
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryYellow,
          labelColor: AppTheme.primaryYellow,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'General'),
            Tab(text: 'Compiler Presets'),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildGeneralTab(),
            _buildPresetsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('General Settings Placeholder', style: TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildPresetsTab() {
    final compilerState = ref.watch(compilerProvider);
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler'),
          subtitle: const Text('Recommended for stable execution'),
          value: compilerState.useDefaultOneCompiler,
          // ignore: deprecated_member_use
          activeColor: AppTheme.primaryYellow,
          onChanged: (val) {
            ref.read(compilerProvider.notifier).toggleUseDefault(val);
          },
        ),
        const Divider(color: Colors.white24),
        if (!compilerState.useDefaultOneCompiler)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => _showPresetEditor(),
              style: AppTheme.toolbarButtonStyle,
              icon: Icon(Icons.add),
              label: Text('Add New Preset'),
            ),
          ),
        Expanded(
          child: compilerState.useDefaultOneCompiler
              ? Center(child: Text('Custom presets are disabled.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: compilerState.presets.length,
                  itemBuilder: (context, index) {
                    final preset = compilerState.presets[index];
                    final isActive = preset.id == compilerState.activePresetId;
                    return ListTile(
                      title: Text(preset.name, style: TextStyle(color: isActive ? AppTheme.primaryYellow : Colors.white)),
                      subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white54)),
                      trailing: isActive ? Icon(Icons.check_circle, color: AppTheme.primaryYellow) : null,
                      onTap: () {
                        ref.read(compilerProvider.notifier).setActivePreset(preset.id);
                      },
                      onLongPress: () {
                         _showPresetEditor(preset);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
