import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'src/ui/theme/theme_constants.dart';
import 'src/features/editor/editor_screen.dart';
import 'src/models/code_file.dart';
import 'src/models/compiler_preset.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  if (!kIsWeb) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      Hive.init(dir.path);
    } catch (_) {
      await Hive.initFlutter();
    }
  } else {
    await Hive.initFlutter();
  }

  // Register Adapters
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  // Open Boxes
  await Hive.openBox<CodeFile>('code_files');
  await Hive.openBox<CompilerPreset>('compiler_presets');
  await Hive.openBox<String>('settings'); // Store simpler settings here

  runApp(const ProviderScope(child: DartMiniIDEApp()));
}

// Fallback constant for web
const bool kIsWeb = identical(0, 0.0);

class DartMiniIDEApp extends StatelessWidget {
  const DartMiniIDEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeConstants.darkTheme,
      home: const EditorScreen(),
    );
  }
}
