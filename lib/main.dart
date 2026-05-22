import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'providers/app_state.dart';
import 'ui/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  final fileBox = await Hive.openBox<CodeFile>('code_files');
  final presetBox = await Hive.openBox<CompilerPreset>('compiler_presets');

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        fileBoxProvider.overrideWithValue(fileBox),
        presetBoxProvider.overrideWithValue(presetBox),
      ],
      child: const DartMiniIDE(),
    ),
  );
}

class DartMiniIDE extends StatelessWidget {
  const DartMiniIDE({Key? key}) : super(key: key);

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
