import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'utils/colors.dart';
import 'utils/constants.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<CodeFile>(AppConstants.fileBoxName);
  await Hive.openBox<CompilerPreset>(AppConstants.presetBoxName);
  await Hive.openBox(AppConstants.settingsBoxName);

  // SharedPreferences can be initialized here if needed for backward compatibility
  // await SharedPreferences.getInstance();

  runApp(const ProviderScope(child: DartMiniIDEApp()));
}

class DartMiniIDEApp extends StatelessWidget {
  const DartMiniIDEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppColors.darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}