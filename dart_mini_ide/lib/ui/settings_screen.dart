import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme/app_theme.dart';
import '../providers/compiler_provider.dart';
import 'custom_compiler_screen.dart';

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
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          const Text(
            'Execution Engine',
            style: TextStyle(
              color: AppTheme.accentYellow,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use Default OneCompiler'),
            subtitle: const Text('Reliable, stable execution environment.'),
            value: compilerState.useDefaultOneCompiler,
            activeThumbColor: AppTheme.accentYellow,
            onChanged: (val) {
              ref.read(compilerProvider.notifier).toggleDefaultOneCompiler(val);
            },
          ),
          const Divider(color: Colors.white12),
          ListTile(
            title: const Text('Custom Compiler API System'),
            subtitle: const Text('Configure your own execution backends'),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            enabled: !compilerState.useDefaultOneCompiler,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomCompilerScreen()),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Presets Management',
            style: TextStyle(
              color: AppTheme.accentYellow,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.white70),
            title: const Text('Export Presets'),
            onTap: () {
                final json = ref.read(compilerProvider.notifier).exportPresetsJson();
                Clipboard.setData(ClipboardData(text: json));
                Fluttertoast.showToast(msg: "Presets JSON copied to clipboard");
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white70),
            title: const Text('Import Presets'),
            onTap: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data != null && data.text != null) {
                    ref.read(compilerProvider.notifier).importPresetsJson(data.text!);
                    Fluttertoast.showToast(msg: "Presets imported successfully");
                } else {
                    Fluttertoast.showToast(msg: "No text found in clipboard");
                }
            },
          ),
        ],
      ),
    );
  }
}
