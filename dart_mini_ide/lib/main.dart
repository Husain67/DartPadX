import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  // Open Boxes
  await Hive.openBox<CodeFile>('code_files');
  await Hive.openBox<CompilerPreset>('compiler_presets');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: DartMiniIdeApp()));
}

class DartMiniIdeApp extends StatelessWidget {
  const DartMiniIdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
