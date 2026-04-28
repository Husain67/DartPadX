import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'providers/file_provider.dart';
import 'providers/compiler_provider.dart';
import 'providers/settings_provider.dart';
import 'ui/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  final fileBox = await Hive.openBox<CodeFile>('codeFilesBox');
  final compilerBox = await Hive.openBox<CompilerPreset>('compilerBox');
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        fileBoxProvider.overrideWithValue(fileBox),
        compilerBoxProvider.overrideWithValue(compilerBox),
        sharedPreferencesProvider.overrideWithValue(prefs),
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
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
