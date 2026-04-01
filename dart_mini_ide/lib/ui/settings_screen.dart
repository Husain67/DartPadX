import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/settings_provider.dart';
import '../utils/colors.dart';
import 'compiler_presets_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Compiler Presets'),
          ListTile(
            title: const Text('Manage Presets'),
            subtitle: const Text('Add, Edit, and Select APIs'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CompilerPresetsScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Export Presets'),
            subtitle: const Text('Save your configured APIs to JSON'),
            trailing: const Icon(Icons.file_upload, color: Colors.grey),
            onTap: () {
              final jsonStr = ref.read(settingsProvider.notifier).exportPresets();
              Share.share(jsonStr, subject: 'DartMini IDE Compiler Presets');
            },
          ),
          ListTile(
            title: const Text('Import Presets'),
            subtitle: const Text('Load APIs from JSON string'),
            trailing: const Icon(Icons.file_download, color: Colors.grey),
            onTap: () => _showImportDialog(context, ref),
          ),
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('DartMini IDE'),
            subtitle: const Text('Version 1.0.0 (beta)\nFully mobile-first native experience.'),
            isThreeLine: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.backgroundStart,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.accentYellow,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        title: const Text('Import Presets'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Paste JSON here...',
            filled: true,
            fillColor: AppColors.editorBackground,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                ref.read(settingsProvider.notifier).importPresets(controller.text);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Presets imported successfully');
              } catch (e) {
                Fluttertoast.showToast(msg: 'Invalid JSON format');
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}