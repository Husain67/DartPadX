import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/compiler_provider.dart';
import 'compiler_presets_screen.dart';
import 'examples_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compilerState = ref.watch(compilerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Compiler Settings'),
          ListTile(
            leading: const Icon(Icons.api_outlined, color: AppTheme.primaryAccent),
            title: const Text('Compiler API Presets'),
            subtitle: Text('Active: ${compilerState.activePreset.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompilerPresetsScreen()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('Learning'),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline, color: AppTheme.primaryAccent),
            title: const Text('Examples Gallery'),
            subtitle: const Text('Pre-loaded Dart examples to try'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExamplesScreen()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppTheme.primaryAccent),
            title: const Text('DartMini IDE'),
            subtitle: const Text('Version 0.1.0-beta\nA complete mobile-first Dart execution environment.'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
