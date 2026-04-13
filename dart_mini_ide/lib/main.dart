import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'providers/file_provider.dart';
import 'providers/preset_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/main_editor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  final fileBox = await Hive.openBox<CodeFile>('codeFiles');
  final presetBox = await Hive.openBox<CompilerPreset>('compilerPresets');
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        fileBoxProvider.overrideWithValue(fileBox),
        presetBoxProvider.overrideWithValue(presetBox),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const DartMiniIDEApp(),
    ),
  );
}

class DartMiniIDEApp extends StatelessWidget {
  const DartMiniIDEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFFACC15),
        scaffoldBackgroundColor: const Color(0xFF050505),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainEditorScreen(),
    );
  }
}
