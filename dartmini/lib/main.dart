import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_highlight/themes/darcula.dart';

import 'theme.dart';
import 'models/dart_file.dart';
import 'models/compiler_preset.dart';
import 'providers/file_notifier.dart';
import 'providers/compiler_notifier.dart';
import 'ui/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Initialize Hive and SharedPreferences
  await Hive.initFlutter();
  Hive.registerAdapter(DartFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  final fileBox = await Hive.openBox<DartFile>('files');
  final compilerBox = await Hive.openBox<CompilerPreset>('compilers');
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        fileBoxProvider.overrideWithValue(fileBox),
        compilerBoxProvider.overrideWithValue(compilerBox),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const DartMiniApp(),
    ),
  );
}

class DartMiniApp extends StatelessWidget {
  const DartMiniApp({Key? key}) : super(key: key);

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
