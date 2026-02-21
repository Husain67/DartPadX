import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_mini_ide/core/models/code_file.dart';
import 'package:dart_mini_ide/core/models/compiler_preset.dart';
import 'package:dart_mini_ide/features/home/screens/home_screen.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<CodeFile>('files');
  await Hive.openBox<CompilerPreset>('presets');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: DartMiniApp()));
}

class DartMiniApp extends StatelessWidget {
  const DartMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundStart,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.backgroundStart,
          onSurface: AppColors.textPrimary,
          background: AppColors.backgroundStart,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundStart,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
