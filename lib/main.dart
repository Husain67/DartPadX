import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/models/dart_file.dart';
import 'src/models/compiler_preset.dart';
import 'src/ui/theme/app_theme.dart';
import 'src/ui/screens/main_screen.dart';

// Provide SharedPreferences synchronously
late SharedPreferences sharedPreferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DartFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<DartFile>('files');
  await Hive.openBox<CompilerPreset>('presets');

  sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    const ProviderScope(
      child: DartMiniApp(),
    ),
  );
}

class DartMiniApp extends StatelessWidget {
  const DartMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
