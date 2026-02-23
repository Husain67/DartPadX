import 'package:dart_mini_ide/core/constants.dart';
import 'package:dart_mini_ide/core/theme.dart';
import 'package:dart_mini_ide/models/code_file.dart';
import 'package:dart_mini_ide/models/compiler_preset.dart';
import 'package:dart_mini_ide/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<CodeFile>(AppConstants.boxFiles);
  await Hive.openBox<CompilerPreset>(AppConstants.boxPresets);
  await Hive.openBox(AppConstants.boxSettings);

  runApp(const ProviderScope(child: DartMiniApp()));
}

class DartMiniApp extends StatelessWidget {
  const DartMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
